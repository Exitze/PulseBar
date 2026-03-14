# Changelog

All notable changes to PulseBar are documented here.  
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Versioning: [SemVer](https://semver.org/).

---

## [Unreleased]

---

## [1.0.0] — 2026-03-14

### Added

#### Core Monitoring
- CPU usage per-core heatmap + temperature (SMC multi-key: TC0P→TC0D→TC0E→Th0H→TA0P fallback for Apple Silicon)
- GPU usage, memory, temperature via IOKit
- RAM breakdown: used / wired / compressed / available
- Battery percentage, time remaining, charging state, health (max capacity, cycle count, temperature)
- All mounted disk volumes via FileManager (skip hidden volumes)
- Network upload/download speeds + ICMP-style latency check
- Fan speed monitoring with animated display
- Per-core CPU load heatmap visualization

#### Menu Bar
- Separate `NSStatusItem` per module (CPU, RAM, GPU, Network, Disk, Battery)
- Custom-drawn gradient bar-chart icons per module with colored gradients
- Per-module show/hide via `UserDefaults`
- Icon updates every N seconds (user-configurable, 1–60s)
- Colored gradient icons (toggleable)

#### Popup
- Click any module icon → frosted-glass `NSPopover` with detailed metrics
- Live sparklines (60-point rolling window) in each popup
- ArcIndicatorView: gradient arc with track + fill
- OdometerText: animated rolling number display
- `Settings…` link in each popover footer

#### Settings
- Native macOS `NavigationSplitView` settings window
- Per-module panels: CPU, RAM, GPU, Network, Disk, Battery
- Alert threshold sliders per metric
- "Quit PulseBar" button in sidebar footer

#### Pro — AI Analysis
- Claude API integration (`claude-sonnet-4-20250514`)
- API key stored in macOS Keychain (never UserDefaults)
- Anomaly detection: temp spike, sustained high CPU, rapid RAM growth
- `AIInsightView` with tap-to-analyze + loading spinner

#### Pro — Dashboard
- Fullscreen 1100×700 `DashboardWindowController`
- 3-column layout: system info + dual arcs, CPU/RAM charts, processes + disk
- `swift Charts` sparklines with gradient fill + area mark
- Kill process button on top process list

#### Pro — Benchmark
- Prime sieve + FP matrix + 50M element RAM allocation test
- Normalized 0–1000 score vs M1 baseline
- Percentile rating + verbal rating (Excellent / Good / Average / Below Average)
- Run-history (last 20 runs) persisted to `UserDefaults`

#### Pro — 30-Day History
- Daily summaries stored as JSON in `~/Library/Application Support/PulseBar/history/`
- Hourly flush + midnight rotation, 30-file cap with pruning
- `swift Charts` HistoryChart: CPU temp, RAM, CPU load with trend line
- Insights: hottest day / heaviest load day

#### Pro — Auto-Kill Rules
- `KillRule` codable struct: process name, CPU %, duration seconds
- `AutoKillService` monitors per-rule with 30s soak time
- SIGTERM on threshold breach + UNNotification
- Rule list with enable/disable toggle, delete, kill-count + last-triggered

#### Pro — iPhone Push
- Pushover API integration
- User Key + App Token stored in `UserDefaults` (configurable in Settings → Network)
- Integrated into Smart Alerts: fires on critical alerts

#### Pro — Apple Shortcuts
- `AppIntents` for macOS 13+
- Intents: GetCPUTemperature, GetCPULoad, GetRAMUsage, GetBatteryLevel, KillTopProcess
- `PulseBarShortcuts` AppShortcutsProvider with suggested phrases

#### Pro — Smart Alerts v2
- Per-metric 30-second soak time before firing
- 5-minute per-metric cooldown to prevent alert storms
- Severity levels: warning vs critical (based on threshold overage ratio)
- Culprit process attached to alerts (top CPU process at fire time)
- Alert log: last 100 alerts persisted to `UserDefaults`
- UNNotification + Pushover push on every alert

#### Pro — Custom Themes
- `ThemeService` singleton with `PulseBarTheme` codable struct
- 3 built-in themes: Default Dark, Neon, Monochrome
- Custom theme editor with macOS `ColorPicker`
- Theme persistence in `UserDefaults`

#### Pro — Multi-Monitor
- `SecondaryBarView` + `MetricPill` for secondary displays
- Configurable metric selection per secondary display

#### Pro — Popup Editor
- Drag-to-reorder popup cards
- Per-card visibility toggle
- Live preview panel
- Order persisted via `@AppStorage`

#### Infrastructure
- `HistoryStore` 30-day persistence with pruning
- `BenchmarkHistory` last-20 run log
- `KeychainHelper` generic get/set/delete for Keychain
- `WidgetKit` extension: small/medium/large widgets via App Group shared defaults
- `WeeklyReportService` — email-friendly weekly digest
- `FloatingWidgetController` — floating NSPanel overlay widget
- `AlertService.check()` wired into MonitorService timer loop
- `AutoKillService.checkRules()` wired into MonitorService timer loop
- `HistoryStore.record()` wired into MonitorService timer loop

---

[Unreleased]: https://github.com/USERNAME/PulseBar/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/USERNAME/PulseBar/releases/tag/v1.0.0
