import SwiftUI

// MARK: - Feature 1: AI Insight View
struct AIInsightView: View {
    @EnvironmentObject var monitor: MonitorService
    @StateObject private var ai = AIAnalysisService.shared

    var body: some View {
        HStack(spacing: 10) {
            if ai.isAnalyzing {
                ProgressView().scaleEffect(0.7)
            } else {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                    .font(.system(size: 13))
            }
            Text(ai.currentInsight.isEmpty ? "Tap to analyze performance" : ai.currentInsight)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(3)
            Spacer()
        }
        .padding(10)
        .background(Color.purple.opacity(0.08))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple.opacity(0.2), lineWidth: 0.5))
        .onTapGesture {
            Task { await ai.analyze(metrics: monitor.currentSnapshot) }
        }
    }
}

// MARK: - Feature 2: Dashboard Window Controller
class DashboardWindowController: NSWindowController {
    static let shared = DashboardWindowController()

    private init() {
        let w = NSWindow(
            contentRect:  NSRect(x: 0, y: 0, width: 1100, height: 700),
            styleMask:    [.titled, .closable, .miniaturizable, .resizable],
            backing:      .buffered, defer: false)
        w.title           = "PulseBar Dashboard"
        w.minSize         = NSSize(width: 800, height: 500)
        w.center()
        w.isReleasedWhenClosed = false
        super.init(window: w)
        let root = DashboardView()
            .environmentObject(MonitorService.shared)
            .environmentObject(AIAnalysisService.shared)
        w.contentView = NSHostingView(rootView: root)
    }
    required init?(coder: NSCoder) { fatalError() }

    func show() { showWindow(nil); window?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
}
