import SwiftUI
import Charts

// MARK: - Feature 4: 30-Day History View
struct HistoryView: View {
    @StateObject private var store = HistoryStore.shared
    @State private var range = 7

    private var filtered: [DailySummary] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -range, to: Date())!
        return store.summaries.filter { $0.date >= cutoff }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Performance History").font(.title2.bold())

                Picker("Range", selection: $range) {
                    Text("7 Days").tag(7)
                    Text("14 Days").tag(14)
                    Text("30 Days").tag(30)
                }.pickerStyle(.segmented)

                if filtered.isEmpty {
                    Text("No history yet. Data is recorded automatically every hour.")
                        .foregroundColor(.secondary).font(.callout)
                } else {
                    HistoryChart(data: filtered, valueKey: \.avgCPUTemp, maxKey: \.maxCPUTemp,
                                 title: "CPU Temperature (°C)", color: .orange)
                    HistoryChart(data: filtered, valueKey: \.avgRAMUsed, maxKey: nil,
                                 title: "RAM Usage (GB)", color: .purple)
                    HistoryChart(data: filtered, valueKey: \.avgCPULoad, maxKey: \.maxCPULoad,
                                 title: "CPU Load (%)", color: .blue)

                    // Insights
                    Divider()
                    Text("Insights").font(.headline)
                    if let hottest = filtered.max(by: { $0.avgCPUTemp < $1.avgCPUTemp }) {
                        InsightRow(icon: "thermometer", text: "Hottest day: \(hottest.date.formatted(date: .abbreviated, time: .omitted)) (avg \(Int(hottest.avgCPUTemp))°C)")
                    }
                    if let heaviest = filtered.max(by: { $0.avgCPULoad < $1.avgCPULoad }) {
                        InsightRow(icon: "cpu", text: "Highest load: \(heaviest.date.formatted(date: .abbreviated, time: .omitted)) (avg \(Int(heaviest.avgCPULoad))%)")
                    }
                }
            }
            .padding(20)
        }
    }
}

struct HistoryChart: View {
    var data:     [DailySummary]
    var valueKey: KeyPath<DailySummary, Double>
    var maxKey:   KeyPath<DailySummary, Double>?
    var title:    String
    var color:    Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundColor(.secondary)
            Chart {
                ForEach(data, id: \.date) { s in
                    LineMark(x: .value("Date", s.date), y: .value("v", s[keyPath: valueKey]))
                        .foregroundStyle(color.gradient).interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Date", s.date), y: .value("v", s[keyPath: valueKey]))
                        .foregroundStyle(color.opacity(0.1).gradient)
                    if let mk = maxKey {
                        RuleMark(y: .value("Max", s[keyPath: mk])).foregroundStyle(color.opacity(0.3))
                    }
                }
            }
            .chartXAxis { AxisMarks(values: .stride(by: .day, count: max(1, data.count / 4))) { v in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 8))
            }}
            .frame(height: 100)
        }
        .padding(12).background(Color(NSColor.controlBackgroundColor)).cornerRadius(10)
    }
}

struct InsightRow: View {
    var icon: String; var text: String
    var body: some View {
        Label(text, systemImage: icon).font(.callout).foregroundColor(.primary)
    }
}
