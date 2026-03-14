# PulseBar

> Free, open-source macOS system monitor living in your menu bar.  
> Бесплатный мониторинг системы macOS прямо в строке меню.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Build](https://github.com/Exitze/PulseBar/actions/workflows/build.yml/badge.svg)
![Version](https://img.shields.io/badge/version-1.0.0-purple)

---

## 📥 Download / Скачать

### ⬇️ [PulseBar.zip — скачать готовое приложение](https://github.com/Exitze/PulseBar/releases/download/v1.0.0/PulseBar.zip)

**Установка (3 шага):**
1. Скачай `PulseBar.zip` по ссылке выше
2. Распакуй → перетащи `PulseBar.app` в папку `/Applications`
3. Правой кнопкой на приложение → **Открыть** → **Открыть** *(первый запуск)*

> PulseBar появится в строке меню сразу после запуска 🚀

**Installation (3 steps):**
1. Download `PulseBar.zip` using the link above
2. Unzip → drag `PulseBar.app` to `/Applications`
3. Right-click the app → **Open** → **Open** *(first launch only)*

> PulseBar will appear in your menu bar instantly 🚀

---

## 🇷🇺 Русский

PulseBar — это бесплатный монитор системы для macOS. Показывает CPU, RAM, GPU, сеть, диск и батарею прямо в строке меню в виде компактных цветных иконок. Кликни на любую иконку — получи подробную статистику.

### ✨ Возможности (бесплатно)
- 🌡 Температура CPU и GPU (с поддержкой Apple Silicon)
- ⚡ Загрузка ядер CPU (тепловая карта)
- 🧠 Использование RAM (used / wired / compressed)
- 🔋 Здоровье батареи, циклы, температура
- 🌐 Скорость сети ↑↓ + пинг
- 💾 Использование диска (все тома)
- 📊 Живые графики sparkline в каждой карточке
- 🌈 Цветные иконки с градиентом в строке меню
- ⚙️ Настройки для каждого модуля отдельно

### 🔑 Pro-функции ($2.99 единоразово)
- 🤖 AI-анализ аномалий (Claude API)
- 📈 Полноэкранный дашборд производительности
- ⏱ Бенчмарк CPU / RAM
- 📅 История за 30 дней
- 🎯 Авто-завершение процессов по правилам
- 📱 Push-уведомления на iPhone (через Pushover)
- ⚡ Интеграция с Apple Shortcuts / Siri
- 🔔 Умные алерты с анализом причин
- 🎨 Редактор цветовых тем
- 🖥 Поддержка нескольких мониторов
- 🖱 Редактор карточек drag-and-drop

### 🚀 Собрать из исходников
```bash
git clone https://github.com/Exitze/PulseBar.git
cd PulseBar
./scripts/setup.sh
open PulseBar.xcodeproj
# Нажми ⌘R в Xcode
```

---

## 🇬🇧 English

PulseBar puts real-time system metrics — CPU, RAM, GPU, network, disk, battery — right in your macOS menu bar as compact, colorful, animated icons. Click any icon for a detailed popover.

### ✨ Free Features
| | |
|--|--|
| 🌡 | CPU & GPU temperature (SMC multi-key fallback for M-series) |
| ⚡ | Per-core CPU load heatmap |
| 🧠 | RAM breakdown (used / wired / compressed) |
| 🔋 | Battery health, cycle count, temperature |
| 🌐 | Network speed ↑↓ with live ping |
| 💾 | Disk usage — all mounted volumes |
| 📊 | Live sparkline graphs in every popup card |
| 🌈 | Gradient-colored menu bar icons per module |
| ⚙️ | Per-module settings (show/hide, interval, style) |

### 🔑 Pro Features ($2.99 one-time)
| | |
|--|--|
| 🤖 | AI anomaly analysis (Claude API, Keychain-stored key) |
| 📈 | Fullscreen performance dashboard with Swift Charts |
| ⏱ | Built-in CPU/RAM benchmark with percentile ranking |
| 📅 | 30-day performance history with trend graphs |
| 🎯 | Auto-kill process rules (SIGTERM on CPU threshold) |
| 📱 | iPhone push notifications via Pushover |
| ⚡ | Apple Shortcuts / Siri integration |
| 🔔 | Smart contextual alerts with culprit process detection |
| 🎨 | Custom color themes editor |
| 🖥 | Multi-monitor support |
| 🖱 | Drag-and-drop popup card editor |

### 🚀 Build from Source
```bash
git clone https://github.com/Exitze/PulseBar.git
cd PulseBar
./scripts/setup.sh
open PulseBar.xcodeproj
# Press ⌘R in Xcode
```

### ⚙️ Requirements
- macOS 13.0 Ventura or later
- Xcode 15.0+ (for building only)

---

## 🏗 Architecture / Архитектура

```
App Layer      →  AppDelegate, PulseBarApp
Service Layer  →  MonitorService, StoreService, AlertService, …
Feature Layer  →  Per-module Views (Popup, Settings, Pro panels)
Shared Layer   →  DesignSystem, reusable components
Widget Target  →  PulseBarWidget (WidgetKit)
```

See [docs/architecture.md](docs/architecture.md) · [docs/api-keys.md](docs/api-keys.md)

---

## 📸 Screenshots

*(Coming soon — добавим скриншоты)*

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) · [SECURITY.md](SECURITY.md)

## 📄 License
[MIT License](LICENSE) © 2026 PulseBar Contributors

---

*Built with Swift, SwiftUI, AppKit, IOKit, WidgetKit — zero third-party dependencies.*
