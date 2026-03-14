import Foundation
import UserNotifications
import Darwin

// MARK: - Feature 8: Smart Alert Service (replaces AlertService)
struct SmartAlert: Identifiable, Codable {
    let id: UUID
    var timestamp:       Date
    var title:           String
    var body:            String
    var culpritProcess:  String?
    var metric:          String
    var value:           Double
    var threshold:       Double
    var duration:        TimeInterval
    var severity:        AlertSeverity

    enum AlertSeverity: String, Codable { case warning, critical }
}

class AlertService: ObservableObject {
    static let shared = AlertService()
    @Published var recentAlerts: [SmartAlert] = []

    // Thresholds (user-configurable via @AppStorage)
    var cpuTempThreshold:  Double { UserDefaults.standard.double(forKey: "alert_cpuTemp")  > 0 ? UserDefaults.standard.double(forKey: "alert_cpuTemp")  : 80 }
    var cpuLoadThreshold:  Double { UserDefaults.standard.double(forKey: "alert_cpuLoad")  > 0 ? UserDefaults.standard.double(forKey: "alert_cpuLoad")  : 85 }
    var ramThreshold:      Double { UserDefaults.standard.double(forKey: "alert_ram")      > 0 ? UserDefaults.standard.double(forKey: "alert_ram")      : 90 }
    var batteryThreshold:  Double { UserDefaults.standard.double(forKey: "alert_battery")  > 0 ? UserDefaults.standard.double(forKey: "alert_battery")  : 15 }

    // Per-metric duration tracking
    private var metricFirstExceeded: [String: Date] = [:]
    private var metricCooldown:      [String: Date] = [:]
    private let cooldownSecs: TimeInterval = 300  // 5 min cooldown per metric

    init() { loadLog() }

    // MARK: - Check all metrics (called per timer tick)
    func check(monitor: MonitorService) {
        checkMetric("cpu_temp",  value: monitor.cpuData.temperature,   threshold: cpuTempThreshold,
                    monitor: monitor, criticalMult: 1.15)
        checkMetric("cpu_load",  value: monitor.cpuData.usagePercentage, threshold: cpuLoadThreshold,
                    monitor: monitor, criticalMult: 1.1)
        let ramPct = monitor.ramData.totalGB > 0 ? (monitor.ramData.usedGB / monitor.ramData.totalGB) * 100 : 0
        checkMetric("ram",       value: ramPct,                         threshold: ramThreshold,
                    monitor: monitor, criticalMult: 1.05)
        checkMetric("battery",   value: monitor.batteryData.percentage, threshold: batteryThreshold,
                    monitor: monitor, criticalMult: 0.5, lessThan: true)
    }

    private func checkMetric(_ key: String, value: Double, threshold: Double,
                              monitor: MonitorService, criticalMult: Double,
                              lessThan: Bool = false) {
        let exceeded = lessThan ? value <= threshold : value >= threshold
        guard exceeded else { metricFirstExceeded.removeValue(forKey: key); return }

        let firstSeen = metricFirstExceeded[key] ?? Date()
        metricFirstExceeded[key] = firstSeen
        let duration = Date().timeIntervalSince(firstSeen)
        guard duration >= 30 else { return }  // 30s minimum soak time

        // Cooldown check
        if let last = metricCooldown[key], Date().timeIntervalSince(last) < cooldownSecs { return }
        metricCooldown[key] = Date()

        let topProc = monitor.topCPUProcesses.first
        let severity: SmartAlert.AlertSeverity = {
            let ratio = lessThan ? threshold / max(value, 0.1) : value / threshold
            return ratio >= criticalMult ? .critical : .warning
        }()

        let durationStr = duration >= 60 ? "\(Int(duration/60))m \(Int(duration.truncatingRemainder(dividingBy:60)))s" : "\(Int(duration))s"
        let trend = value > threshold * 1.05 ? "and still rising" : "seems stable"
        let procStr = topProc != nil ? " \(topProc!.name) is using \(Int(topProc!.cpuPercentage))% CPU." : ""

        let alert = SmartAlert(
            id: UUID(), timestamp: Date(),
            title: alertTitle(for: key, value: value, severity: severity),
            body:  "\(metricLabel(key)) at \(formattedValue(key, value)) for \(durationStr), \(trend).\(procStr)",
            culpritProcess: topProc?.name,
            metric: key, value: value, threshold: threshold,
            duration: duration, severity: severity
        )
        fire(alert: alert)
    }

    private func fire(alert: SmartAlert) {
        DispatchQueue.main.async {
            self.recentAlerts.insert(alert, at: 0)
            if self.recentAlerts.count > 100 { self.recentAlerts = Array(self.recentAlerts.prefix(100)) }
            self.saveLog()
        }
        let c = UNMutableNotificationContent()
        c.title = alert.title; c.body = alert.body
        c.sound = alert.severity == .critical ? .defaultCritical : .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: alert.id.uuidString, content: c, trigger: nil))

        // Push notification (Feature 6)
        Task { await PushNotificationService.shared.send(
            title: "⚠️ PulseBar: \(alert.title)",
            message: alert.body,
            priority: alert.severity == .critical ? 1 : 0) }
    }

    private func alertTitle(for key: String, value: Double, severity: SmartAlert.AlertSeverity) -> String {
        let prefix = severity == .critical ? "🔴" : "🟡"
        switch key {
        case "cpu_temp":  return "\(prefix) CPU Temp \(Int(value))°C"
        case "cpu_load":  return "\(prefix) CPU Load \(Int(value))%"
        case "ram":       return "\(prefix) RAM Usage \(Int(value))%"
        case "battery":   return "\(prefix) Low Battery \(Int(value))%"
        default:          return "\(prefix) Alert"
        }
    }
    private func metricLabel(_ key: String) -> String {
        ["cpu_temp":"CPU temperature","cpu_load":"CPU load","ram":"RAM","battery":"Battery"][key] ?? key
    }
    private func formattedValue(_ key: String, _ v: Double) -> String {
        key == "cpu_temp" ? "\(Int(v))°C" : "\(Int(v))%"
    }

    // MARK: - Persistence
    private func saveLog() {
        if let data = try? JSONEncoder().encode(recentAlerts) {
            UserDefaults.standard.set(data, forKey: "alertLog")
        }
    }
    private func loadLog() {
        guard let data = UserDefaults.standard.data(forKey: "alertLog"),
              let arr = try? JSONDecoder().decode([SmartAlert].self, from: data) else { return }
        recentAlerts = arr
    }

    func clearLog() { recentAlerts = []; UserDefaults.standard.removeObject(forKey: "alertLog") }
}
