import SwiftUI

// Card 3: Memory — arc + odometer + smart color + sparkline + pulse
struct MemoryCard: View {
    let ram: RAMData
    @EnvironmentObject var monitor: MonitorService
    @State private var pulse = false

    private var usedPct: Double { ram.totalGB > 0 ? (ram.usedGB / ram.totalGB) * 100.0 : 0 }
    private var isStressed: Bool { ram.totalGB > 0 && (ram.usedGB / ram.totalGB) > 0.8 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MEMORY")
                .font(.metricLabel).tracking(1.2).foregroundColor(Color.textSecondary)
            Spacer(minLength: 4)
            HStack(alignment: .center, spacing: 10) {
                ArcIndicatorView(value: usedPct / 100, color: .accentPurple, size: 52, lineWidth: 5)
                VStack(alignment: .leading, spacing: 2) {
                    OdometerText(
                        value: String(format: "%.1f", ram.usedGB),
                        font: .system(size: 28, weight: .bold, design: .rounded),
                        color: .accentPurple
                    )
                    Text("GB").font(.system(size: 13)).foregroundColor(Color.textSecondary)
                }
            }
            Text(String(format: "of %.0f GB", ram.totalGB))
                .font(.metricSub).foregroundColor(Color.textTertiary)
                .padding(.top, 4).padding(.bottom, 4)
            if !monitor.ramHistory.isEmpty {
                SparklineView(data: monitor.ramHistory, color: .accentPurple, height: 20)
            }
        }
        .padding(DS.cardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .fill(Color.accentPurple.opacity(pulse ? 0.16 : 0.08))
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(Color.accentPurple.opacity(pulse ? 0.4 : 0.18), lineWidth: 1)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
        )
        .onAppear { pulse = isStressed }
        .onChange(of: isStressed) { pulse = $0 }
    }
}

// Legacy alias
typealias CPURAMCard = _CPURAMCardLegacy
struct _CPURAMCardLegacy: View {
    let cpu: CPUData; let ram: RAMData
    var body: some View {
        HStack(spacing: DS.gridGap) {
            CPULoadCard(cpu: cpu)
            MemoryCard(ram: ram)
        }
    }
}
