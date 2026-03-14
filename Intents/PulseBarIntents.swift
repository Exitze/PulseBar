import AppIntents
import Foundation
import Darwin

// MARK: - Feature 7: Apple Shortcuts Intents

struct GetCPUTemperatureIntent: AppIntent {
    static var title: LocalizedStringResource = "Get CPU Temperature"
    static var description = IntentDescription("Returns current CPU temperature in °C")

    @MainActor
    func perform() async throws -> some ReturnsValue<Double> {
        .result(value: MonitorService.shared.cpuData.temperature)
    }
}

struct GetCPULoadIntent: AppIntent {
    static var title: LocalizedStringResource = "Get CPU Load"
    static var description = IntentDescription("Returns CPU usage percentage 0–100")

    @MainActor
    func perform() async throws -> some ReturnsValue<Double> {
        .result(value: MonitorService.shared.cpuData.usagePercentage)
    }
}

struct GetRAMUsageIntent: AppIntent {
    static var title: LocalizedStringResource = "Get RAM Usage"
    static var description = IntentDescription("Returns used RAM in GB")

    @MainActor
    func perform() async throws -> some ReturnsValue<Double> {
        .result(value: MonitorService.shared.ramData.usedGB)
    }
}

struct GetBatteryLevelIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Battery Level"
    static var description = IntentDescription("Returns battery percentage 0–100")

    @MainActor
    func perform() async throws -> some ReturnsValue<Double> {
        .result(value: MonitorService.shared.batteryData.percentage)
    }
}

struct KillTopProcessIntent: AppIntent {
    static var title: LocalizedStringResource = "Kill Top CPU Process"
    static var description = IntentDescription("Terminates the process using the most CPU")

    @MainActor
    func perform() async throws -> some ReturnsValue<String> {
        guard let top = MonitorService.shared.topCPUProcesses.first else {
            return .result(value: "No processes found")
        }
        Darwin.kill(top.pid, SIGTERM)
        return .result(value: "Killed \(top.name)")
    }
}

struct PulseBarShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: GetCPUTemperatureIntent(),
                    phrases: ["Get CPU temperature from \(.applicationName)"],
                    shortTitle: "CPU Temp", systemImageName: "thermometer")
        AppShortcut(intent: GetCPULoadIntent(),
                    phrases: ["Get CPU load from \(.applicationName)"],
                    shortTitle: "CPU Load", systemImageName: "cpu")
        AppShortcut(intent: GetRAMUsageIntent(),
                    phrases: ["Get RAM usage from \(.applicationName)"],
                    shortTitle: "RAM Usage", systemImageName: "memorychip")
        AppShortcut(intent: GetBatteryLevelIntent(),
                    phrases: ["Get battery level from \(.applicationName)"],
                    shortTitle: "Battery", systemImageName: "battery.75")
    }
}
