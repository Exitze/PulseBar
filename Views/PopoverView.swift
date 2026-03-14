import SwiftUI
import ServiceManagement

struct PopoverView: View {
    @EnvironmentObject var monitor: MonitorService
    @EnvironmentObject var store:   StoreService
    @EnvironmentObject var alerts:  AlertService

    @State private var currentPage: Int = 0
    @AppStorage("floatWidgetEnabled") private var floatWidgetEnabled = false

    private let tabs = ["Overview", "Processes", "History"]

    var body: some View {
        VStack(spacing: 0) {
            // ── HEADER ROW ────────────────────────────────────────
            HStack(spacing: 8) {
                Text("PULSEBAR")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.25))
                Spacer()
                // Pro badge
                if store.isPro {
                    Text("PRO ✓")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color(hex: "#1A3A2A"))
                        .foregroundColor(Color(hex: "#32D74B"))
                        .clipShape(Capsule())
                } else {
                    Button {
                        NSApp.sendAction(#selector(AppDelegate.openSettingsProTab), to: nil, from: nil)
                    } label: {
                        Text("PRO")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Color.accentOrange.opacity(0.2))
                            .foregroundColor(Color.accentOrange)
                            .clipShape(Capsule())
                    }.buttonStyle(.plain)
                }
                // Gear
                Button {
                    NotificationCenter.default.post(name: .openPulseBarSettings, object: nil)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.3))
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)

            // ── SEGMENTED PILL SWITCHER ───────────────────────────
            HStack(spacing: 2) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { idx, tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            currentPage = idx
                        }
                    } label: {
                        Text(tab)
                            .font(.system(size: 12, weight: currentPage == idx ? .semibold : .regular))
                            .foregroundColor(currentPage == idx ? .white : .white.opacity(0.35))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(currentPage == idx ? Color.white.opacity(0.1) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            // ── PAGE CONTENT ──────────────────────────────────────
            Group {
                switch currentPage {
                case 0: overviewPage
                case 1: processesPage
                default: historyPage
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentPage)
            .frame(maxHeight: 480)

            // ── FOOTER ────────────────────────────────────────────
            HStack {
                Text(timeAgo(from: monitor.lastUpdated))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.2))
                Spacer()
                HStack(spacing: 4) {
                    Text("Float")
                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.3))
                    Toggle("", isOn: $floatWidgetEnabled)
                        .toggleStyle(.switch).controlSize(.mini)
                        .onChange(of: floatWidgetEnabled) { val in
                            val ? FloatingWidgetController.shared.show()
                                : FloatingWidgetController.shared.hide()
                        }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5), alignment: .top)
        }
        .frame(width: DS.popupWidth)
        .background(Color(hex: "#0A0A0A"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // ── Overview ─────────────────────────────────────────────
    var overviewPage: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                SmartStatusView(status: monitor.smartStatus)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 8
                ) {
                    CPUTempCard2(cpu: monitor.cpuData).environmentObject(monitor)
                    CPULoadCard(cpu: monitor.cpuData).environmentObject(monitor)
                    MemoryCard(ram: monitor.ramData).environmentObject(monitor)
                    BatteryCard(battery: monitor.batteryData).environmentObject(monitor)
                }
                .frame(height: 320)

                NetworkCard2(network: monitor.networkData).environmentObject(monitor)
                    .frame(height: 100)

                DiskCard(disk: monitor.diskData).environmentObject(monitor)
                    .frame(height: 100)

                if !monitor.coreUsages.isEmpty {
                    CoreHeatmapView().environmentObject(monitor)
                }

                BatteryHealthView().environmentObject(monitor)
                FanSpeedView().environmentObject(monitor)
            }
            .padding(.horizontal, 14).padding(.bottom, 14)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal:   .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // ── Processes ─────────────────────────────────────────────
    var processesPage: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                GPUCard(gpu: monitor.gpuData)
                ProcessCard(topCPU: monitor.topCPUProcesses, topRAM: monitor.topRAMProcesses)
                if !store.isPro {
                    LockedProBanner {
                        NSApp.sendAction(#selector(AppDelegate.openSettingsProTab), to: nil, from: nil)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.bottom, 14)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal:   .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // ── History ───────────────────────────────────────────────
    var historyPage: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                ThermalHistoryCard(history: monitor.thermalHistory)
                if !store.isPro {
                    LockedProBanner {
                        NSApp.sendAction(#selector(AppDelegate.openSettingsProTab), to: nil, from: nil)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.bottom, 14)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal:   .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private func timeAgo(from date: Date) -> String {
        let d = Int(Date().timeIntervalSince(date))
        if d < 5 { return "Updated just now" }
        if d < 60 { return "Updated \(d)s ago" }
        return "Updated \(d/60)m ago"
    }
}

// MARK: - Locked Pro Banner
struct LockedProBanner: View {
    var onTap: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill").foregroundColor(Color.accentOrange).font(.system(size: 13))
                VStack(alignment: .leading, spacing: 2) {
                    Text("GPU · Processes · Thermal History · Alerts")
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(Color.textPrimary)
                    Text("Tap to unlock Pro — one-time $2.99")
                        .font(.system(size: 10)).foregroundColor(Color.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(Color.textTertiary)
            }
            .padding(DS.cardPadding)
            .background(Color.accentOrange.opacity(hovered ? 0.11 : 0.07))
            .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(Color.accentOrange.opacity(hovered ? 0.25 : 0.15), lineWidth: 1))
            .scaleEffect(hovered ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: hovered)
        }
        .buttonStyle(.plain).onHover { hovered = $0 }
    }
}
