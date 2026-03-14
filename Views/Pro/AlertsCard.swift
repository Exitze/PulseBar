import SwiftUI

// MARK: - Alerts Card (updated for SmartAlertService)
struct AlertsCard: View {
    @EnvironmentObject var alerts: AlertService

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(Color.accentOrange).font(.system(size: 14))
                    Text("Smart Alerts")
                        .font(.system(size: 12, weight: .medium)).foregroundColor(.white)
                    Spacer()
                    if !alerts.recentAlerts.isEmpty {
                        Button("Clear") { alerts.clearLog() }
                            .font(.system(size: 10)).foregroundColor(Color.secondary).buttonStyle(.plain)
                    }
                }

                if !alerts.recentAlerts.isEmpty {
                    Rectangle().fill(Color.cardBorder).frame(height: 1)
                    Text("Alert Log").font(.system(size: 10, weight: .semibold)).foregroundColor(Color.secondary)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(alerts.recentAlerts.prefix(5)) { alert in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: alert.severity == .critical
                                          ? "exclamationmark.triangle.fill" : "exclamationmark.circle")
                                        .foregroundColor(alert.severity == .critical ? .red : .orange)
                                        .font(.system(size: 10)).padding(.top, 1)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(alert.title)
                                            .font(.system(size: 10)).foregroundColor(.white).lineLimit(2)
                                        Text(alert.timestamp, style: .time)
                                            .font(.system(size: 9)).foregroundColor(Color.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                }
            }
        }
    }
}

struct ThresholdSlider: View {
    let label: String; let unit: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label).font(.system(size: 10)).foregroundColor(Color.secondary)
                Spacer()
                Text(String(format: "%.0f\(unit)", value))
                    .font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundColor(color)
            }
            Slider(value: $value, in: range, step: 5).tint(color).controlSize(.mini)
        }
    }
}
