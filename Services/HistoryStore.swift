import Foundation

// MARK: - Feature 4: 30-Day History Store
struct DailySummary: Codable {
    var date:               Date
    var avgCPUTemp:         Double
    var maxCPUTemp:         Double
    var avgCPULoad:         Double
    var maxCPULoad:         Double
    var avgRAMUsed:         Double
    var avgPingMs:          Double
    var totalUptime:        Double
    var batteryHealthAtDay: Double
}

class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    @Published var summaries: [DailySummary] = []

    private var storageDir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("PulseBar/history", isDirectory: true)
    }
    private let maxDays = 30
    private var hourlyBuffer: [MonitorTick] = []
    private var lastDayWritten: String = ""
    private var timer: Timer?

    struct MonitorTick {
        var cpuTemp: Double; var cpuLoad: Double; var ram: Double; var ping: Double
    }

    private init() {
        try? FileManager.default.createDirectory(at: storageDir, withIntermediateDirectories: true)
        loadAll()
        scheduleHourly()
    }

    // Called from MonitorService each tick
    func record(cpuTemp: Double, cpuLoad: Double, ram: Double, ping: Double) {
        hourlyBuffer.append(MonitorTick(cpuTemp: cpuTemp, cpuLoad: cpuLoad, ram: ram, ping: ping))
        checkMidnight()
    }

    private func scheduleHourly() {
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.flushHourly()
        }
    }

    private func flushHourly() {
        guard !hourlyBuffer.isEmpty else { return }
        let now = DailySummary(
            date:               Date(),
            avgCPUTemp:         hourlyBuffer.map(\.cpuTemp).avg,
            maxCPUTemp:         hourlyBuffer.map(\.cpuTemp).max() ?? 0,
            avgCPULoad:         hourlyBuffer.map(\.cpuLoad).avg,
            maxCPULoad:         hourlyBuffer.map(\.cpuLoad).max() ?? 0,
            avgRAMUsed:         hourlyBuffer.map(\.ram).avg,
            avgPingMs:          hourlyBuffer.map(\.ping).avg,
            totalUptime:        Double(hourlyBuffer.count) * 3.0,
            batteryHealthAtDay: MonitorService.shared.batteryHealthPercent
        )
        saveDay(now)
        hourlyBuffer.removeAll()
    }

    private func checkMidnight() {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let today = df.string(from: Date())
        if lastDayWritten != today && !lastDayWritten.isEmpty { flushHourly() }
        lastDayWritten = today
    }

    private func saveDay(_ summary: DailySummary) {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let filename = "\(df.string(from: summary.date)).json"
        let url = storageDir.appendingPathComponent(filename)
        if let data = try? JSONEncoder().encode(summary) { try? data.write(to: url) }
        pruneOldFiles()
        loadAll()
    }

    private func pruneOldFiles() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: storageDir, includingPropertiesForKeys: [.creationDateKey]) else { return }
        let sorted = files.sorted { $0.lastPathComponent > $1.lastPathComponent }
        if sorted.count > maxDays {
            sorted.dropFirst(maxDays).forEach { try? FileManager.default.removeItem(at: $0) }
        }
    }

    func loadAll() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: storageDir, includingPropertiesForKeys: nil) else { return }
        let loaded = files.compactMap { url -> DailySummary? in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(DailySummary.self, from: data)
        }.sorted { $0.date < $1.date }
        DispatchQueue.main.async { self.summaries = loaded }
    }
}

private extension Array where Element == Double {
    var avg: Double { isEmpty ? 0 : reduce(0, +) / Double(count) }
}
