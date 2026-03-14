# PulseBar

> Free, open-source macOS system monitor living in your menu bar.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Build](https://github.com/USERNAME/PulseBar/actions/workflows/build.yml/badge.svg)
![Version](https://img.shields.io/badge/version-1.0.0-purple)

PulseBar puts real-time system metrics—CPU, RAM, GPU, network, disk, battery—right in your macOS menu bar as compact, colorful, animated icons. Click any icon for a detailed popover. No menubar clutter: each module is independently show/hide-able.

---

## ✨ Features

### Free
| | |
|--|--|
| 🌡 | CPU & GPU temperature (SMC, multi-key fallback for M-series) |
| ⚡ | CPU load per-core heatmap |
| 🧠 | RAM usage breakdown (used / wired / compressed) |
| 🔋 | Battery health, cycle count, temperature |
| 🌐 | Network speed ↑↓ with live ping |
| 💾 | Disk usage — all mounted volumes |
| 📊 | Live sparkline graphs in every popup card |
| 🌈 | Gradient-colored menu bar icons per module |
| ⚙️ | Per-module settings (show/hide, interval, style) |
| 🖥 | Floating desktop overlay widget |
| 🔔 | Smart alerts (CPU temp, RAM, battery thresholds) |

### Pro ($2.99 one-time)
| | |
|--|--|
| 🤖 | AI anomaly analysis (Claude API, Keychain-stored key) |
| 📈 | Fullscreen performance dashboard with Swift Charts |
| ⏱ | Built-in CPU/RAM benchmark with percentile ranking |
| 📅 | 30-day performance history with trend graphs |
| 🎯 | Auto-kill process rules (SIGTERM on CPU threshold breach) |
| 📱 | iPhone push notifications via Pushover |
| ⚡ | Apple Shortcuts integration (Siri-compatible) |
| 🔔 | Smart contextual alerts with culprit process + severity |
| 🎨 | Custom color themes editor (3 built-ins + custom) |
| 🖥 | Multi-monitor support — metrics on secondary displays |
| 🌈 | Gradient animated menu bar icons |
| 🖱 | Drag-and-drop popup card editor |

---

## 📸 Screenshots

| Menu Bar | CPU Popup | Settings |
|----------|-----------|----------|
| *(add screenshot)* | *(add screenshot)* | *(add screenshot)* |

> **Add screenshots**: run PulseBar, take screenshots, drop them in `docs/screenshots/`, then update the table above.

---

## 🚀 Quick Start

### Option 1 — Download (recommended)
1. Go to [Releases](https://github.com/USERNAME/PulseBar/releases)
2. Download `PulseBar.dmg`
3. Drag to Applications → Launch
4. PulseBar appears in your menu bar instantly ✅

### Option 2 — Build from source
```bash
# Prerequisites: Xcode 15+, macOS 13+
git clone https://github.com/USERNAME/PulseBar.git
cd PulseBar
./scripts/setup.sh          # installs xcodegen, generates .xcodeproj
open PulseBar.xcodeproj
# Press ⌘R in Xcode
```

---

## 🏗 Architecture

PulseBar uses **MVVM + Service Layer** with a clean separation of concerns:

```
App Layer       →  AppDelegate, PulseBarApp
Service Layer   →  MonitorService, StoreService, AlertService, …
Feature Layer   →  Per-module Views (Popup, Settings, Pro panels)
Shared Layer    →  DesignSystem, reusable components
Widget Target   →  PulseBarWidget (WidgetKit)
```

See [docs/architecture.md](docs/architecture.md) for the full deep-dive.

### Data Flow
```
IOKit/sysctl → MonitorService (@Published)
             → SwiftUI Views (auto-refresh)
             → NSStatusItem images (timer-driven)
```

### Threading Model
- MonitorService timer fires on a background queue
- All `@Published` updates dispatched through `DispatchQueue.main` / `MainActor`
- UI always updates on the main thread ✅

---

## ⚙️ Requirements

| | Minimum |
|---|---|
| macOS | 13.0 Ventura |
| Xcode | 15.0 |
| Swift | 5.9 |
| Apple Developer account | Free tier works |

---

## 🤖 AI & Push Setup

- **Claude AI analysis**: see [docs/api-keys.md](docs/api-keys.md#claude-ai)
- **iPhone push notifications**: see [docs/api-keys.md](docs/api-keys.md#pushover)

All API keys are stored in the **macOS Keychain** — never in UserDefaults or on disk.

---

## 🤝 Contributing

We welcome contributions of all kinds! See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup
- Code style guide
- PR process
- Commit message format

---

## 🔒 Security

No telemetry. No analytics. No data leaves your Mac except:
- AI analysis calls (opt-in, your own API key)
- Push notifications (opt-in, your own Pushover account)

See [SECURITY.md](SECURITY.md) for our vulnerability disclosure policy.

---

## 📄 License

[MIT License](LICENSE) © 2026 PulseBar Contributors

---

## 🙏 Acknowledgments

Built entirely with Apple frameworks: **Swift · SwiftUI · AppKit · IOKit · WidgetKit · AppIntents · StoreKit 2 · Swift Charts** — zero third-party dependencies.
