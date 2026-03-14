import Foundation
import Combine
import IOKit
import IOKit.ps
import Darwin
import AppKit
import SwiftUI

// MARK: - Connection quality (Feature 9)
enum ConnectionQuality: String {
    case excellent = "Excellent"
    case good      = "Good"
    case fair      = "Fair"
    case poor      = "Poor"
    case offline   = "Offline"
    case unknown   = "—"

    var color: Color {
        switch self {
        case .excellent, .good: return .accentGreen
        case .fair:             return .accentOrange
        case .poor, .offline:   return .accentRed
        default:                return Color(hex8: "#8E8E93")
        }
    }
    var icon: String {
        switch self {
        case .excellent, .good: return "wifi"
        case .fair:             return "wifi.exclamationmark"
        case .poor, .offline:   return "wifi.slash"
        default:                return "wifi"
        }
    }
}

// MARK: - Circular buffer helper
struct CircularBuffer<T> {
    private var buffer: [T] = []
    private var head = 0
    var capacity: Int
    var count: Int = 0

    init(capacity: Int) { self.capacity = capacity }

    mutating func append(_ value: T) {
        if buffer.count < capacity { buffer.append(value) }
        else { buffer[head] = value }
        head = (head + 1) % capacity
        count = min(count + 1, capacity)
    }

    var all: [T] {
        if buffer.count < capacity { return buffer }
        return Array(buffer[head...]) + Array(buffer[..<head])
    }
}

class MonitorService: ObservableObject {
    // MARK: Singleton
    static let shared = MonitorService()

    // MARK: - Published — core
    @Published var cpuData         = CPUData()
    @Published var ramData         = RAMData()
    @Published var networkData     = NetworkData()
    @Published var batteryData     = BatteryData()
    @Published var diskData        = DiskData()
    @Published var diskVolumes:    [DiskVolume] = []
    @Published var gpuData         = GPUData()
    @Published var topCPUProcesses: [ProcessData] = []
    @Published var topRAMProcesses: [ProcessData] = []
    @Published var thermalHistory: [ThermalHistoryData] = []
    @Published var lastUpdated:    Date = Date()

    // MARK: - Published — sparkline histories
    @Published var cpuTempHistory:   [Double] = []
    @Published var cpuLoadHistory:   [Double] = []
    @Published var ramHistory:       [Double] = []
    @Published var networkUpHistory: [Double] = []
    @Published var networkDnHistory: [Double] = []

    // MARK: - Published — per-core
    @Published var coreUsages: [Double] = []

    // MARK: - Published — Feature 7 CSV
    @Published var historyPoints: [HistoryPoint] = []
    private let maxHistory = 86400

    // MARK: - Published — Feature 8 Battery Health
    @Published var batteryMaxCapacity:    Int    = 0
    @Published var batteryDesignCapacity: Int    = 0
    @Published var batteryCycleCount:     Int    = 0
    @Published var batteryHealthPercent:  Double = 100.0
    @Published var batteryTemp:           Double = 0.0

    // MARK: - Published — Feature 9 Ping
    @Published var pingMs:             Double            = 0
    @Published var connectionQuality:  ConnectionQuality = .unknown

    // MARK: - Published — Feature 10 Fans
    @Published var fanSpeeds: [FanInfo] = []

    // MARK: - Anomaly tracking
    private var prevCPUTempForSpike: Double = 0
    private var prevCPUTempSpikeTime: Date = Date()
    private var highCPUProcStart: [String: Date] = [:]
    private var prevRAMForGrowth: Double = 0
    private var prevRAMGrowthTime: Date = Date()
    @Published var currentAnomalies: [String] = []

