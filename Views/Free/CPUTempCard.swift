import SwiftUI

// Card 1: CPU Temperature — arc + odometer + smart color + sparkline + pulse
struct CPUTempCard2: View {
    let cpu: CPUData
    @EnvironmentObject var monitor: MonitorService
    @State private var pulse = false

    private var accent: Color { cpuTempColor(cpu.temperature) }
    private var isStressed: Bool { cpu.temperature > 75 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CPU TEMP")
                .font(.metricLabel).tracking(1.2).foregroundColor(Color.textSecondary)

            Spacer(minLength: 4)

            // Arc + odometer row
            HStack(alignment: .center, spacing: 10) {
                ArcIndicatorView(value: cpu.temperature / 100, color: accent, size: 52, lineWidth: 5)
                VStack(alignment: .leading, spacing: 2) {
                    OdometerText(
                        value: "\(Int(cpu.temperature))",
                        font: .system(size: 32, weight: .bold, design: .rounded),
                        color: accent
                    )
                    Text("°C").font(.system(size: 13)).foregroundColor(Color.textSecondary)
                }
            }

            Text(cpu.activeCoresText)
                .font(.metricSub).foregroundColor(Color.textTertiary)
                .padding(.top, 4).padding(.bottom, 4)

            if !monitor.cpuTempHistory.isEmpty {
                SparklineView(data: monitor.cpuTempHistory, color: accent, height: 20)
            }
        }
        .padding(DS.cardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .fill(accent.opacity(pulse ? 0.16 : 0.08))
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(accent.opacity(pulse ? 0.4 : 0.18), lineWidth: 1)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
        )
        .onAppear { pulse = isStressed }
        .onChange(of: isStressed) { pulse = $0 }
    }
}

// Card 2: CPU Load — arc + odometer + smart color + sparkline + pulse
struct CPULoadCard: View {
    let cpu: CPUData
    @EnvironmentObject var monitor: MonitorService
    @State private var pulse = false

    private var accent: Color { cpuLoadColor(cpu.usagePercentage) }
    private var isStressed: Bool { cpu.usagePercentage > 70 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("LOAD")
                .font(.metricLabel).tracking(1.2).foregroundColor(Color.textSecondary)

            Spacer(minLength: 4)

            HStack(alignment: .center, spacing: 10) {
                ArcIndicatorView(value: cpu.usagePercentage / 100, color: accent, size: 52, lineWidth: 5)
                VStack(alignment: .leading, spacing: 2) {
                    OdometerText(
                        value: "\(Int(cpu.usagePercentage))",
                        font: .system(size: 32, weight: .bold, design: .rounded),
                        color: accent
                    )
                    Text("%").font(.system(size: 13)).foregroundColor(Color.textSecondary)
                }
            }

            Text("CPU usage")
                .font(.metricSub).foregroundColor(Color.textTertiary)
                .padding(.top, 4).padding(.bottom, 4)

            if !monitor.cpuLoadHistory.isEmpty {
                SparklineView(data: monitor.cpuLoadHistory, color: accent, height: 20)
            }
        }
        .padding(DS.cardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .fill(accent.opacity(pulse ? 0.16 : 0.08))
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(accent.opacity(pulse ? 0.4 : 0.18), lineWidth: 1)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
        )
        .onAppear { pulse = isStressed }
        .onChange(of: isStressed) { pulse = $0 }
    }
}
