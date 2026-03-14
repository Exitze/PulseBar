import SwiftUI

// MARK: - Feature 5: Live Settings Preview
struct LivePreviewView: View {
    @AppStorage("menuBarLayout")  var layout: String        = "iconOnly"
    @AppStorage("primaryMetric") var primaryMetric: String = "cpuTemp"
    @EnvironmentObject var monitor: MonitorService

    var body: some View {
        VStack(spacing: 16) {
            // Menu bar preview
            VStack(alignment: .leading, spacing: 6) {
                Text("MENU BAR")
                    .font(.system(size: 9, weight: .semibold)).tracking(1.2)
                    .foregroundColor(.white.opacity(0.25))
                HStack(spacing: 6) {
                    Spacer()
                    HStack(spacing: 5) {
                        Image(systemName: "chart.bar.fill").font(.system(size: 11))
                            .foregroundColor(menuBarIconColor)
                        if layout == "iconMetric" || layout == "multiMetric" {
                            Text(primaryMetricValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(menuBarIconColor)
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.white.opacity(0.08)).cornerRadius(6)
                    Text("🔋22%").font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
                    Text("23:06").font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
                }
                .padding(8).background(Color.black.opacity(0.6)).cornerRadius(8)
            }
            // Mini popup preview
            VStack(alignment: .leading, spacing: 4) {
                Text("POPUP")
                    .font(.system(size: 9, weight: .semibold)).tracking(1.2)
                    .foregroundColor(.white.opacity(0.25))
                VStack(spacing: 4) {
                    HStack {
                        Text("PULSEBAR").font(.system(size: 7, weight: .semibold)).tracking(1)
                            .foregroundColor(.white.opacity(0.3))
                        Spacer()
                        Image(systemName: "gearshape").font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 3) {
                        MiniMetricCell(label: "CPU",  value: "\(Int(monitor.cpuData.temperature))°",  color: cpuTempColor(monitor.cpuData.temperature))
                        MiniMetricCell(label: "LOAD", value: "\(Int(monitor.cpuData.usagePercentage))%", color: cpuLoadColor(monitor.cpuData.usagePercentage))
                        MiniMetricCell(label: "RAM",  value: "\(String(format: "%.1f", monitor.ramData.usedGB))G", color: .accentPurple)
                        MiniMetricCell(label: "BAT",  value: "\(Int(monitor.batteryData.percentage))%", color: batteryColorFor(monitor.batteryData.percentage, charging: monitor.batteryData.isCharging))
                    }
                }
                .padding(8).background(Color(hex8: "#111113")).cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
                .frame(width: 160)
            }
        }
        .padding(14).background(Color.white.opacity(0.03)).cornerRadius(12)
    }

    var menuBarIconColor: Color { cpuTempColor(monitor.cpuData.temperature) }
    var primaryMetricValue: String {
        switch primaryMetric {
        case "cpuTemp": return "\(Int(monitor.cpuData.temperature))°C"
        case "cpuLoad": return "\(Int(monitor.cpuData.usagePercentage))%"
        case "ram":     return String(format: "%.1fG", monitor.ramData.usedGB)
        default:        return "\(Int(monitor.cpuData.temperature))°C"
        }
    }
}

struct MiniMetricCell: View {
    var label: String; var value: String; var color: Color
    var body: some View {
        VStack(spacing: 1) {
            Text(label).font(.system(size: 7, weight: .semibold)).tracking(0.8).foregroundColor(color.opacity(0.6))
            Text(value).font(.system(size: 11, weight: .bold)).foregroundColor(color)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 5)
        .background(color.opacity(0.08)).cornerRadius(6)
    }
}
