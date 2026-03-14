import SwiftUI
import UserNotifications

class WeeklyReportService {
    static let shared = WeeklyReportService()
    private let monitor: MonitorService

    private init() { self.monitor = MonitorService.shared }

    func scheduleWeeklyReport() {
        let cal = Calendar.current
        let now = Date()
        let lastSent = UserDefaults.standard.object(forKey: "lastWeeklyReport") as? Date
        guard cal.component(.weekday, from: now) == 1 else { return }
        if let last = lastSent, cal.isDate(last, equalTo: now, toGranularity: .weekOfYear) { return }
        sendWeeklyReport()
        UserDefaults.standard.set(now, forKey: "lastWeeklyReport")
    }

    func sendWeeklyReport() {
        let pts = monitor.historyPoints
        guard !pts.isEmpty else { return }
        let avgCPUTemp = pts.map(\.cpuTemp).reduce(0, +) / Double(pts.count)
        let maxCPUTemp = pts.map(\.cpuTemp).max() ?? 0
        let avgLoad    = pts.map(\.cpuLoad).reduce(0, +) / Double(pts.count)
        let health     = monitor.batteryHealthPercent
        let c = UNMutableNotificationContent()
        c.title    = "PulseBar Weekly Report"
        c.subtitle = "Week of \(weekString())"
        c.body     = """
            Avg CPU temp: \(Int(avgCPUTemp))°C · Peak: \(Int(maxCPUTemp))°C
            Avg CPU load: \(Int(avgLoad))%
            Battery health: \(Int(health))% · \(monitor.batteryCycleCount) cycles
            """
        c.sound = .default
        let req = UNNotificationRequest(identifier: "weeklyReport-\(Int(Date().timeIntervalSince1970))",
                                        content: c, trigger: nil)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    private func weekString() -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "MMM d"; return fmt.string(from: Date())
    }
}
