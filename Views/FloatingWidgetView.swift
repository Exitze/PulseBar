import SwiftUI

struct FloatingWidgetView: View {
    @EnvironmentObject var monitor: MonitorService
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header / drag handle
            HStack {
                Text("PULSEBAR")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.25))
                Spacer()
                Button { FloatingWidgetController.shared.hide() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 8)

            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)

            // Metric rows
            VStack(spacing: 0) {
                FloatRow(icon: "thermometer.medium", label: "CPU",
                         value: "\(Int(monitor.cpuData.temperature))°C",
                         color: floatTempColor(monitor.cpuData.temperature))
                FloatRow(icon: "cpu", label: "Load",
                         value: "\(Int(monitor.cpuData.usagePercentage))%",
                         color: .accentBlue)
                FloatRow(icon: "memorychip", label: "RAM",
                         value: String(format: "%.1f GB", monitor.ramData.usedGB),
                         color: .accentPurple)
                FloatRow(icon: "battery.75", label: "Battery",
                         value: "\(Int(monitor.batteryData.percentage))%",
                         color: .accentGreen)
                FloatRow(icon: "arrow.up", label: "Net ↑",
                         value: monitor.networkData.uploadBytesPerSec.networkFormatted(),
                         color: .accentTeal)
            }
            .padding(.vertical, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
        .opacity(isHovered ? 1.0 : 0.85)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

private func floatTempColor(_ t: Double) -> Color {
    t > 80 ? .accentRed : t > 65 ? .accentOrange : .accentGreen
}

struct FloatRow: View {
    var icon: String; var label: String; var value: String; var color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11)).foregroundColor(color).frame(width: 16)
            Text(label)
                .font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
    }
}
