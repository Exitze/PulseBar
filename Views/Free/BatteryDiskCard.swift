import SwiftUI

// Card 4: Battery — arc + odometer + smart color + sparkline + pulse
struct BatteryCard: View {
    let battery: BatteryData
    @EnvironmentObject var monitor: MonitorService
    @State private var pulse = false

    private var accent: Color { batteryColorFor(battery.percentage, charging: battery.isCharging) }
    private var isStressed: Bool { battery.percentage < 15 && !battery.isCharging }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("BATTERY")
                .font(.metricLabel).tracking(1.2).foregroundColor(Color.textSecondary)
            Spacer(minLength: 4)
            HStack(alignment: .center, spacing: 10) {
                ArcIndicatorView(value: battery.percentage / 100, color: accent, size: 52, lineWidth: 5)
                VStack(alignment: .leading, spacing: 2) {
                    OdometerText(
                        value: "\(Int(battery.percentage))",
                        font: .system(size: 32, weight: .bold, design: .rounded),
                        color: accent
                    )
                    Text("%").font(.system(size: 13)).foregroundColor(Color.textSecondary)
                }
            }
            HStack(spacing: 4) {
                if battery.isCharging {
                    Image(systemName: "bolt.fill").font(.system(size: 9)).foregroundColor(.accentGreen)
                }
                Text(battery.isCharging ? "Charging" : battery.timeRemainingString)
                    .font(.metricSub).foregroundColor(Color.textTertiary)
            }.padding(.top, 4).padding(.bottom, 4)
            if !monitor.ramHistory.isEmpty {
                SparklineView(data: monitor.ramHistory, color: accent, height: 20)
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

// MARK: - NetworkCard2 with ping row (Feature 9) + sparkline
struct NetworkCard2: View {
    let network: NetworkData
    @EnvironmentObject var monitor: MonitorService

    var body: some View {
        MetricCard(accent: .accentTeal, bgOpacity: 0.06, borderOpacity: 0.12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("NETWORK")
                    .font(.metricLabel).tracking(1.2).foregroundColor(Color.textSecondary)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("↑").font(.system(size: 10, weight: .semibold)).foregroundColor(Color.accentTeal)
                        Text(network.uploadBytesPerSec.networkFormatted())
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.accentTeal)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("↓").font(.system(size: 10, weight: .semibold)).foregroundColor(Color.textSecondary)
                        Text(network.downloadBytesPerSec.networkFormatted())
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.textSecondary)
                    }
                    // Feature 9: Ping quality row
                    HStack(spacing: 4) {
                        Image(systemName: monitor.connectionQuality.icon)
                            .foregroundColor(monitor.connectionQuality.color).font(.system(size: 9))
                        Text(monitor.connectionQuality.rawValue)
                            .font(.system(size: 10)).foregroundColor(monitor.connectionQuality.color)
                        Spacer()
                        Text(monitor.pingMs > 0 ? "\(Int(monitor.pingMs)) ms" : "—")
                            .font(.system(size: 10, weight: .semibold)).foregroundColor(.white.opacity(0.5))
                    }
                }
                if !monitor.networkUpHistory.isEmpty {
                    SparklineView(data: monitor.networkUpHistory, color: .accentTeal, height: 16)
                }
            }
        }
    }
}

// MARK: - DiskCard with multi-volume list + arc
struct DiskCard: View {
    let disk: DiskData
    @EnvironmentObject var monitor: MonitorService

    private var usedPct: Double { disk.totalGB > 0 ? disk.usedGB / disk.totalGB : 0 }

    var body: some View {
        MetricCard(accent: .accentBlue, bgOpacity: 0.06, borderOpacity: 0.12) {
            if monitor.diskVolumes.isEmpty {
                legacyDiskView
            } else {
                multiVolumeView
            }
        }
    }

    var legacyDiskView: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DISK").font(.metricLabel).tracking(1.2).foregroundColor(Color.textSecondary)
                OdometerText(value: "\(Int(disk.usedGB))", font: .mediumNumber, color: .accentBlue)
            }
            Spacer()
            ArcIndicatorView(value: usedPct, color: .accentBlue, size: 44, lineWidth: 4)
        }
    }

    var multiVolumeView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("DISK").font(.metricLabel).tracking(1.2).foregroundColor(Color.textSecondary)
            ForEach(Array(monitor.diskVolumes.prefix(3))) { vol in
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: vol.isRemovable ? "externaldrive.fill" : "internaldrive")
                            .font(.system(size: 9)).foregroundColor(Color.accentBlue)
                        Text(vol.name).font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.textPrimary).lineLimit(1)
                        Spacer()
                        Text(String(format: "%.0f/%.0f GB", vol.usedGB, vol.totalGB))
                            .font(.system(size: 9)).foregroundColor(Color.textTertiary)
                    }
                    ThinProgressBar(value: vol.usagePercent * 100, color: .accentBlue)
                }
            }
        }
    }
}

// MARK: - Legacy aliases
struct BatteryDiskCard: View {
    let battery: BatteryData; let disk: DiskData
    var body: some View {
        HStack(spacing: DS.gridGap) { BatteryCard(battery: battery); DiskCard(disk: disk) }
    }
}
struct NetworkCard: View {
    let network: NetworkData
    var body: some View { NetworkCard2(network: network) }
}
