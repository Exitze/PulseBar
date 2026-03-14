import SwiftUI
import Charts
import UniformTypeIdentifiers

struct ThermalHistoryCard: View {
    let history: [ThermalHistoryData]
    @State private var showExpanded = false

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundStyle(Color.accentBlue)
                        .font(.system(size: 14))
                    Text("Thermal History")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        showExpanded = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Mini chart (last 40 points)
                let recent = Array(history.suffix(40))
                if recent.isEmpty {
                    Text("Collecting data…")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                        .frame(height: 60, alignment: .center)
                        .frame(maxWidth: .infinity)
                } else {
                    Chart {
                        ForEach(recent.indices, id: \.self) { i in
                            LineMark(x: .value("t", i), y: .value("CPU°C", recent[i].cpuTemp))
                                .foregroundStyle(Color.accentRed)
                            LineMark(x: .value("t", i), y: .value("Load%", recent[i].cpuLoad))
                                .foregroundStyle(Color.accentBlue)
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 56)
                }

                // Legend
                HStack(spacing: 12) {
                    LegendDot(color: .accentRed,  label: "CPU Temp")
                    LegendDot(color: .accentBlue, label: "CPU Load")
                }
            }
        }
        .sheet(isPresented: $showExpanded) {
            ThermalHistoryExpanded(history: history)
        }
    }
}

struct LegendDot: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.system(size: 10)).foregroundStyle(Color.secondary)
        }
    }
}

// MARK: - Expanded full-screen chart
struct ThermalHistoryExpanded: View {
    let history: [ThermalHistoryData]
    @Environment(\.dismiss) var dismiss
    @State private var exportTrigger = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Thermal History (24h)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button("Export CSV") { exportTrigger = true }
                    .font(.system(size: 12))
                    .foregroundStyle(Color.accentBlue)
                    .buttonStyle(.plain)
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.secondary)
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.cardBg)

            Rectangle().fill(Color.cardBorder).frame(height:1)

            // Full chart
            if history.isEmpty {
                Spacer()
                Text("No data yet. Data accumulates over time.")
                    .foregroundStyle(Color.secondary)
                Spacer()
            } else {
                Chart {
                    ForEach(history.indices, id: \.self) { i in
                        LineMark(x: .value("Time", history[i].timestamp),
                                 y: .value("CPU Temp", history[i].cpuTemp))
                            .foregroundStyle(by: .value("Metric", "CPU Temp"))
                        LineMark(x: .value("Time", history[i].timestamp),
                                 y: .value("GPU Temp", history[i].gpuTemp))
                            .foregroundStyle(by: .value("Metric", "GPU Temp"))
                        LineMark(x: .value("Time", history[i].timestamp),
                                 y: .value("CPU Load", history[i].cpuLoad))
                            .foregroundStyle(by: .value("Metric", "CPU Load %"))
                    }
                }
                .chartForegroundStyleScale([
                    "CPU Temp":  Color.accentRed,
                    "GPU Temp":  Color.accentYellow,
                    "CPU Load %": Color.accentBlue
                ])
                .padding(20)
            }
        }
        .background(Color.appBg)
        .frame(minWidth: 600, minHeight: 400)
        .fileExporter(
            isPresented: $exportTrigger,
            document: ThermalCSVDocument(history: history),
            contentType: .commaSeparatedText,
            defaultFilename: "PulseBar_Thermal_\(formattedDate())"
        ) { _ in }
    }

    private func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HH-mm"
        return f.string(from: Date())
    }
}

// MARK: - CSV export document
struct ThermalCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    let history: [ThermalHistoryData]

    init(history: [ThermalHistoryData]) { self.history = history }
    init(configuration: ReadConfiguration) throws { history = [] }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        var csv = "Timestamp,CPU Temp (°C),GPU Temp (°C),CPU Load (%)\n"
        let f = ISO8601DateFormatter()
        for entry in history {
            csv += "\(f.string(from: entry.timestamp)),\(entry.cpuTemp),\(entry.gpuTemp),\(entry.cpuLoad)\n"
        }
        return FileWrapper(regularFileWithContents: Data(csv.utf8))
    }
}
