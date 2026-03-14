import WidgetKit
import SwiftUI

// MARK: - Shared data via App Group
// App Group ID: group.com.danyaczhan.pulsebar

struct WidgetMetrics: Codable {
    var cpuTemp:         Double = 0
    var cpuUsage:        Double = 0
    var ramUsedGB:       Double = 0
    var ramTotalGB:      Double = 16
    var batteryLevel:    Int    = 0
    var batteryCharging: Bool   = false
    var networkUp:       String = "0 KB/s"
    var pingMs:          Double = 0
    var updatedAt:       Date   = Date()
}

// MARK: - Timeline Provider
struct PulseBarProvider: TimelineProvider {
    func placeholder(in context: Context) -> PulseBarEntry {
        PulseBarEntry(date: Date(), metrics: WidgetMetrics())
    }
    func getSnapshot(in context: Context, completion: @escaping (PulseBarEntry) -> Void) {
        completion(PulseBarEntry(date: Date(), metrics: loadMetrics()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PulseBarEntry>) -> Void) {
        let entry = PulseBarEntry(date: Date(), metrics: loadMetrics())
        let next  = Calendar.current.date(byAdding: .second, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
    private func loadMetrics() -> WidgetMetrics {
        guard let defaults = UserDefaults(suiteName: "group.com.danyaczhan.pulsebar"),
              let data     = defaults.data(forKey: "widgetMetrics"),
              let metrics  = try? JSONDecoder().decode(WidgetMetrics.self, from: data)
        else { return WidgetMetrics() }
        return metrics
    }
}

struct PulseBarEntry: TimelineEntry {
    let date: Date
    let metrics: WidgetMetrics
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    var metrics: WidgetMetrics
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.05)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill").font(.system(size: 10, weight: .semibold)).foregroundColor(.blue)
                    Text("PulseBar").font(.system(size: 10, weight: .semibold)).foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(metrics.cpuTemp))°")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(tempColor(metrics.cpuTemp))
                    Text("CPU TEMP").font(.system(size: 9, weight: .semibold)).tracking(1).foregroundColor(.white.opacity(0.3))
                }
                HStack {
                    Label("\(Int(metrics.cpuUsage))%", systemImage: "cpu").font(.system(size: 11, weight: .medium)).foregroundColor(.blue)
                    Spacer()
                    Label("\(metrics.batteryLevel)%", systemImage: "battery.75").font(.system(size: 11, weight: .medium)).foregroundColor(batteryColor(metrics.batteryLevel))
                }
            }.padding(14)
        }.clipShape(RoundedRectangle(cornerRadius: 20))
    }
    func tempColor(_ t: Double) -> Color { t > 80 ? .red : t > 65 ? .orange : .green }
    func batteryColor(_ l: Int) -> Color { l < 20 ? .red : l < 40 ? .orange : .green }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    var metrics: WidgetMetrics
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.05)
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "chart.bar.fill").foregroundColor(.blue)
                    Text("PulseBar").font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text(timeAgo(metrics.updatedAt)).font(.system(size: 10)).foregroundColor(.white.opacity(0.25))
                }.padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 12)

                HStack(spacing: 8) {
                    MetricCell(label: "CPU",  value: "\(Int(metrics.cpuTemp))",         unit: "°C", color: .orange)
                    MetricCell(label: "LOAD", value: "\(Int(metrics.cpuUsage))",         unit: "%",  color: .blue)
                    MetricCell(label: "RAM",  value: String(format: "%.1f", metrics.ramUsedGB), unit: "GB", color: .purple)
                    MetricCell(label: "BAT",  value: "\(metrics.batteryLevel)",           unit: "%",  color: batteryColor(metrics.batteryLevel))
                }.padding(.horizontal, 12).padding(.bottom, 14)
            }
        }.clipShape(RoundedRectangle(cornerRadius: 20))
    }
    func batteryColor(_ l: Int) -> Color { l < 20 ? .red : l < 40 ? .orange : .green }
    func timeAgo(_ date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow); return s < 60 ? "\(s)s ago" : "\(s/60)m ago"
    }
}

struct MetricCell: View {
    var label: String; var value: String; var unit: String; var color: Color
    var body: some View {
        VStack(spacing: 3) {
            Text(label).font(.system(size: 9, weight: .semibold)).tracking(0.8).foregroundColor(color.opacity(0.6))
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(value).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(color)
                Text(unit).font(.system(size: 11)).foregroundColor(color.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(color.opacity(0.08)).cornerRadius(10)
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    var metrics: WidgetMetrics
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.05)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.fill").font(.system(size: 16)).foregroundColor(.blue)
                    Text("PulseBar").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Text(timeAgo(metrics.updatedAt)).font(.system(size: 11)).foregroundColor(.white.opacity(0.25))
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    BigMetricCard(label: "CPU TEMP", value: "\(Int(metrics.cpuTemp))",          unit: "°C", color: .orange,  sub: "Load: \(Int(metrics.cpuUsage))%")
                    BigMetricCard(label: "MEMORY",   value: String(format: "%.1f", metrics.ramUsedGB), unit: "GB", color: .purple, sub: "of \(Int(metrics.ramTotalGB)) GB")
                    BigMetricCard(label: "BATTERY",  value: "\(metrics.batteryLevel)",           unit: "%",  color: batteryColor(metrics.batteryLevel), sub: metrics.batteryCharging ? "⚡ Charging" : "On battery")
                    BigMetricCard(label: "NETWORK",  value: metrics.networkUp,                   unit: "",   color: Color(red: 0.35, green: 0.78, blue: 0.98), sub: "Ping: \(Int(metrics.pingMs))ms")
                }
                Spacer()
            }.padding(16)
        }.clipShape(RoundedRectangle(cornerRadius: 20))
    }
    func batteryColor(_ l: Int) -> Color { l < 20 ? .red : l < 40 ? .orange : .green }
    func timeAgo(_ date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow); return s < 60 ? "\(s)s ago" : "\(s/60)m ago"
    }
}

struct BigMetricCard: View {
    var label: String; var value: String; var unit: String; var color: Color; var sub: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 9, weight: .semibold)).tracking(1).foregroundColor(color.opacity(0.6))
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(color)
                if !unit.isEmpty { Text(unit).font(.system(size: 13)).foregroundColor(color.opacity(0.5)) }
            }
            Text(sub).font(.system(size: 10)).foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .background(color.opacity(0.08)).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.15), lineWidth: 0.5))
    }
}

// MARK: - Entry View
struct PulseBarWidgetEntryView: View {
    var entry: PulseBarProvider.Entry
    @Environment(\.widgetFamily) var family
    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(metrics: entry.metrics)
        case .systemMedium: MediumWidgetView(metrics: entry.metrics)
        case .systemLarge:  LargeWidgetView(metrics: entry.metrics)
        default:            MediumWidgetView(metrics: entry.metrics)
        }
    }
}

// MARK: - Widget Configuration
struct PulseBarWidget: Widget {
    let kind = "PulseBarWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PulseBarProvider()) { entry in
            PulseBarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("PulseBar")
        .description("Monitor your Mac's performance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct PulseBarWidgetBundle: WidgetBundle {
    var body: some Widget { PulseBarWidget() }
}
