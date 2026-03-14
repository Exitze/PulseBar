import Foundation
import Combine

// MARK: - Feature 3: Benchmark Service
class BenchmarkService: ObservableObject {
    static let shared = BenchmarkService()
    @Published var isRunning = false
    @Published var progress:  Double = 0
    @Published var result:    BenchmarkResult?

    private init() {}

    struct BenchmarkResult: Codable {
        var cpuScore:       Int
        var ramScore:       Int
        var cpuRating:      String
        var ramRating:      String
        var cpuPercentile:  Int
        var ramPercentile:  Int
        var durationSeconds: Double
        var timestamp:      Date
    }

    func runBenchmark() async {
        await MainActor.run { isRunning = true; progress = 0 }
        let cpuStart = Date()

        // CPU Test 1: prime sieve
        var primes = 0
        for n in 2..<500_000 {
            var isPrime = true
            if n > 2 { for i in 2..<(Int(Double(n).squareRoot())+1) { if n % i == 0 { isPrime = false; break } } }
            if isPrime { primes += 1 }
        }
        _ = primes
        await MainActor.run { self.progress = 0.33 }

        // CPU Test 2: FP matrix sim
        var sum = 0.0
        for i in 0..<1000 { for j in 0..<1000 { sum += sin(Double(i)) * cos(Double(j)) } }
        _ = sum
        await MainActor.run { self.progress = 0.66 }

        // RAM test: large alloc + sequential access
        let ramStart = Date()
        var bigArray = [Int](repeating: 0, count: 50_000_000)
        for i in stride(from: 0, to: bigArray.count, by: 64) { bigArray[i] = i }
        let ramTime = Date().timeIntervalSince(ramStart)
        let cpuTime = Date().timeIntervalSince(cpuStart) - ramTime
        bigArray.removeAll()
        await MainActor.run { self.progress = 1.0 }

        let baselineCPU = 8.5; let baselineRAM = 1.2
        let cpuScore = Int(min(1000, baselineCPU / max(cpuTime, 0.001) * 500))
        let ramScore = Int(min(1000, baselineRAM / max(ramTime, 0.001) * 500))

        func percentile(_ s: Int) -> Int {
            switch s { case 800...: return 98; case 700..<800: return 90; case 600..<700: return 75
            case 500..<600: return 60; case 400..<500: return 40; default: return 20 }
        }
        func rating(_ s: Int) -> String {
            s > 700 ? "Excellent" : s > 550 ? "Good" : s > 400 ? "Average" : "Below Average"
        }
        let r = BenchmarkResult(cpuScore: cpuScore, ramScore: ramScore,
            cpuRating: rating(cpuScore), ramRating: rating(ramScore),
            cpuPercentile: percentile(cpuScore), ramPercentile: percentile(ramScore),
            durationSeconds: Date().timeIntervalSince(cpuStart), timestamp: Date())

        await MainActor.run {
            self.result = r; self.isRunning = false
            var hist = BenchmarkHistory.load(); hist.append(r); BenchmarkHistory.save(hist)
        }
    }
}

struct BenchmarkHistory {
    static let key = "benchmarkHistory"
    static func load()  -> [BenchmarkService.BenchmarkResult] {
        guard let d = UserDefaults.standard.data(forKey: key),
              let a = try? JSONDecoder().decode([BenchmarkService.BenchmarkResult].self, from: d) else { return [] }
        return a
    }
    static func save(_ arr: [BenchmarkService.BenchmarkResult]) {
        if let d = try? JSONEncoder().encode(Array(arr.suffix(20))) {
            UserDefaults.standard.set(d, forKey: key)
        }
    }
}
