import SwiftUI

// MARK: - Feature 10: Fan Speed View
struct FanSpeedView: View {
    @EnvironmentObject var monitor: MonitorService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(monitor.fanSpeeds) { fan in
                HStack(spacing: 10) {
                    SpinningFanIcon(rpm: fan.currentRPM)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fan.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(fan.currentRPM) RPM")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(fanColor(fan.loadPercent))
                    }
                    Spacer()
                    ArcIndicatorView(value: fan.loadPercent,
                                     color: fanColor(fan.loadPercent),
                                     size: 36, lineWidth: 3)
                }
            }
            if monitor.fanSpeeds.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "fan.fill").foregroundColor(.white.opacity(0.2))
                    Text("No fans detected (Apple Silicon)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: DS.cardRadius)
            .stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    func fanColor(_ load: Double) -> Color {
        load > 0.7 ? .accentRed : load > 0.4 ? .accentOrange : .accentTeal
    }
}

struct SpinningFanIcon: View {
    var rpm: Int
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "fan.fill")
            .font(.system(size: 18))
            .foregroundColor(.white.opacity(0.5))
            .rotationEffect(.degrees(rotation))
            .onAppear { startSpinning() }
            .onChange(of: rpm) { _ in startSpinning() }
    }

    func startSpinning() {
        let duration = rpm > 0 ? max(0.3, 6000.0 / Double(rpm)) : 2.0
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
}