    // MARK: - currentSnapshot for AI analysis
    var currentSnapshot: HistorySnapshot {
        let topProc = topCPUProcesses.first
        return HistorySnapshot(
            avgCPUTemp:    cpuTempHistory.isEmpty ? 0 : cpuTempHistory.reduce(0,+)/Double(cpuTempHistory.count),
            peakCPUTemp:   cpuTempHistory.max() ?? 0,
            avgCPULoad:    cpuLoadHistory.isEmpty ? 0 : cpuLoadHistory.reduce(0,+)/Double(cpuLoadHistory.count),
            peakCPULoad:   cpuLoadHistory.max() ?? 0,
            avgRAM:        ramHistory.isEmpty ? 0 : ramHistory.reduce(0,+)/Double(ramHistory.count),
            topProcess:    topProc?.name ?? "—",
            topProcessCPU: topProc?.cpuPercentage ?? 0,
            anomalies:     currentAnomalies
        )
    }

    // MARK: Callback for status bar icon
    var statusItemUpdateCallback: ((StatusColorState) -> Void)?

    // MARK: - Private network state
    private var prevNetBytes: (up: UInt64, down: UInt64) = (0, 0)

    // MARK: - CPU tick state
    private var prevCPUInfo: processor_info_array_t? = nil

    // MARK: - Combine timers
    private var cancellables = Set<AnyCancellable>()
    private(set) var currentInterval: TimeInterval = 3.0

    // MARK: - Battery health timer
    private var battHealthTimer: Timer?

    // MARK: - SMC connection cache
    private var smcConn: io_connect_t = IO_OBJECT_NULL

    // MARK: - Start / Stop
    func startMonitoring() {
        openSMC()

        Timer.publish(every: currentInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.collectAll() }
            .store(in: &cancellables)

        // Slower battery health timer
        battHealthTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateBatteryHealth()
        }
        battHealthTimer?.fire()

