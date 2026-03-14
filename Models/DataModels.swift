import Foundation

struct CPUData {
    var usagePercentage: Double = 0.0
    var activeCoresText: String = "0 of 0 cores active"
    var temperature: Double = 0.0
    var history: [Double] = []
}

struct RAMData {
    var usedGB: Double = 0.0
    var totalGB: Double = 16.0
}

struct NetworkData {
    var interfaceName: String = "Wi-Fi"
    var uploadBytesPerSec: Double = 0.0
    var downloadBytesPerSec: Double = 0.0
    var uploadHistory: [Double] = []
    var downloadHistory: [Double] = []
}

struct BatteryData {
    var percentage: Double = 100.0
    var isCharging: Bool = false
    var timeRemainingString: String = "Calculating..."
}

struct DiskData {
    var usedGB: Double = 0.0
    var totalGB: Double = 1.0
}

struct DiskVolume: Identifiable {
    let id = UUID()
    var name: String
    var usedBytes: Int
    var totalBytes: Int
    var usagePercent: Double
    var isRemovable: Bool

    var usedGB: Double { Double(usedBytes) / 1_073_741_824 }
    var totalGB: Double { Double(totalBytes) / 1_073_741_824 }
    var displaySize: String {
        totalGB > 100 ? "\(Int(totalGB)) GB" : String(format: "%.0f GB", totalGB)
    }
}

struct GPUData {
    var usagePercentage: Double = 0.0
    var temperature: Double = 0.0
    var vramUsedGB: Double = 0.0
    var vramTotalGB: Double = 0.0
    var activeProcesses: [String] = []
}

struct ProcessData: Identifiable {
    let id = UUID()
    var pid: Int32
    var name: String
    var cpuPercentage: Double
    var ramBytes: UInt64
}

struct ThermalHistoryData {
    var timestamp: Date
    var cpuTemp: Double
    var gpuTemp: Double
    var cpuLoad: Double
}

struct SmartStatus {
    enum Level { case good, warning, critical }
    var level: Level
    var message: String
    var icon: String
}

// Feature 7 — HistoryPoint for CSV export
struct HistoryPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let cpuTemp: Double
    let gpuTemp: Double
    let cpuLoad: Double
    let ramUsed: Double
}

// Feature 10 — Fan speed
struct FanInfo: Identifiable {
    let id: Int
    var currentRPM: Int
    var maxRPM: Int
    var name: String
    var loadPercent: Double { Double(currentRPM) / Double(max(maxRPM, 1)) }
}
