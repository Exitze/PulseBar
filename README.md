<div align="center">

# PulseBar

**macOS system monitor that lives in your menu bar**

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-F05138)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Build](https://github.com/Exitze/PulseBar/actions/workflows/build.yml/badge.svg)](https://github.com/Exitze/PulseBar/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/Exitze/PulseBar)](https://github.com/Exitze/PulseBar/releases/latest)

[English](#english) · [Русский](#русский)

</div>

---

## English

PulseBar is a lightweight, open-source system monitor for macOS. It displays CPU, GPU, RAM, network, disk, and battery metrics as individual status items in your menu bar. Click any item to expand it into a detailed panel.

Built entirely on Apple frameworks — no third-party dependencies.

### Features

**Free**
- CPU & GPU usage with temperature (multi-key SMC support for Apple Silicon)
- Per-core load heatmap
- RAM breakdown: used, wired, compressed
- Battery health, cycle count, charge state
- Network throughput and latency
- Disk usage across all mounted volumes
- Live sparkline graphs
- Individually configurable status items (show/hide, refresh interval)
- Floating overlay widget

**Pro — $2.99 (one-time)**
- AI anomaly analysis via Claude API
- Fullscreen performance dashboard
- CPU/RAM benchmark with historical comparison
- 30-day performance history with trend analysis
- Automatic process termination rules
- Push notifications to iPhone via Pushover
- Apple Shortcuts / Siri integration
- Contextual smart alerts with culprit process detection
- Custom color themes
- Multi-monitor status bar support
- Drag-and-drop popup card editor

### Installation

**Download (pre-built)**

1. Download [`PulseBar.zip`](https://github.com/Exitze/PulseBar/releases/download/v1.0.0/PulseBar.zip) from the latest release
2. Unzip and move `PulseBar.app` to `/Applications`
3. Right-click → **Open** → **Open** on first launch (Gatekeeper warning — unsigned build)

**Build from source**

Prerequisites: Xcode 15+, macOS 13+

```bash
git clone https://github.com/Exitze/PulseBar.git
cd PulseBar
./scripts/setup.sh   # installs xcodegen and generates .xcodeproj
open PulseBar.xcodeproj
```

Press `⌘R` to build and run. All Pro features are unlocked in Debug builds.

### Architecture

PulseBar follows MVVM with a service layer:

```
App/          Entry point, AppDelegate, status item management
Services/     MonitorService, StoreService, AlertService, and others
Views/        SwiftUI views organized by feature
Helpers/      KeychainHelper, extensions
Intents/      AppIntents for Shortcuts integration
```

Metrics are collected on a background queue and published to the main thread via `@Published` properties. See [docs/architecture.md](docs/architecture.md) for details.

### Requirements

| | Minimum |
|---|---|
| macOS | 13.0 Ventura |
| Xcode | 15.0 (for building) |

### Contributing

Pull requests are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting changes.

```bash
git checkout -b feature/your-feature
# make changes
./scripts/build.sh   # must pass with 0 errors
```

### License

[MIT](LICENSE) © 2026 PulseBar Contributors

---

## Русский

PulseBar — лёгкий монитор системы с открытым исходным кодом для macOS. Отображает метрики CPU, GPU, RAM, сети, диска и батареи в виде отдельных элементов в строке меню. Нажмите на любой элемент, чтобы открыть подробную панель.

Написан полностью на фреймворках Apple — без сторонних зависимостей.

### Возможности

**Бесплатно**
- Температура и загрузка CPU / GPU (поддержка Apple Silicon через цепочку SMC-ключей)
- Тепловая карта ядер CPU
- RAM: используемая, wired, compressed
- Здоровье батареи, количество циклов, состояние зарядки
- Скорость сети и задержка
- Использование диска по всем томам
- Живые sparkline-графики
- Независимая настройка каждого модуля (показ/скрытие, интервал обновления)
- Плавающий виджет поверх окон

**Pro — $2.99 (разово)**
- AI-анализ аномалий через Claude API
- Полноэкранный дашборд производительности
- Бенчмарк CPU/RAM с историей результатов
- 30-дневная история с анализом трендов
- Автоматическое завершение процессов по правилам
- Push-уведомления на iPhone через Pushover
- Интеграция с Apple Shortcuts / Siri
- Умные алерты с определением виновного процесса
- Редактор цветовых тем
- Поддержка нескольких мониторов
- Редактор карточек с перетаскиванием

### Установка

**Скачать готовое приложение**

1. Скачайте [`PulseBar.zip`](https://github.com/Exitze/PulseBar/releases/download/v1.0.0/PulseBar.zip) из последнего релиза
2. Распакуйте и перенесите `PulseBar.app` в `/Applications`
3. При первом запуске: правая кнопка → **Открыть** → **Открыть** (предупреждение Gatekeeper — сборка без подписи)

**Собрать из исходников**

Требования: Xcode 15+, macOS 13+

```bash
git clone https://github.com/Exitze/PulseBar.git
cd PulseBar
./scripts/setup.sh   # устанавливает xcodegen и создаёт .xcodeproj
open PulseBar.xcodeproj
```

Нажмите `⌘R` для сборки. В Debug-сборках все Pro-функции разблокированы.

### Вклад в проект

Pull request'ы приветствуются. Перед отправкой ознакомьтесь с [CONTRIBUTING.md](CONTRIBUTING.md).

### Лицензия

[MIT](LICENSE) © 2026 PulseBar Contributors
