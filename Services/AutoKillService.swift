import Foundation
import UserNotifications
import Darwin

// MARK: - Feature 5: Auto-Kill Service
struct KillRule: Codable, Identifiable {
    let id:               UUID
    var processName:      String
    var cpuThreshold:     Double
    var durationSeconds:  Int
    var isEnabled:        Bool
    var killCount:        Int    = 0
    var lastTriggered:    Date?
}

class AutoKillService: ObservableObject {
    static let shared = AutoKillService()
    @Published var rules: [KillRule] = []
    private var processFirstSeen: [String: Date] = [:]

    private init() { loadRules() }

    func checkRules(processes: [ProcessData]) {
        for rule in rules where rule.isEnabled {
            if let proc = processes.first(where: { $0.name.localizedCaseInsensitiveContains(rule.processName) }),
               proc.cpuPercentage >= rule.cpuThreshold {
                if let firstSeen = processFirstSeen[rule.processName] {
                    if Date().timeIntervalSince(firstSeen) >= Double(rule.durationSeconds) {
                        killProcess(pid: proc.pid, rule: rule)
                    }
                } else {
                    processFirstSeen[rule.processName] = Date()
                }
            } else {
                processFirstSeen.removeValue(forKey: rule.processName)
            }
        }
    }

    private func killProcess(pid: Int32, rule: KillRule) {
        Darwin.kill(pid, SIGTERM)
        processFirstSeen.removeValue(forKey: rule.processName)
        if let idx = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[idx].killCount += 1; rules[idx].lastTriggered = Date()
        }
        saveRules()
        let c = UNMutableNotificationContent()
        c.title = "PulseBar: Process Killed"
        c.body  = "\(rule.processName) was using >\(Int(rule.cpuThreshold))% CPU for \(rule.durationSeconds)s"
        c.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil))
    }

    func saveRules() {
        if let d = try? JSONEncoder().encode(rules) { UserDefaults.standard.set(d, forKey: "autoKillRules") }
    }
    func loadRules() {
        guard let d = UserDefaults.standard.data(forKey: "autoKillRules"),
              let arr = try? JSONDecoder().decode([KillRule].self, from: d) else { return }
        rules = arr
    }
    func addRule(_ rule: KillRule) { rules.append(rule); saveRules() }
    func deleteRules(at offsets: IndexSet) { rules.remove(atOffsets: offsets); saveRules() }
}