        // Ping timer
        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.updatePing() }
            .store(in: &cancellables)

        collectAll()
    }

    func stopMonitoring()  { cancellables.removeAll(); battHealthTimer?.invalidate() }

    func restartMonitoring(interval newInterval: TimeInterval) {
        currentInterval = newInterval
        cancellables.removeAll()
        startMonitoring()
    }

    // MARK: - Smart Status
    var smartStatus: SmartStatus {
        let cpuTemp  = cpuData.temperature
        let gpuTemp  = gpuData.temperature
        let cpuUsage = cpuData.usagePercentage
        let ramPct   = ramData.totalGB > 0 ? ramData.usedGB / ramData.totalGB : 0

        if cpuTemp > 85 || gpuTemp > 90 {
            return SmartStatus(level: .critical, message: "Overheating detected",   icon: "thermometer.high")
        }
        if cpuUsage > 80 {
            return SmartStatus(level: .warning, message: "High CPU load",            icon: "cpu")
        }
        if let top = topCPUProcesses.first, top.cpuPercentage > 60 {
            return SmartStatus(level: .warning, message: "\(top.name) is using CPU", icon: "exclamationmark.circle")
        }
        if ramPct > 0.85 {
            return SmartStatus(level: .warning, message: "Low memory available",    icon: "memorychip")
        }
        return SmartStatus(level: .good, message: "Everything looks good",          icon: "checkmark.circle.fill")
    }

    // MARK: - Collect all metrics
    private func collectAll() {
        let cpuTemp  = readCPUTemperature()
        let cpuLoad  = readCPULoad()
        let cores    = readCoreUsages()
        let ram      = readRAM()
        let net      = readNetwork()
        let batt     = readBattery()
        let disk     = readDiskLegacy()
        let gpu      = readGPU()
        let (topCPU, topRAM) = readTopProcesses()
        let volumes  = readDiskVolumes()

        updateFans()

        let colorState: StatusColorState
        if cpuTemp > 80 || cpuLoad > 80      { colorState = .critical }
        else if cpuTemp > 60 || cpuLoad > 50 { colorState = .warning  }
        else                                  { colorState = .normal   }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            var cd = CPUData()
            cd.temperature     = cpuTemp
            cd.usagePercentage = cpuLoad
            cd.activeCoresText = self.buildCoresText(load: cpuLoad)
            cd.history         = Array(self.cpuTempHistory.suffix(60))
            self.cpuData       = cd

            self.ramData = ram

            var nd = net
            nd.uploadHistory   = Array(self.networkUpHistory.suffix(30))
            nd.downloadHistory = Array(self.networkDnHistory.suffix(30))
            self.networkData   = nd

            self.batteryData   = batt
            self.diskData      = disk
            self.diskVolumes   = volumes
            self.gpuData       = gpu
            self.coreUsages    = cores
            self.topCPUProcesses = topCPU
            self.topRAMProcesses = topRAM

            // Sparkline history
            self.appendHistory(cpuTemp,                 to: &self.cpuTempHistory)
            self.appendHistory(cpuLoad,                 to: &self.cpuLoadHistory)
            let ramPct = ram.totalGB > 0 ? (ram.usedGB / ram.totalGB) * 100 : 0
            self.appendHistory(ramPct,                  to: &self.ramHistory)
            self.appendHistory(net.uploadBytesPerSec,   to: &self.networkUpHistory)
            self.appendHistory(net.downloadBytesPerSec, to: &self.networkDnHistory)

            // Thermal history
            let record = ThermalHistoryData(
                timestamp: Date(), cpuTemp: cpuTemp, gpuTemp: gpu.temperature, cpuLoad: cpuLoad)
            self.thermalHistory.append(record)
            if self.thermalHistory.count > 28800 { self.thermalHistory.removeFirst() }

            // Feature 7: HistoryPoint for CSV
            let pt = HistoryPoint(timestamp: Date(), cpuTemp: cpuTemp, gpuTemp: gpu.temperature,
                                  cpuLoad: cpuLoad, ramUsed: ram.usedGB)
            self.historyPoints.append(pt)
            if self.historyPoints.count > self.maxHistory { self.historyPoints.removeFirst() }

            self.lastUpdated = Date()
            self.statusItemUpdateCallback?(colorState)
            self.writeWidgetMetrics()

            // Anomaly detection
            self.detectAnomalies()

            // Smart alerts
            AlertService.shared.check(monitor: self)

            // History recording
            HistoryStore.shared.record(
                cpuTemp: self.cpuData.temperature,
                cpuLoad: self.cpuData.usagePercentage,
                ram: self.ramData.usedGB,
                ping: self.pingMs
            )

            // Auto-kill rules
            AutoKillService.shared.checkRules(processes: self.topCPUProcesses)
        }
    }

    private func appendHistory(_ value: Double, to arr: inout [Double], max: Int = 60) {
        arr.append(value)
        if arr.count > max { arr.removeFirst() }
    }

    // MARK: - Feature 7: CSV Export
    func exportCSV() -> URL? {
        var csv = "Timestamp,CPU Temp (°C),GPU Temp (°C),CPU Load (%),RAM Used (GB)\n"
        let fmt = ISO8601DateFormatter()
        for p in historyPoints {
            csv += "\(fmt.string(from: p.timestamp)),\(p.cpuTemp),\(p.gpuTemp),\(p.cpuLoad),\(p.ramUsed)\n"
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PulseBar_Export_\(Int(Date().timeIntervalSince1970)).csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Feature 8: Battery Health
    func updateBatteryHealth() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault,
                      IOServiceMatching("AppleSmartBattery"))
        guard service != IO_OBJECT_NULL else { return }
        defer { IOObjectRelease(service) }

        func intVal(_ key: String) -> Int {
            (IORegistryEntryCreateCFProperty(service, key as CFString,
                kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int) ?? 0
        }
        let maxCap    = intVal("MaxCapacity")
        let designCap = intVal("DesignCapacity")
        let cycles    = intVal("CycleCount")
        let rawTemp   = intVal("Temperature")
        let health    = designCap > 0 ? Double(maxCap) / Double(designCap) * 100 : 0.0
        let tempC     = Double(rawTemp) / 100.0

        DispatchQueue.main.async {
            self.batteryMaxCapacity    = maxCap
            self.batteryDesignCapacity = designCap
            self.batteryCycleCount     = cycles
            self.batteryHealthPercent  = health
            self.batteryTemp           = tempC
        }
    }

    // MARK: - Feature 9: Ping
    func updatePing() {
        Task {
            let start = Date()
            let url   = URL(string: "https://captive.apple.com")!
            var req   = URLRequest(url: url, timeoutInterval: 3)
            req.httpMethod = "HEAD"
            let result = try? await URLSession.shared.data(for: req)
            let ms = Date().timeIntervalSince(start) * 1000
            await MainActor.run {
                self.pingMs = result != nil ? ms : -1
                self.connectionQuality = {
                    guard result != nil else { return .offline }
                    switch ms {
                    case ..<30:   return .excellent
                    case 30..<80: return .good
                    case 80..<200: return .fair
                    default:      return .poor
                    }
                }()
            }
        }
    }

    // MARK: - Feature 10: Fans via SMC
    func updateFans() {
        var fans: [FanInfo] = []
        for i in 0..<4 {
            let keyAc = "F\(i)Ac"
            let keyMx = "F\(i)Mx"
            guard smcConn != IO_OBJECT_NULL else { break }
            guard let current = readSMCFloatVal(key: keyAc), current > 0 else { break }
            let maxRPM = readSMCFloatVal(key: keyMx) ?? 0
            fans.append(FanInfo(id: i, currentRPM: Int(current), maxRPM: Int(maxRPM), name: "Fan \(i + 1)"))
        }
        DispatchQueue.main.async { self.fanSpeeds = fans }
    }

    // MARK: - SMC helpers
    private func openSMC() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != IO_OBJECT_NULL else { return }
        IOServiceOpen(service, mach_task_self_, 0, &smcConn)
        IOObjectRelease(service)
    }

    private func readCPUTemperature() -> Double {
        guard smcConn != IO_OBJECT_NULL else {
            // FIXED: No SMC connection — return load-based estimate as graceful fallback
            return 35.0 + cpuData.usagePercentage * 0.5
        }
        // FIXED: Try multiple SMC keys — Apple Silicon uses different keys than Intel
        // Order: Intel Tdie → Intel die → Apple Silicon Th → ambient → wireless
        let tempKeys = ["TC0P", "TC0D", "TC0E", "TC0F", "Th0H", "TA0P", "TW0P", "TCXC"]
        for key in tempKeys {
            let t = smcReadKey(conn: smcConn, key: key)
            if t > 20 && t < 120 { return t }   // sanity-check: valid temp range
        }
        // Last resort: load-based estimate
        return 35.0 + cpuData.usagePercentage * 0.5
    }

    private func readSMCFloatVal(key: String) -> Double? {
        guard smcConn != IO_OBJECT_NULL else { return nil }
        let v = smcReadKey(conn: smcConn, key: key)
        return v > 0 ? v : nil
    }

    private func smcReadKey(conn: io_connect_t, key: String) -> Double {
        typealias SMCBytes = (
            UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
            UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
            UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
            UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8)
        struct SMCKeyData_t {
            var key: UInt32 = 0
            var vers: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0,0,0,0,0,0)
            var pLimitData: (UInt16, UInt8) = (0,0)
            var keyInfo: (UInt32, UInt8, UInt8, UInt8, UInt8, UInt8) = (0,0,0,0,0,0)
            var result: UInt8 = 0; var status: UInt8 = 0
            var data8: UInt8 = 0;  var data32: UInt32 = 0
            var bytes: SMCBytes =
                (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
        }
        func toU32(_ k: String) -> UInt32 {
            var r: UInt32 = 0; for c in k.utf8 { r = r << 8 | UInt32(c) }; return r
        }
        var inp = SMCKeyData_t(); var out = SMCKeyData_t()
        inp.key = toU32(key); inp.data8 = 5
        let sz  = MemoryLayout<SMCKeyData_t>.size
        var outSz = sz
        var kr  = IOConnectCallStructMethod(conn, 2, &inp, sz, &out, &outSz)
        guard kr == KERN_SUCCESS else { return -1 }
        inp.keyInfo.1 = out.keyInfo.1; inp.data8 = 5
        kr = IOConnectCallStructMethod(conn, 5, &inp, sz, &out, &outSz)
        guard kr == KERN_SUCCESS else { return -1 }
        return Double(out.bytes.0) + Double(out.bytes.1) / 256.0
    }

    // MARK: - CPU Load
    private func readCPULoad() -> Double {
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCPUsU: natural_t = 0
        let kr = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO,
                                     &numCPUsU, &cpuInfo, &numCpuInfo)
        guard kr == KERN_SUCCESS, let info = cpuInfo else { return 0 }
        var totalUsed: Double = 0; var totalAll: Double = 0
        for i in 0..<Int(numCPUsU) {
            let base = Int(CPU_STATE_MAX) * i
            let u  = Double(info[base + Int(CPU_STATE_USER)])
            let s  = Double(info[base + Int(CPU_STATE_SYSTEM)])
            let id = Double(info[base + Int(CPU_STATE_IDLE)])
            let n  = Double(info[base + Int(CPU_STATE_NICE)])
            let used = u + s + n; let total = used + id
            totalUsed += used; totalAll += total
        }
        prevCPUInfo = cpuInfo
        return totalAll > 0 ? (totalUsed / totalAll) * 100.0 : 0
    }

    private func readCoreUsages() -> [Double] {
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCPUsU: natural_t = 0
        let kr = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO,
                                     &numCPUsU, &cpuInfo, &numCpuInfo)
        guard kr == KERN_SUCCESS, let info = cpuInfo else { return [] }
        return (0..<Int(numCPUsU)).map { i in
            let base = Int(CPU_STATE_MAX) * i
            let u  = Double(info[base + Int(CPU_STATE_USER)])
            let s  = Double(info[base + Int(CPU_STATE_SYSTEM)])
            let id = Double(info[base + Int(CPU_STATE_IDLE)])
            let n  = Double(info[base + Int(CPU_STATE_NICE)])
            let used = u + s + n; let total = used + id
            return total > 0 ? used / total : 0
        }
    }

    private func buildCoresText(load: Double) -> String {
        let count  = ProcessInfo.processInfo.processorCount
        let active = max(1, Int(load / 100.0 * Double(count)))
        return "\(active) of \(count) cores active"
    }

    // MARK: - RAM
    private func readRAM() -> RAMData {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return RAMData() }
        let pageSize   = UInt64(vm_kernel_page_size)
        let used       = (UInt64(stats.active_count) + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)) * pageSize
        var data = RAMData()
        data.usedGB  = Double(used) / 1_073_741_824.0
        data.totalGB = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824.0
        return data
    }

    // MARK: - Network
    private func readNetwork() -> NetworkData {
        var upBytes: UInt64 = 0; var downBytes: UInt64 = 0; var ifName = "Wi-Fi"
        var ifap: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifap) == 0, let first = ifap else { return NetworkData() }
        defer { freeifaddrs(first) }
        var ptr = first
        while true {
            let ifa = ptr.pointee
            if ifa.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                let name = String(cString: ifa.ifa_name)
                if name.hasPrefix("en") || name.hasPrefix("eth") {
                    ifa.ifa_data.withMemoryRebound(to: if_data.self, capacity: 1) { d in
                        upBytes   += UInt64(d.pointee.ifi_obytes)
                        downBytes += UInt64(d.pointee.ifi_ibytes)
                        if name == "en0" { ifName = "Wi-Fi" } else { ifName = "Ethernet" }
                    }
                }
            }
            if let next = ifa.ifa_next { ptr = next } else { break }
        }
        let interval = currentInterval
        let upSpeed   = upBytes   > prevNetBytes.up   ? Double(upBytes   - prevNetBytes.up)   / interval : 0
        let downSpeed = downBytes > prevNetBytes.down ? Double(downBytes - prevNetBytes.down) / interval : 0
        prevNetBytes  = (upBytes, downBytes)
        var data = NetworkData()
        data.interfaceName       = ifName
        data.uploadBytesPerSec   = upSpeed
        data.downloadBytesPerSec = downSpeed
        return data
    }

    // MARK: - Battery
    private func readBattery() -> BatteryData {
        var data = BatteryData()
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources  = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else { return data }
        for src in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, src)?.takeUnretainedValue() as? [String: Any] else { continue }
            if let current = desc[kIOPSCurrentCapacityKey] as? Int,
               let max     = desc[kIOPSMaxCapacityKey]     as? Int, max > 0 {
                data.percentage = Double(current) / Double(max) * 100.0
            }
            data.isCharging = (desc[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
            if let rem = desc[kIOPSTimeToEmptyKey] as? Int, rem > 0 {
                data.timeRemainingString = "\(rem / 60)h \(rem % 60)m"
            } else {
                data.timeRemainingString = data.isCharging ? "Charging" : "Calculating…"
            }
        }
        return data
    }

    // MARK: - Disk
    private func readDiskLegacy() -> DiskData {
        var data = DiskData()
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
           let total = attrs[.systemSize] as? Int64, let free = attrs[.systemFreeSize] as? Int64 {
            data.totalGB = Double(total)        / 1_073_741_824.0
            data.usedGB  = Double(total - free) / 1_073_741_824.0
        }
        return data
    }

    private func readDiskVolumes() -> [DiskVolume] {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey, .volumeIsRemovableKey]
        guard let mounts = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes])
        else { return [] }
        return mounts.compactMap { url -> DiskVolume? in
            guard let vals  = try? url.resourceValues(forKeys: Set(keys)),
                  let total = vals.volumeTotalCapacity,
                  let avail = vals.volumeAvailableCapacity,
                  let name  = vals.volumeName, total > 0 else { return nil }
            let used = total - avail
            return DiskVolume(name: name, usedBytes: used, totalBytes: total,
                              usagePercent: Double(used) / Double(total),
                              isRemovable: vals.volumeIsRemovable ?? false)
        }
    }

    // MARK: - GPU
    private func readGPU() -> GPUData {
        var data = GPUData()
        let matchingDict = IOServiceMatching("IOGPU")
        var iter: io_iterator_t = IO_OBJECT_NULL
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iter) == KERN_SUCCESS else { return data }
        defer { IOObjectRelease(iter) }
        var service = IOIteratorNext(iter)
        while service != IO_OBJECT_NULL {
            defer { IOObjectRelease(service) }
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = props?.takeRetainedValue() as? [String: Any],
               let perf = dict["PerformanceStatistics"] as? [String: Any] {
                if let u = perf["Device Utilization %"] as? Double { data.usagePercentage = u }
                else if let u = perf["Tiler Utilization %"] as? Double { data.usagePercentage = u }
            }
            service = IOIteratorNext(iter)
        }
        if smcConn != IO_OBJECT_NULL {
            let t = smcReadKey(conn: smcConn, key: "TGOP")
            if t > 0 { data.temperature = t }
        }
        return data
    }

    // MARK: - Top Processes
    private func readTopProcesses() -> ([ProcessData], [ProcessData]) {
        let pidCount = proc_listallpids(nil, 0)
        guard pidCount > 0 else { return ([], []) }
        var pids = [Int32](repeating: 0, count: Int(pidCount) + 10)
        let actual = proc_listallpids(&pids, Int32(pids.count * 4))
        guard actual > 0 else { return ([], []) }
        var processes: [ProcessData] = []
        for i in 0..<Int(actual) {
            let pid = pids[i]; guard pid > 0 else { continue }
            var info = proc_taskinfo()
            guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(MemoryLayout<proc_taskinfo>.size))
                    == Int32(MemoryLayout<proc_taskinfo>.size) else { continue }
            var buf = [CChar](repeating: 0, count: 512)
            proc_name(pid, &buf, 512)
            let name = String(cString: buf).isEmpty ? "Unknown" : String(cString: buf)
            let cpu  = Double(info.pti_total_user + info.pti_total_system) / 1_000_000_000.0
            processes.append(ProcessData(pid: pid, name: name, cpuPercentage: cpu, ramBytes: UInt64(info.pti_resident_size)))
        }
        let topCPU = Array(processes.sorted { $0.cpuPercentage > $1.cpuPercentage }.prefix(5))
        let topRAM = Array(processes.sorted { $0.ramBytes      > $1.ramBytes      }.prefix(5))
        let maxCPU = topCPU.first?.cpuPercentage ?? 1.0
        let normCPU = topCPU.map { p -> ProcessData in
            var d = p; d.cpuPercentage = maxCPU > 0 ? min(p.cpuPercentage / maxCPU * 100.0, 100.0) : 0; return d
        }
        return (normCPU, topRAM)
    }

    // MARK: - Widget App Group sync
    func writeWidgetMetrics() {
        guard let defaults = UserDefaults(suiteName: "group.com.danyaczhan.pulsebar") else { return }
        let metrics = WidgetMetrics(
            cpuTemp:         cpuData.temperature,
            cpuUsage:        cpuData.usagePercentage,
            ramUsedGB:       ramData.usedGB,
            ramTotalGB:      ramData.totalGB,
            batteryLevel:    Int(batteryData.percentage),
            batteryCharging: batteryData.isCharging,
            networkUp:       networkData.uploadBytesPerSec.networkFormatted(),
            pingMs:          pingMs,
            updatedAt:       Date()
        )
        if let data = try? JSONEncoder().encode(metrics) {
            defaults.set(data, forKey: "widgetMetrics")
        }
    }

    // MARK: - Anomaly Detection
    func detectAnomalies() {
        var anomalies: [String] = []
        let now = Date()

        // 1. CPU temp spike > 15°C in 30s
        let tempDelta = cpuData.temperature - prevCPUTempForSpike
        if Date().timeIntervalSince(prevCPUTempSpikeTime) >= 30 {
            if tempDelta > 15 { anomalies.append("sudden temp spike") }
            prevCPUTempForSpike = cpuData.temperature
            prevCPUTempSpikeTime = now
        }

        // 2. Process using > 80% CPU for > 2min
        for proc in topCPUProcesses where proc.cpuPercentage >= 80 {
            if let first = highCPUProcStart[proc.name] {
                if now.timeIntervalSince(first) >= 120 {
                    anomalies.append("sustained high CPU: \(proc.name)")
                }
            } else {
                highCPUProcStart[proc.name] = now
            }
        }
        let highNames = Set(topCPUProcesses.filter { $0.cpuPercentage >= 80 }.map(\.name))
        highCPUProcStart = highCPUProcStart.filter { highNames.contains($0.key) }

        // 3. RAM grew > 2 GB in 5 min
        if now.timeIntervalSince(prevRAMGrowthTime) >= 300 {
            if ramData.usedGB - prevRAMForGrowth > 2 { anomalies.append("rapid memory growth") }
            prevRAMForGrowth = ramData.usedGB
            prevRAMGrowthTime = now
        }

        currentAnomalies = anomalies
    }
}


// MARK: - WidgetMetrics (shared with widget extension via App Group)
struct WidgetMetrics: Codable {
    var cpuTemp:         Double = 0
    var cpuUsage:        Double = 0
    var ramUsedGB:       Double = 0
    var ramTotalGB:      Double = 16
    var batteryLevel:    Int    = 0
    var batteryCharging: Bool   = false
    var networkUp:       String = "0 KB/s"
    var pingMs:          Double = 0
    var updatedAt:       Date   = Date()
}

