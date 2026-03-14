import Cocoa
import SwiftUI
import Combine
import UserNotifications
import Darwin

extension Notification.Name {
    static let openPulseBarSettings = Notification.Name("openPulseBarSettings")
}

// MARK: - Module definition
struct BarModule: Identifiable {
    let id: String          // "cpu", "ram", "gpu", "network", "disk", "battery"
    var title: String
    var sfSymbol: String
}

let allModules: [BarModule] = [
    BarModule(id: "cpu",     title: "CPU",     sfSymbol: "cpu"),
    BarModule(id: "ram",     title: "RAM",     sfSymbol: "memorychip"),
    BarModule(id: "gpu",     title: "GPU",     sfSymbol: "rectangle.3.group"),
    BarModule(id: "network", title: "Network", sfSymbol: "network"),
    BarModule(id: "disk",    title: "Disk",    sfSymbol: "internaldrive"),
    BarModule(id: "battery", title: "Battery", sfSymbol: "battery.75"),
]

class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - State
    var statusItems: [String: NSStatusItem] = [:]
    var popovers:    [String: NSPopover]    = [:]
    let monitor     = MonitorService.shared
    let store       = StoreService.shared
    let alertSvc    = AlertService()

    private var hotKeyMonitor:      Any?
    private var settingsObserver:   NSObjectProtocol?
    private var defaultsObserver:   NSObjectProtocol?
    private var monitorCancellable: AnyCancellable?

    // MARK: - Launch
    func applicationDidFinishLaunching(_ n: Notification) {
        SettingsWindowController.shared.configure(
            monitorService: monitor,
            storeService:   store,
            alertService:   alertSvc
        )

        // Kick off monitoring
        monitor.startMonitoring()

        // Build all module status items
        setupStatusItems()

        // React to monitor data
        monitorCancellable = monitor.$lastUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshAllStatusItems() }

        // Open settings notification
        settingsObserver = NotificationCenter.default.addObserver(
            forName: .openPulseBarSettings, object: nil, queue: .main
        ) { [weak self] _ in self?.openSettings() }

        // React to UserDefaults changes (show/hide modules)
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.syncModuleVisibility() }

        // Feature 6 — global hotkey
        setupHotKey()

        // Feature 11 — weekly report
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
        WeeklyReportService.shared.scheduleWeeklyReport()
    }

    // MARK: - Build / Tear down status items
    func setupStatusItems() {
        for module in allModules {
            let shown = UserDefaults.standard.object(forKey: "show_\(module.id)") as? Bool ?? true
            if shown { createStatusItem(for: module) }
        }
    }

    func createStatusItem(for module: BarModule) {
        guard statusItems[module.id] == nil else { return }

        let item   = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        // Tag the button with module id via title temporarily
        item.button?.identifier = NSUserInterfaceItemIdentifier(module.id)

        // Draw placeholder image right away
        item.button?.image  = placeholderImage(for: module)
        item.button?.imagePosition = .imageLeft

        statusItems[module.id] = item

        // Build popover for this module
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 260, height: 340)

        let asSvc  = alertSvc
        let popoverRootView: AnyView
        switch module.id {
        case "cpu":     popoverRootView = AnyView(CPUPopoverView().environmentObject(monitor).environmentObject(store).environmentObject(asSvc))
        case "ram":     popoverRootView = AnyView(RAMPopoverView().environmentObject(monitor).environmentObject(store).environmentObject(asSvc))
        case "gpu":     popoverRootView = AnyView(GPUPopoverView().environmentObject(monitor).environmentObject(store).environmentObject(asSvc))
        case "network": popoverRootView = AnyView(NetworkPopoverView().environmentObject(monitor).environmentObject(store).environmentObject(asSvc))
        case "disk":    popoverRootView = AnyView(DiskPopoverView().environmentObject(monitor).environmentObject(store).environmentObject(asSvc))
        case "battery": popoverRootView = AnyView(BatteryPopoverView().environmentObject(monitor).environmentObject(store).environmentObject(asSvc))
        default:        popoverRootView = AnyView(Text("Module"))
        }

        // Wrap in NSVisualEffectView via NSHostingController
        let vc = ModulePopoverVC(rootView: popoverRootView)
        popover.contentViewController = vc
        popovers[module.id] = popover
    }

    func removeStatusItem(for moduleId: String) {
        if let item = statusItems[moduleId] {
            NSStatusBar.system.removeStatusItem(item)
            statusItems.removeValue(forKey: moduleId)
        }
        popovers.removeValue(forKey: moduleId)
    }

    func syncModuleVisibility() {
        for module in allModules {
            let shown = UserDefaults.standard.object(forKey: "show_\(module.id)") as? Bool ?? true
            if shown && statusItems[module.id] == nil   { createStatusItem(for: module) }
            if !shown && statusItems[module.id] != nil  { removeStatusItem(for: module.id) }
        }
    }

    // MARK: - Click handler
    @objc func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let moduleId = sender.identifier?.rawValue,
              let item     = statusItems[moduleId],
              let popover  = popovers[moduleId],
              let button   = item.button else { return }

        if popover.isShown { popover.performClose(nil) }
        else {
            // Close all other popovers first
            popovers.values.forEach { if $0.isShown { $0.performClose(nil) } }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Refresh all status items
    func refreshAllStatusItems() {
        for module in allModules {
            guard let item = statusItems[module.id], let button = item.button else { continue }
            button.image = makeImage(for: module)
            button.imageScaling = .scaleProportionallyDown
        }
    }

    // MARK: - Image drawing
    private func placeholderImage(for module: BarModule) -> NSImage {
        return makeImage(for: module)
    }

    private func makeImage(for module: BarModule) -> NSImage {
        switch module.id {
        case "cpu":     return cpuBarImage()
        case "ram":     return ramBarImage()
        case "gpu":     return gpuBarImage()
        case "network": return networkTextImage()
        case "disk":    return diskTextImage()
        case "battery": return batteryBarImage()
        default:        return NSImage()
        }
    }

    // CPU — mini bar chart per core
    private func cpuBarImage() -> NSImage {
        let cores  = monitor.coreUsages.isEmpty ? [0.0] : monitor.coreUsages
        let showLabel = UserDefaults.standard.object(forKey: "cpu_showLabel") as? Bool ?? true
        let barW: CGFloat = 3
        let gap:  CGFloat = 1
        let h:    CGFloat = 16
        let chartW = CGFloat(cores.count) * (barW + gap) - gap
        let labelH: CGFloat = showLabel ? 7 : 0
        let totalH = h + labelH + (showLabel ? 1 : 0)
        let totalW = chartW

        let img = NSImage(size: NSSize(width: totalW, height: totalH), flipped: false) { _ in
            // FIXED: removed unused [weak self] — drawing uses locally captured `cores` and `showLabel`
            // Background bars
            NSColor.white.withAlphaComponent(0.2).setFill()
            for i in 0..<cores.count {
                let x = CGFloat(i) * (barW + gap)
                NSBezierPath(roundedRect: NSRect(x: x, y: labelH, width: barW, height: h),
                             xRadius: 1, yRadius: 1).fill()
            }
            // Foreground bars
            NSColor.white.setFill()
            for (i, load) in cores.enumerated() {
                let x  = CGFloat(i) * (barW + gap)
                let bh = max(2, h * CGFloat(load))
                NSBezierPath(roundedRect: NSRect(x: x, y: labelH, width: barW, height: bh),
                             xRadius: 1, yRadius: 1).fill()
            }
            if showLabel {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 6, weight: .semibold),
                    .foregroundColor: NSColor.white
                ]
                "CPU".draw(at: NSPoint(x: 0, y: 0), withAttributes: attrs)
            }
            return true
        }
        img.isTemplate = true
        return img
    }

    // RAM — single filled bar
    private func ramBarImage() -> NSImage {
        let pct = monitor.ramData.totalGB > 0
            ? CGFloat(monitor.ramData.usedGB / monitor.ramData.totalGB) : 0
        let showLabel = UserDefaults.standard.object(forKey: "ram_showLabel") as? Bool ?? true
        let w: CGFloat = 8; let h: CGFloat = 16
        let labelH: CGFloat = showLabel ? 7 : 0
        let totalH = h + labelH + (showLabel ? 1 : 0)

        let img = NSImage(size: NSSize(width: w + 16, height: totalH), flipped: false) { _ in
            NSColor.white.withAlphaComponent(0.2).setFill()
            NSBezierPath(roundedRect: NSRect(x: 14, y: labelH, width: w, height: h), xRadius: 2, yRadius: 2).fill()
            NSColor.white.setFill()
            NSBezierPath(roundedRect: NSRect(x: 14, y: labelH, width: w, height: max(2, h * pct)), xRadius: 2, yRadius: 2).fill()
            if showLabel {
                let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 6, weight: .semibold), .foregroundColor: NSColor.white]
                "RAM".draw(at: NSPoint(x: 0, y: 0), withAttributes: attrs)
                "RAM".draw(at: NSPoint(x: 14, y: 0), withAttributes: attrs)
            }
            return true
        }
        img.isTemplate = true
        return img
    }

    // GPU — single bar
    private func gpuBarImage() -> NSImage {
        let pct = CGFloat(monitor.gpuData.usagePercentage / 100.0)
        let w: CGFloat = 8; let h: CGFloat = 16
        let showLabel = UserDefaults.standard.object(forKey: "gpu_showLabel") as? Bool ?? true
        let labelH: CGFloat = showLabel ? 7 : 0
        let totalH = h + labelH + (showLabel ? 1 : 0)

        let img = NSImage(size: NSSize(width: w + 14, height: totalH), flipped: false) { _ in
            NSColor.white.withAlphaComponent(0.2).setFill()
            NSBezierPath(roundedRect: NSRect(x: 12, y: labelH, width: w, height: h), xRadius: 2, yRadius: 2).fill()
            NSColor.white.setFill()
            NSBezierPath(roundedRect: NSRect(x: 12, y: labelH, width: w, height: max(2, h * pct)), xRadius: 2, yRadius: 2).fill()
            if showLabel {
                let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 6, weight: .semibold), .foregroundColor: NSColor.white]
                "GPU".draw(at: NSPoint(x: 0, y: 0), withAttributes: attrs)
            }
            return true
        }
        img.isTemplate = true
        return img
    }

    // Network — stacked up/down text
    private func networkTextImage() -> NSImage {
        let upStr   = "↑\(monitor.networkData.uploadBytesPerSec.shortNetworkFormatted())"
        let downStr = "↓\(monitor.networkData.downloadBytesPerSec.shortNetworkFormatted())"
        let attrs9: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular), .foregroundColor: NSColor.white]
        let upSize   = (upStr as NSString).size(withAttributes: attrs9)
        let downSize = (downStr as NSString).size(withAttributes: attrs9)
        let totalW   = max(upSize.width, downSize.width) + 2
        let img = NSImage(size: NSSize(width: totalW, height: 18), flipped: false) { _ in
            (upStr   as NSString).draw(at: NSPoint(x: 0, y:  9), withAttributes: attrs9)
            (downStr as NSString).draw(at: NSPoint(x: 0, y:  0), withAttributes: attrs9)
            return true
        }
        img.isTemplate = true
        return img
    }

    // Disk — temperature text
    private func diskTextImage() -> NSImage {
        let str = "93.0°"  // placeholder
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular), .foregroundColor: NSColor.white]
        let sz = (str as NSString).size(withAttributes: attrs)
        let img = NSImage(size: NSSize(width: sz.width + 2, height: 16), flipped: false) { _ in
            (str as NSString).draw(at: NSPoint(x: 1, y: 0), withAttributes: attrs)
            return true
        }
        img.isTemplate = true
        return img
    }

    // Battery — text percentage
    private func batteryBarImage() -> NSImage {
        let pct  = Int(monitor.batteryData.percentage)
        let str  = "\(pct)%"
        let showPct = UserDefaults.standard.object(forKey: "battery_showPercentage") as? Bool ?? true
        let attrs: [NSAttributedString.Key: Any] = [
            .font:            NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.white
        ]
        let sz  = (str as NSString).size(withAttributes: attrs)
        let w   = showPct ? sz.width + 4 : 20
        let img = NSImage(size: NSSize(width: w, height: 16), flipped: false) { _ in
            if showPct {
                (str as NSString).draw(at: NSPoint(x: 2, y: 0), withAttributes: attrs)
            }
            return true
        }
        img.isTemplate = true
        return img
    }

    // MARK: - Settings
    func openSettings() { SettingsWindowController.shared.showAndActivate() }

    @objc func openSettingsProTab() {
        popovers.values.forEach { $0.performClose(nil) }
        SettingsWindowController.shared.showProTab()
    }

    // MARK: - Hot key
    func setupHotKey() {
        hotKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags    = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let savedKey = UserDefaults.standard.integer(forKey: "hotKeyCode")
            let savedMod = UserDefaults.standard.integer(forKey: "hotKeyMod")
            let keyCode  = savedKey == 0 ? 49 : savedKey
            let modMask  = savedMod == 0 ? NSEvent.ModifierFlags.option.rawValue : UInt(savedMod)
            if UInt16(event.keyCode) == UInt16(keyCode) && flags.rawValue == modMask {
                DispatchQueue.main.async {
                    // Toggle first visible module's popover
                    if let first = allModules.first, let button = self?.statusItems[first.id]?.button {
                        if let pop = self?.popovers[first.id] {
                            if pop.isShown { pop.performClose(nil) }
                            else { pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY) }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Custom popover VC with visual effect background
class ModulePopoverVC: NSViewController {
    private let rootView: AnyView

    init(rootView: AnyView) {
        self.rootView = rootView
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        let effect = NSVisualEffectView()
        effect.material = .menu
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 10

        let hosting = NSHostingView(rootView: rootView)
        hosting.autoresizingMask = [.width, .height]
        hosting.frame = effect.bounds
        effect.addSubview(hosting)
        self.view = effect
    }
}

// MARK: - StatusColorState (kept for compat)
enum StatusColorState { case normal, warning, critical }

extension NSColor {
    convenience init?(hex: String) {
        let h = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0; Scanner(string: h).scanHexInt64(&rgb)
        self.init(red:   CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >>  8) & 0xFF) / 255,
                  blue:  CGFloat( rgb        & 0xFF) / 255, alpha: 1)
    }
}

// MARK: - Short network formatter (no "B/s" suffix trailing)
extension Double {
    func shortNetworkFormatted() -> String {
        if self < 1_000         { return String(format: "%.0f B/s",  self) }
        if self < 1_000_000     { return String(format: "%.1f KB/s", self / 1_000) }
        if self < 1_000_000_000 { return String(format: "%.1f MB/s", self / 1_000_000) }
        return String(format: "%.1f GB/s", self / 1_000_000_000)
    }
}
