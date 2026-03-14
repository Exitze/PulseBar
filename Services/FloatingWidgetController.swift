import Foundation
import SwiftUI
import AppKit

class FloatingWidgetController {
    static let shared = FloatingWidgetController()
    private var window: NSWindow?

    private init() {}

    func show() {
        if window == nil { createWindow() }
        window?.orderFront(nil)
    }

    func hide() { window?.orderOut(nil) }

    func toggle() {
        if window?.isVisible == true { hide() } else { show() }
    }

    private func createWindow() {
        let w = NSWindow(
            contentRect: NSRect(x: 40, y: 40, width: 180, height: 240),
            styleMask: [.borderless, .resizable],
            backing: .buffered, defer: false
        )
        w.level = .floating
        w.backgroundColor = .clear
        w.isOpaque = false
        w.hasShadow = true
        w.isMovableByWindowBackground = true
        w.contentView = NSHostingView(rootView:
            FloatingWidgetView()
                .environmentObject(MonitorService.shared)
        )
        self.window = w
    }
}
