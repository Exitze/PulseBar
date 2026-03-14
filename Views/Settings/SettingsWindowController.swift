import Cocoa
import SwiftUI

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var monitorService: MonitorService?
    private var storeService:   StoreService?
    private var alertService:   AlertService?

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask:   [.titled, .closable, .miniaturizable],
            backing:     .buffered,
            defer:       false
        )
        window.title   = "Settings"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
        window.delegate = self
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(monitorService: MonitorService, storeService: StoreService, alertService: AlertService) {
        self.monitorService = monitorService
        self.storeService   = storeService
        self.alertService   = alertService

        let root = SettingsView()
            .environmentObject(monitorService)
            .environmentObject(storeService)
            .environmentObject(alertService)

        window?.contentView = NSHostingView(rootView: root)
        window?.setContentSize(NSSize(width: 640, height: 480))
    }

    func showAndActivate() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showProTab() {
        UserDefaults.standard.set("about", forKey: "settingsSelectedModule")
        showAndActivate()
    }

    func windowWillClose(_ notification: Notification) { }
}
