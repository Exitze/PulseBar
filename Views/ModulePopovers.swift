import SwiftUI

// MARK: - Shared popover chrome
struct ModulePopoverChrome<Content: View>: View {
    var title: String; var icon: String; var iconColor: Color
    var moduleId: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundColor(iconColor).font(.system(size: 13, weight: .semibold))
                Text(title).font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 8)

            Divider().opacity(0.3)

            // Content
            content()

            Divider().opacity(0.3)

            // Footer
            Button("Settings…") {
                UserDefaults.standard.set(moduleId, forKey: "settingsSelectedModule")
                NotificationCenter.default.post(name: .openPulseBarSettings, object: nil)
            }
            .buttonStyle(.plain).font(.system(size: 11)).foregroundColor(.secondary)
            .padding(.horizontal, 14).padding(.vertical, 8)
        }
        .frame(width: 260)
    }
}

// MARK: - CPU Popover
struct CPUPopoverView: View {
    @EnvironmentObject var monitor: MonitorService
    var body: some View {
        ModulePopoverChrome(title: "CPU", icon: "cpu", iconColor: .accentBlue, moduleId: "cpu") {
            VStack(spacing: 12) {
                // Usage big number
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(Int(monitor.cpuData.usagePercentage))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(cpuLoadColor(monitor.cpuData.usagePercentage))
                    Text("%").font(.system(size: 20)).foregroundColor(.secondary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.0f°C", monitor.cpuData.temperature))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(cpuTempColor(monitor.cpuData.temperature))
                        Text("Temperature").font(.caption).foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 14).padding(.top, 10)

                // Per-core bars
                if !monitor.coreUsages.isEmpty {
                    MiniCoreChart(coreLoads: monitor.coreUsages)
                        .padding(.horizontal, 14)
                }

                // Top CPU processes
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOP PROCESSES").font(.system(size: 9, weight: .semibold)).tracking(1)
                        .foregroundColor(.secondary).padding(.horizontal, 14)
                    ForEach(monitor.topCPUProcesses.prefix(3)) { proc in
                        HStack {
                            Text(proc.name).font(.system(size: 11)).lineLimit(1)
                            Spacer()
                            Text(String(format: "%.1f%%", proc.cpuPercentage))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.accentBlue)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 2)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }
}

struct MiniCoreChart: View {
    var coreLoads: [Double]
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(coreLoads.enumerated()), id: \.offset) { _, load in
                RoundedRectangle(cornerRadius: 2)
                    .fill(cpuLoadColor(load * 100).opacity(0.8))
                    .frame(width: max(3, (232 / CGFloat(coreLoads.count)) - 2), height: 20 * CGFloat(load) + 2)
                    .animation(.spring(response: 0.4), value: load)
            }
        }
        .frame(height: 24)
    }
}

// MARK: - RAM Popover
struct RAMPopoverView: View {
    @EnvironmentObject var monitor: MonitorService
    private var pct: Double { monitor.ramData.totalGB > 0 ? monitor.ramData.usedGB / monitor.ramData.totalGB : 0 }
    var body: some View {
        ModulePopoverChrome(title: "RAM", icon: "memorychip", iconColor: .accentPurple, moduleId: "ram") {
            VStack(spacing: 10) {
                HStack(alignment: .center, spacing: 14) {
                    ArcIndicatorView(value: pct, color: .accentPurple, size: 56, lineWidth: 5,
                                     label: "\(Int(pct * 100))%")
                    VStack(alignment: .leading, spacing: 4) {
                        InfoRow(label: "Used",  value: String(format: "%.1f GB", monitor.ramData.usedGB), color: .accentPurple)
                        InfoRow(label: "Total", value: String(format: "%.0f GB", monitor.ramData.totalGB), color: Color(NSColor.secondaryLabelColor))
                    }
                    Spacer()
                }
                .padding(.horizontal, 14).padding(.top, 10)

                SparklineView(data: monitor.ramHistory, color: .accentPurple, height: 30)
                    .padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 4) {
                    Text("TOP MEMORY").font(.system(size: 9, weight: .semibold)).tracking(1)
                        .foregroundColor(.secondary).padding(.horizontal, 14)
                    ForEach(monitor.topRAMProcesses.prefix(3)) { proc in
                        HStack {
                            Text(proc.name).font(.system(size: 11)).lineLimit(1)
                            Spacer()
                            Text(String(format: "%.0f MB", Double(proc.ramBytes) / 1_048_576))
                                .font(.system(size: 11, weight: .semibold)).foregroundColor(.accentPurple)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 2)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - GPU Popover
struct GPUPopoverView: View {
    @EnvironmentObject var monitor: MonitorService
    var body: some View {
        ModulePopoverChrome(title: "GPU", icon: "rectangle.3.group", iconColor: .accentOrange, moduleId: "gpu") {
            VStack(spacing: 12) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(Int(monitor.gpuData.usagePercentage))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.accentOrange)
                    Text("%").font(.system(size: 20)).foregroundColor(.secondary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.0f°C", monitor.gpuData.temperature))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(cpuTempColor(monitor.gpuData.temperature))
                        Text("Temp").font(.caption).foregroundColor(.secondary)
                    }
                }.padding(.horizontal, 14).padding(.top, 10)

                HStack(spacing: 0) {
                    InfoRow(label: "VRAM Used",  value: String(format: "%.1f GB", monitor.gpuData.vramUsedGB),  color: .accentOrange)
                    Spacer()
                    InfoRow(label: "VRAM Total", value: String(format: "%.0f GB", monitor.gpuData.vramTotalGB), color: Color(NSColor.secondaryLabelColor))
                }.padding(.horizontal, 14).padding(.bottom, 12)
            }
        }
    }
}

// MARK: - Network Popover
struct NetworkPopoverView: View {
    @EnvironmentObject var monitor: MonitorService
    var body: some View {
        ModulePopoverChrome(title: "Network", icon: "network", iconColor: .accentTeal, moduleId: "network") {
            VStack(spacing: 10) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("↑").foregroundColor(.accentTeal).font(.system(size: 11, weight: .semibold))
                            Text(monitor.networkData.uploadBytesPerSec.networkFormatted())
                                .font(.system(size: 14, weight: .bold))
                        }
                        HStack(spacing: 4) {
                            Text("↓").foregroundColor(.secondary).font(.system(size: 11, weight: .semibold))
                            Text(monitor.networkData.downloadBytesPerSec.networkFormatted())
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: monitor.connectionQuality.icon)
                            .foregroundColor(monitor.connectionQuality.color)
                        Text(monitor.pingMs > 0 ? "\(Int(monitor.pingMs)) ms" : "—")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }.padding(.horizontal, 14).padding(.top, 10)

                if !monitor.networkUpHistory.isEmpty {
                    SparklineView(data: monitor.networkUpHistory, color: .accentTeal, height: 30)
                        .padding(.horizontal, 14)
                }
                Text(monitor.networkData.interfaceName)
                    .font(.caption).foregroundColor(.secondary)
                    .padding(.horizontal, 14).padding(.bottom, 10)
            }
        }
    }
}

