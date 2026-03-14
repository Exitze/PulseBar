<div align="center">

# Changelog

[English](#english) · [Русский](#русский)

</div>

---

## English

All notable changes to PulseBar are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Versioning: [SemVer](https://semver.org/)

### [Unreleased]

### [1.0.0] — 2026-03-14

#### Added

**Core monitoring**
- CPU & GPU usage with temperature via IOKit SMC (multi-key fallback: TC0P → TC0D → TC0E → Th0H → TA0P for Apple Silicon)
- Per-core CPU load heatmap
- RAM breakdown: used, wired, compressed, available
- Battery health, cycle count, max capacity, temperature via AppleSmartBattery
- All mounted disk volumes via FileManager
- Network throughput (upload/download) and latency
- Fan speed monitoring

**Menu bar**
- Separate NSStatusItem per module (CPU, RAM, GPU, Network, Disk, Battery)
- Custom-drawn gradient icons with per-module color palette
- Per-module show/hide and refresh interval (configurable)

**Popups**
- Frosted-glass NSPopover per module
- Live sparkline graphs (60-point rolling window)
- ArcIndicatorView with gradient fill
- OdometerText animated number transitions

**Settings**
- Native NavigationSplitView settings window
- Per-module configuration panels
- Alert threshold sliders

**Advanced features**
- AI anomaly analysis via Claude API (API key stored in Keychain)
- Fullscreen performance dashboard with Swift Charts
- CPU/RAM benchmark with percentile scoring and run history
- 30-day performance history stored as daily JSON files
- Auto-kill process rules with SIGTERM and notifications
- Push notifications to iPhone via Pushover API
- Apple Shortcuts / Siri integration via AppIntents
- Smart alerts with soak time, cooldown, culprit process detection
- Custom color themes (3 built-in + custom editor)
- Multi-monitor status bar support
- Drag-and-drop popup card editor
- WidgetKit extension (small / medium / large)
- Floating overlay widget

---

[Unreleased]: https://github.com/Exitze/PulseBar/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Exitze/PulseBar/releases/tag/v1.0.0

---

## Русский

Все значимые изменения в PulseBar фиксируются здесь.
Формат: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Версионирование: [SemVer](https://semver.org/)

### [Не выпущено]

### [1.0.0] — 2026-03-14

#### Добавлено

**Базовый мониторинг**
- Загрузка и температура CPU / GPU через IOKit SMC (цепочка ключей: TC0P → TC0D → TC0E → Th0H → TA0P для Apple Silicon)
- Тепловая карта ядер CPU
- RAM: используемая, wired, compressed, available
- Здоровье батареи, циклы, ёмкость, температура через AppleSmartBattery
- Все смонтированные тома через FileManager
- Скорость сети (upload/download) и задержка
- Мониторинг скорости вентиляторов

**Строка меню**
- Отдельный NSStatusItem для каждого модуля
- Кастомные иконки с градиентом, цвет зависит от модуля
- Настройка показа/скрытия и интервала обновления отдельно для каждого модуля

**Попапы**
- NSPopover с матовым стеклом для каждого модуля
- Живые sparkline-графики (60-точечное скользящее окно)
- ArcIndicatorView с градиентной заливкой
- Анимированное переключение чисел OdometerText

**Настройки**
- Нативное окно настроек на NavigationSplitView
- Панель настроек для каждого модуля
- Ползунки порогов алертов

**Расширенные функции**
- AI-анализ аномалий через Claude API (ключ хранится в Keychain)
- Полноэкранный дашборд с Swift Charts
- Бенчмарк CPU/RAM с процентильным рейтингом и историей
- 30-дневная история в виде ежедневных JSON-файлов
- Авто-завершение процессов по правилам (SIGTERM + уведомления)
- Push-уведомления на iPhone через Pushover API
- Интеграция с Apple Shortcuts / Siri через AppIntents
- Умные алерты: выдержка времени, кулдаун, определение виновного процесса
- Цветовые темы (3 встроенных + редактор)
- Поддержка нескольких мониторов
- Редактор карточек попапа с перетаскиванием
- Расширение WidgetKit (малый / средний / большой)
- Плавающий виджет поверх окон
