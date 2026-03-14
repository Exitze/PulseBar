import SwiftUI
import Charts

// MARK: - Feature 2: Full Dashboard View
struct DashboardView: View {
    @EnvironmentObject var monitor: MonitorService
    @EnvironmentObject var ai:      AIAnalysisService

    var body: some View {
        ZStack {
            Color(hex8: "#0A0A0AFF").ignoresSafeArea()

            HStack(alignment: .top, spacing: 12) {
                // LEFT COLUMN
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        SystemInfoCard()
                        AIInsightView().environmentObject(monitor)
                        BatteryHealthView().environmentObject(monitor)
                        FanSpeedView().environmentObject(monitor)
                        Button("Open Dashboard") { DashboardWindowController.shared.show() }
                            .buttonStyle(.plain).foregroundColor(.white.opacity(0.3)).font(.caption)
                    }.padding(.vertical, 12)
                }
                .frame(width: 280)

                // CENTER COLUMN
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        // Dual big arc row
                        HStack(spacing: 16) {
                            VStack(spacing: 4) {
                                ArcIndicatorView(value: monitor.cpuData.temperature / 100,
                                                 color: cpuTempColor(monitor.cpuData.temperature),
                                                 size: 120, lineWidth: 10,
                                                 label: "\(Int(monitor.cpuData.temperature))°")
                                Text("CPU TEMP").font(.system(size: 10, weight: .semibold)).tracking(1.2)
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            VStack(spacing: 4) {
                                ArcIndicatorView(value: monitor.cpuData.usagePercentage / 100,
                                                 color: cpuLoadColor(monitor.cpuData.usagePercentage),
                                                 size: 120, lineWidth: 10,
                                                 label: "\(Int(monitor.cpuData.usagePercentage))%")
                                Text("CPU LOAD").font(.system(size: 10, weight: .semibold)).tracking(1.2)
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }

                        // CPU Sparkline
                        DashboardChartCard(title: "CPU TEMPERATURE (5 MIN)",
                                           data: monitor.cpuTempHistory,
                                           color: cpuTempColor(monitor.cpuData.temperature))

                        // RAM Arc + sparkline
                        DashboardChartCard(title: "RAM USAGE (5 MIN)",
                                           data: monitor.ramHistory,
                                           color: .accentPurple)
                    }.padding(.vertical, 12)
                }
                .frame(maxWidth: .infinity)

                // RIGHT COLUMN
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        // Network chart
                        DashboardChartCard(title: "NETWORK ↑ (5 MIN)",
                                           data: monitor.networkUpHistory,
                                           color: .accentTeal)
                        // Top 5 processes
                        TopProcessesCard(processes: monitor.topCPUProcesses)
                        // Disk volumes
                        DiskCard(disk: monitor.diskData).environmentObject(monitor).frame(height: 140)
                    }.padding(.vertical, 12)
                }
                .frame(width: 280)
            }
            .padding(.horizontal, 12)
        }
        // Bottom bar overlay
        .overlay(alignment: .bottom) {
            HStack {
                Label("3s refresh", systemImage: "arrow.clockwise").font(.caption).foregroundColor(.white.opacity(0.3))
                Spacer()
                Text("Updated \(monitor.lastUpdated.formatted(.dateTime.hour().minute().second()))")
                    .font(.caption).foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
    }
}

struct SystemInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("System", systemImage: "desktopcomputer").font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            Text(ProcessInfo.processInfo.hostName)
                .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
            Text("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
                .font(.caption).foregroundColor(.white.opacity(0.4))
            Text("\(ProcessInfo.processInfo.processorCount) cores")
                .font(.caption).foregroundColor(.white.opacity(0.4))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04)).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

struct DashboardChartCard: View {
    var title: String
    var data:  [Double]
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 9, weight: .semibold)).tracking(1.2).foregroundColor(.white.opacity(0.3))
            if !data.isEmpty {
                Chart(Array(data.enumerated()), id: \.offset) { i, val in
                    LineMark(x: .value("t", i), y: .value("v", val))
                        .foregroundStyle(color.gradient)
                        .interpolationMethod(.catmullRom)
                    AreaMark(x: .value("t", i), y: .value("v", val))
                        .foregroundStyle(color.opacity(0.12).gradient)
                }
                .chartXAxis(.hidden)
                .chartYAxis { AxisMarks(position: .leading) { v in
                    AxisValueLabel { if let d = v.as(Double.self) { Text(String(format: "%.0f", d)).font(.system(size: 8)).foregroundColor(.white.opacity(0.3)) } }
                }}
                .frame(height: 80)
            } else {
                Rectangle().fill(Color.white.opacity(0.04)).frame(height: 80).cornerRadius(6)
            }
        }
        .padding(12).background(Color.white.opacity(0.04)).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

struct TopProcessesCard: View {
    var processes: [ProcessData]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TOP PROCESSES").font(.system(size: 9, weight: .semibold)).tracking(1.2)
                .foregroundColor(.white.opacity(0.3))
            ForEach(processes.prefix(5)) { proc in
                HStack {
                    Text(proc.name).font(.system(size: 11)).foregroundColor(.white).lineLimit(1)
                    Spacer()
                    Text(String(format: "%.1f%%", proc.cpuPercentage))
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(.accentOrange)
                    Button {
                        Darwin.kill(proc.pid, SIGTERM)
                    } label: {
                        Image(systemName: "xmark.circle").foregroundColor(.accentRed).font(.system(size: 11))
                    }.buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(12).background(Color.white.opacity(0.04)).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}