// MARK: - Disk Popover
struct DiskPopoverView: View {
    @EnvironmentObject var monitor: MonitorService
    var body: some View {
        ModulePopoverChrome(title: "Disk", icon: "internaldrive", iconColor: .accentBlue, moduleId: "disk") {
            VStack(alignment: .leading, spacing: 8) {
                if monitor.diskVolumes.isEmpty {
                    let pct = monitor.diskData.totalGB > 0 ? monitor.diskData.usedGB / monitor.diskData.totalGB : 0
                    InfoRow(label: "Usage", value: String(format: "%.0f / %.0f GB", monitor.diskData.usedGB, monitor.diskData.totalGB), color: .accentBlue)
                        .padding(.horizontal, 14).padding(.top, 10)
                    ThinProgressBar(value: pct * 100, color: .accentBlue).padding(.horizontal, 14)
                } else {
                    ForEach(monitor.diskVolumes.prefix(4)) { vol in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Image(systemName: vol.isRemovable ? "externaldrive.fill" : "internaldrive")
                                    .font(.system(size: 10)).foregroundColor(.accentBlue)
                                Text(vol.name).font(.system(size: 11, weight: .medium)).lineLimit(1)
                                Spacer()
                                Text(String(format: "%.0f/%.0f GB", vol.usedGB, vol.totalGB))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            ThinProgressBar(value: vol.usagePercent * 100, color: .accentBlue)
                        }
                        .padding(.horizontal, 14)
                    }
                    .padding(.top, 10)
                }
                Spacer(minLength: 8)
            }
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Battery Popover
struct BatteryPopoverView: View {
    @EnvironmentObject var monitor: MonitorService
    private var bColor: Color { batteryColorFor(monitor.batteryData.percentage, charging: monitor.batteryData.isCharging) }
    var body: some View {
        ModulePopoverChrome(title: "Battery", icon: "battery.75", iconColor: .accentGreen, moduleId: "battery") {
            VStack(spacing: 10) {
                HStack(spacing: 16) {
                    ArcIndicatorView(value: monitor.batteryData.percentage / 100,
                                     color: bColor, size: 56, lineWidth: 5,
                                     label: "\(Int(monitor.batteryData.percentage))%")
                    VStack(alignment: .leading, spacing: 4) {
                        InfoRow(label: "Status", value: monitor.batteryData.isCharging ? "Charging ⚡" : "On battery", color: bColor)
                        InfoRow(label: "Time",   value: monitor.batteryData.timeRemainingString, color: Color(NSColor.secondaryLabelColor))
                    }
                    Spacer()
                }.padding(.horizontal, 14).padding(.top, 10)

                if monitor.batteryHealthPercent > 0 {
                    Divider().opacity(0.3).padding(.horizontal, 14)
                    VStack(alignment: .leading, spacing: 4) {
                        InfoRow(label: "Health",  value: String(format: "%.0f%%", monitor.batteryHealthPercent), color: monitor.batteryHealthPercent > 80 ? .accentGreen : .accentOrange)
                        InfoRow(label: "Cycles",  value: "\(monitor.batteryCycleCount)", color: Color(NSColor.secondaryLabelColor))
                    }.padding(.horizontal, 14)
                }
                Spacer(minLength: 8)
            }.padding(.bottom, 4)
        }
    }
}

// MARK: - Shared small helper
struct InfoRow: View {
    var label: String; var value: String; var color: Color
    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.system(size: 11, weight: .semibold)).foregroundColor(color)
        }
    }
}
