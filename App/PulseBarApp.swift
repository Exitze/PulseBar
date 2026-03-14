import SwiftUI
import AppKit

@main
struct PulseBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // We use Settings to avoid opening a main window, keeping it a pure menu bar app.
        Settings {
            EmptyView()
        }
    }
}
