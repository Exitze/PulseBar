import Foundation
import Combine

// MARK: - Feature 1: AI Analysis Service
struct HistorySnapshot {
    var avgCPUTemp:    Double
    var peakCPUTemp:   Double
    var avgCPULoad:    Double
    var peakCPULoad:   Double
    var avgRAM:        Double
    var topProcess:    String
    var topProcessCPU: Double
    var anomalies:     [String]
}

class AIAnalysisService: ObservableObject {
    static let shared = AIAnalysisService()
    @Published var currentInsight: String = ""
    @Published var isAnalyzing:    Bool   = false

    private let apiURL = "https://api.anthropic.com/v1/messages"
    private init() {}

    func analyze(metrics: HistorySnapshot) async {
        guard !isAnalyzing else { return }
        guard let apiKey = KeychainHelper.get("anthropic_api_key"), !apiKey.isEmpty else {
            await MainActor.run { currentInsight = "Add API key in Pro › AI Settings" }
            return
        }
        await MainActor.run { isAnalyzing = true }

        let body: [String: Any] = [
            "model":      "claude-sonnet-4-20250514",
            "max_tokens": 200,
            "messages":   [["role": "user", "content": buildPrompt(metrics: metrics)]]
        ]
        var req = URLRequest(url: URL(string: apiURL)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey,     forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = (json["content"] as? [[String: Any]])?.first,
               let text    = content["text"] as? String {
                await MainActor.run { self.currentInsight = text; self.isAnalyzing = false }
            } else {
                await MainActor.run { self.currentInsight = "Could not parse response"; self.isAnalyzing = false }
            }
        } catch {
            await MainActor.run { self.currentInsight = "Analysis unavailable"; self.isAnalyzing = false }
        }
    }

    private func buildPrompt(metrics: HistorySnapshot) -> String {
        """
        You are a Mac performance analyst. Analyze these last 10 minutes of data \
        and give ONE short insight (max 2 sentences). Be specific about processes \
        if relevant. Be direct, no fluff.

        CPU temp: avg \(Int(metrics.avgCPUTemp))°C, peak \(Int(metrics.peakCPUTemp))°C
        CPU load: avg \(Int(metrics.avgCPULoad))%, peak \(Int(metrics.peakCPULoad))%
        RAM: \(String(format:"%.1f", metrics.avgRAM)) GB avg
        Top process: \(metrics.topProcess) using \(Int(metrics.topProcessCPU))% CPU
        Anomalies detected: \(metrics.anomalies.isEmpty ? "none" : metrics.anomalies.joined(separator: ", "))
        """
    }
}
