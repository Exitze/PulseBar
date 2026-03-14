# PulseBar Architecture

## Overview

PulseBar uses **MVVM + Service Layer** architecture with a clean separation:

```
App Layer       →  Entry point, NSApplication setup, status item wiring
Service Layer   →  Business logic, data collection, persistence
Feature Layer   →  SwiftUI views organized by feature/module
Shared Layer    →  Design system, reusable components
Widget Target   →  WidgetKit extension (separate target)
```

---

## Directory Structure

```
PulseBar/
├── App/            Entry point (PulseBarApp.swift, AppDelegate.swift)
├── Services/       All business logic singletons
├── Models/         Data model structs
├── Views/          SwiftUI views organized by feature
│   ├── Free/       Core feature views (cards, indicators)
│   ├── Pro/        Pro feature views
│   └── Settings/   Settings window + per-module panels
├── Helpers/        KeychainHelper, Extensions
├── Intents/        AppIntents for Shortcuts
└── Resources/      Assets, plist, storekit, entitlements

PulseBarWidget/     Separate WidgetKit target
```

---

## Service Layer

Each service is an `ObservableObject` singleton, initialized at app launch.

### MonitorService
**File**: `Services/MonitorService.swift`

The heart of the app. Collects all hardware metrics on a timer.

```
Timer (every N seconds)
  └── collectAll()
        ├── readCPU()         → IOKit + host_processor_info
        ├── readRAM()         → host_statistics64
        ├── readGPU()         → IOService GPU counters
        ├── updateNetwork()   → getifaddrs + URLSession ping
        ├── updateDisk()      → FileManager.mountedVolumeURLs
        ├── updateBattery()   → IOKit AppleSmartBattery
        ├── readFanSpeeds()   → SMC keys F0Ac, F1Ac
        ├── detectAnomalies() → spike/sustained/growth detection
        ├── AlertService.check()
        ├── HistoryStore.record()
        └── AutoKillService.checkRules()
```

**CPU Temperature — SMC Key Cascade** (for cross-chip compatibility):
```swift
["TC0P", "TC0D", "TC0E", "TC0F", "Th0H", "TA0P", "TW0P", "TCXC"]
// Intel Tdie → Intel die → Apple Silicon Th → ambient → …
```

### StoreService
**File**: `Services/StoreService.swift`

StoreKit 2 IAP. In `#if DEBUG` builds, Pro is always unlocked — no sandbox Apple ID needed.

### AlertService
**File**: `Services/AlertService.swift`

Per-metric threshold monitoring with:
- 30-second soak time (must stay above threshold for 30s before firing)
- 5-minute per-metric cooldown (prevents alert storms)
- Severity classification (warning vs critical)
- Fires `UNNotification` + Pushover push

### AIAnalysisService
**File**: `Services/AIAnalysisService.swift`

Calls Anthropic Claude API with a 10-minute rolling window of metrics. API key stored exclusively in Keychain via `KeychainHelper`.

### HistoryStore
**File**: `Services/HistoryStore.swift`

Persists `DailySummary` JSON files to:
```
~/Library/Application Support/PulseBar/history/YYYY-MM-DD.json
```
Max 30 files, pruned on each write. Hourly flush, midnight rotation.

---

## Feature Layer

### Menu Bar (`AppDelegate`)

```
AppDelegate
  ├── statusItems: [String: NSStatusItem]
  ├── popovers:    [String: NSPopover]
  ├── updateIcons()    ← timer-driven, calls drawModuleIcon()
  └── drawModuleIcon() ← custom NSImage drawing with NSGradient
```

Each module (cpu, ram, gpu, network, disk, battery) gets its own:
- `NSStatusItem` with custom icon
- `NSPopover` with `NSHostingController<ModulePopoverView>`

### Pro Features

| Feature | Entry Point | Service |
|---------|------------|---------|
| AI Analysis | `AIInsightView` | `AIAnalysisService` |
| Dashboard | `DashboardWindowController` | `MonitorService` |
| Benchmark |`BenchmarkView` | `BenchmarkService` |
| History | `HistoryView` | `HistoryStore` |
| Auto-Kill | `AutoKillView` | `AutoKillService` |
| Themes | `ThemeEditorView` | `ThemeService` |
| Popup Editor | `PopupEditorView` | `@AppStorage` |

---

## Data Flow

```
IOKit/sysctl
    ↓
MonitorService (background thread collection)
    ↓  DispatchQueue.main.async
@Published properties (main thread)
    ↓
SwiftUI Views (auto-refresh via @EnvironmentObject / @StateObject)
    ↓
NSStatusItem icons (update via statusItemUpdateCallback)
```

---

## Threading Model

| Thread | What happens there |
|--------|-------------------|
| Main | All UI updates, @Published mutations, SwiftUI rendering |
| Background | IOKit reads, process enumeration, network ping |
| Async Task | Claude API calls, Pushover API, StoreKit |

All `@Published` property updates go through `DispatchQueue.main.async { }` or `await MainActor.run { }`.

---

## WidgetKit Integration

- **Target**: `PulseBarWidget`  
- **Shared data**: App Group `group.com.danyaczhan.pulsebar` via `UserDefaults`  
- **Payload struct**: `WidgetMetrics` (Codable) written by `MonitorService.writeWidgetMetrics()`  
- **Sizes**: small (single metric), medium (4-up grid), large (full dashboard)  
- **Refresh**: System-driven (background app refresh)

---

## Zero Third-Party Dependencies

All functionality built on Apple frameworks only:

| Framework | Used for |
|-----------|---------|
| `AppKit` | Status items, popovers, windows, NSImage drawing |
| `SwiftUI` | All UI views, forms, charts |
| `IOKit` | SMC temperature, battery, GPU, fan reading |
| `Foundation` | Timers, URLSession, FileManager, Codable |
| `WidgetKit` | Desktop widgets |
| `AppIntents` | Siri/Shortcuts integration |
| `StoreKit` | In-app purchases |
| `UserNotifications` | Local alert notifications |
| `Security` | Keychain API key storage |
| `Charts` | Swift Charts sparklines and history graphs |
