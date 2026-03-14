<div align="center">

# Architecture

[English](#english) · [Русский](#русский)

</div>

---

## English

### Overview

PulseBar follows MVVM with a service layer pattern:

```
App/          Entry point, NSApplication setup, status item wiring
Services/     Business logic singletons (ObservableObject)
Views/        SwiftUI views organized by feature
Helpers/      KeychainHelper, extensions
Intents/      AppIntents for Siri / Shortcuts integration
Resources/    Assets, plist, storekit, entitlements
PulseBarWidget/  WidgetKit target
```

### Data Flow

```
IOKit / sysctl / FileManager
        ↓
MonitorService  (background timer)
        ↓  DispatchQueue.main.async
@Published properties  (main thread)
        ↓
SwiftUI views  (auto-refresh)
NSStatusItem images  (timer-driven updates)
```

### Service Layer

Each service is an `ObservableObject` singleton initialized at app launch.

| Service | Responsibility |
|---------|---------------|
| `MonitorService` | All hardware data collection via IOKit, sysctl, FileManager |
| `StoreService` | StoreKit 2 in-app purchases |
| `AlertService` | Threshold monitoring, soak time, cooldown, notifications |
| `AIAnalysisService` | Claude API integration |
| `BenchmarkService` | CPU/RAM performance testing |
| `HistoryStore` | 30-day JSON persistence in Application Support |
| `AutoKillService` | Process termination rule engine |
| `ThemeService` | Color theme management and persistence |
| `PushNotificationService` | Pushover API client |
| `WeeklyReportService` | Weekly digest generation |

### MonitorService — Collection Loop

```
Timer (every N seconds)
  └── collectAll()
        ├── readCPU()          IOKit + host_processor_info
        ├── readRAM()          host_statistics64
        ├── readGPU()          IOService GPU counters
        ├── updateNetwork()    getifaddrs + URLSession
        ├── updateDisk()       FileManager.mountedVolumeURLs
        ├── updateBattery()    IOKit AppleSmartBattery
        ├── readFanSpeeds()    SMC keys F0Ac, F1Ac
        ├── AlertService.check()
        ├── HistoryStore.record()
        └── AutoKillService.checkRules()
```

### CPU Temperature — SMC Key Cascade

On Apple Silicon, Intel-era SMC keys return zero. PulseBar tries keys in sequence:

```
TC0P → TC0D → TC0E → TC0F → Th0H → TA0P → TW0P → TCXC
```

Each value is validated against the range 20–120°C. If all keys fail, a load-based estimate is returned as a fallback.

### Threading Model

| Thread | Responsibilities |
|--------|-----------------|
| Main | All UI updates, @Published mutations, SwiftUI rendering |
| Background | IOKit reads, process enumeration, network ping |
| Async Task | Claude API, Pushover API, StoreKit operations |

### WidgetKit Integration

- **Target**: `PulseBarWidget`
- **Shared data**: App Group `group.com.danyaczhan.pulsebar` via `UserDefaults`
- **Payload**: `WidgetMetrics` (Codable) written by `MonitorService.writeWidgetMetrics()`
- **Sizes**: small, medium, large
- **Refresh**: system-driven background app refresh

### Why No Third-Party Dependencies

| Reason | Detail |
|--------|--------|
| Build simplicity | Any contributor can clone and build without package resolution |
| Security surface | Fewer dependencies = fewer supply chain risks |
| Completeness | All required APIs are available in Apple frameworks |

---

## Русский

### Обзор

PulseBar использует MVVM с сервисным слоем:

```
App/           Точка входа, настройка NSApplication, подключение status items
Services/      Синглтоны бизнес-логики (ObservableObject)
Views/         SwiftUI-вьюхи, организованные по функциям
Helpers/       KeychainHelper, расширения
Intents/       AppIntents для Siri / Shortcuts
Resources/     Assets, plist, storekit, entitlements
PulseBarWidget/ Таргет WidgetKit
```

### Поток данных

```
IOKit / sysctl / FileManager
        ↓
MonitorService  (фоновый таймер)
        ↓  DispatchQueue.main.async
@Published свойства  (главный поток)
        ↓
SwiftUI-вьюхи  (авто-обновление)
NSStatusItem иконки  (обновление по таймеру)
```

### Сервисный слой

Каждый сервис — синглтон `ObservableObject`, инициализируется при запуске.

| Сервис | Ответственность |
|--------|----------------|
| `MonitorService` | Сбор всех данных оборудования через IOKit, sysctl, FileManager |
| `StoreService` | Встроенные покупки StoreKit 2 |
| `AlertService` | Мониторинг порогов, выдержка времени, кулдаун, уведомления |
| `AIAnalysisService` | Интеграция с Claude API |
| `BenchmarkService` | Тестирование производительности CPU/RAM |
| `HistoryStore` | 30-дневное хранилище JSON в Application Support |
| `AutoKillService` | Движок правил завершения процессов |
| `ThemeService` | Управление цветовыми темами |
| `PushNotificationService` | Клиент Pushover API |

### Температура CPU — цепочка SMC-ключей

На Apple Silicon ключи эпохи Intel возвращают ноль. PulseBar перебирает ключи по порядку:

```
TC0P → TC0D → TC0E → TC0F → Th0H → TA0P → TW0P → TCXC
```

Каждое значение проверяется в диапазоне 20–120°C. Если все ключи не дали результата, возвращается оценка на основе загрузки.

### Модель потоков

| Поток | Задачи |
|-------|--------|
| Главный | Все обновления UI, мутации @Published, рендеринг SwiftUI |
| Фоновый | Чтение IOKit, перечисление процессов, сетевой пинг |
| Async Task | Claude API, Pushover API, операции StoreKit |

### Почему нет сторонних зависимостей

| Причина | Подробности |
|---------|------------|
| Простота сборки | Любой контрибьютор может клонировать и собрать без разрешения пакетов |
| Поверхность атаки | Меньше зависимостей — меньше рисков цепочки поставок |
| Полнота | Все необходимые API доступны во фреймворках Apple |
