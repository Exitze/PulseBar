import SwiftUI

// MARK: - Feature 8: Battery Health View
struct BatteryHealthView: View {
    @EnvironmentObject var monitor: MonitorService

    private var healthColor: Color {
        if monitor.batteryHealthPercent > 80 { return .accentGreen }
        if monitor.batteryHealthPercent > 60 { return .accentOrange }
        return .accentRed
    }

    var body: some View {
        HStack(spacing: 16) {
            ArcIndicatorView(
                value: monitor.batteryHealthPercent / 100,
                color: healthColor, size: 56, lineWidth: 5,
                label: "\(Int(monitor.batteryHealthPercent))%"
            )

            VStack(alignment: .leading, spacing: 4) {
                Label("Battery Health", systemImage: "heart.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(healthColor)

                Text("\(monitor.batteryCycleCount) charge cycles")
                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.4))

                if monitor.batteryTemp > 0 {
                    Text(String(format: "%.1f°C battery", monitor.batteryTemp))
                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
                }

                if monitor.batteryMaxCapacity > 0 {
                    Text("\(monitor.batteryMaxCapacity) / \(monitor.batteryDesignCapacity) mAh")
                        .font(.system(size: 10)).foregroundColor(.white.opacity(0.3))
                }
            }
            Spacer()
        }
        .padding(12)
        .background(healthColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: DS.cardRadius)
            .stroke(healthColor.opacity(0.18), lineWidth: 1))
    }
}
