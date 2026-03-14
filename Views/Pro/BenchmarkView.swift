import SwiftUI

// MARK: - Feature 3: Benchmark View
struct BenchmarkView: View {
    @StateObject private var bench = BenchmarkService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("CPU & RAM Benchmark").font(.title2.bold())

                // Warning
                Label("This will use 100% CPU for ~15 seconds", systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundColor(.secondary)

                if bench.isRunning {
                    VStack(spacing: 10) {
                        ProgressView(value: bench.progress)
                            .progressViewStyle(.linear).tint(.accentColor)
                        Text(progressLabel(bench.progress)).font(.caption).foregroundColor(.secondary)
                    }
                } else {
                    Button("Run Benchmark") { Task { await bench.runBenchmark() } }
                        .buttonStyle(.borderedProminent)
                }

                if let r = bench.result {
                    HStack(spacing: 20) {
                        ScoreCard(label: "CPU Score", score: r.cpuScore,
                                  rating: r.cpuRating, percentile: r.cpuPercentile)
                        ScoreCard(label: "RAM Score", score: r.ramScore,
                                  rating: r.ramRating, percentile: r.ramPercentile)
                    }
                    Text(String(format: "Completed in %.1fs", r.durationSeconds))
                        .font(.caption).foregroundColor(.secondary)
                }

                // History
                let history = BenchmarkHistory.load()
                if !history.isEmpty {
                    Divider()
                    Text("History").font(.headline)
                    ForEach(history.suffix(5).reversed(), id: \.timestamp) { h in
                        HStack {
                            Text(h.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text("CPU \(h.cpuScore) · RAM \(h.ramScore)")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private func progressLabel(_ p: Double) -> String {
        p < 0.33 ? "Running CPU integer test…"
        : p < 0.66 ? "Running CPU floating-point test…"
        : "Running RAM test…"
    }
}

struct ScoreCard: View {
    var label: String; var score: Int; var rating: String; var percentile: Int
    var ratingColor: Color { score > 700 ? .green : score > 550 ? .blue : score > 400 ? .orange : .red }
    var body: some View {
        VStack(spacing: 6) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Text("\(score)").font(.system(size: 44, weight: .bold, design: .rounded))
            Text(rating).font(.caption.bold()).foregroundColor(ratingColor)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(ratingColor.opacity(0.15)).cornerRadius(6)
            Text("Faster than \(percentile)% of Macs").font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(14)
        .background(Color(NSColor.controlBackgroundColor)).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
    }
}
