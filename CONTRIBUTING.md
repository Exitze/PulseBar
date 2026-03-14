<div align="center">

# Contributing to PulseBar

[English](#english) · [Русский](#русский)

</div>

---

## English

### Ways to Contribute

- Report bugs via [GitHub Issues](https://github.com/Exitze/PulseBar/issues/new?template=bug_report.md)
- Suggest features via [GitHub Issues](https://github.com/Exitze/PulseBar/issues/new?template=feature_request.md)
- Submit pull requests
- Improve documentation
- Star the repository

### Development Setup

```bash
git clone https://github.com/Exitze/PulseBar.git
cd PulseBar
./scripts/setup.sh
open PulseBar.xcodeproj
```

All features are unlocked in Debug builds — no purchase required.

### Code Style

**Threading**

All `@Published` mutations must happen on the main thread:

```swift
// Correct
await MainActor.run { self.cpuData = newData }
DispatchQueue.main.async { self.value = result }

// Wrong — never mutate @Published on a background thread
self.cpuData = newData
```

**Optionals**

```swift
// Correct
guard let value = optional else { return }
let result = optional ?? defaultValue

// Wrong
let value = optional!
```

**IOKit**

```swift
// Always guard + defer release
let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
guard service != IO_OBJECT_NULL else { return }
defer { IOObjectRelease(service) }
```

**File organization**

- Use `// MARK: - Section Name` to organize files longer than 100 lines
- Document public APIs with `///` doc comments
- Keep files under 300 lines where possible

### Pull Request Process

1. Fork the repository and create a branch:
   ```bash
   git checkout -b feature/your-feature
   # or
   git checkout -b fix/issue-description
   ```
2. Make your changes following the style guide above
3. Verify the build passes with zero errors: `./scripts/build.sh`
4. Update `CHANGELOG.md` under `[Unreleased]`
5. Open a pull request against `main`

### Commit Message Format

```
type: short description
```

| Type | When |
|------|------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change with no behavior change |
| `chore` | Build, CI, tooling |

Examples:
```
feat: add fan speed animation
fix: CPU temperature on M3 chips (add TCXC SMC key)
docs: update Pushover setup guide
```

### Reporting Bugs

Include in your report:
- macOS version
- Mac model and chip (e.g. MacBook Pro M3 14")
- PulseBar version (Settings → About)
- Steps to reproduce
- Console logs from Console.app filtered by "PulseBar"

### License

By contributing, you agree your changes will be licensed under the [MIT License](LICENSE).

---

## Русский

### Как внести вклад

- Сообщить об ошибке через [GitHub Issues](https://github.com/Exitze/PulseBar/issues/new?template=bug_report.md)
- Предложить функцию через [GitHub Issues](https://github.com/Exitze/PulseBar/issues/new?template=feature_request.md)
- Отправить pull request
- Улучшить документацию
- Поставить звезду репозиторию

### Настройка среды разработки

```bash
git clone https://github.com/Exitze/PulseBar.git
cd PulseBar
./scripts/setup.sh
open PulseBar.xcodeproj
```

В Debug-сборках все функции разблокированы — покупка не требуется.

### Стиль кода

**Потоки**

Все изменения `@Published`-свойств только на главном потоке:

```swift
// Правильно
await MainActor.run { self.cpuData = newData }
DispatchQueue.main.async { self.value = result }

// Неправильно
self.cpuData = newData  // из фонового потока
```

**Опционалы**

```swift
// Правильно
guard let value = optional else { return }
let result = optional ?? defaultValue

// Неправильно
let value = optional!
```

**IOKit**

```swift
let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
guard service != IO_OBJECT_NULL else { return }
defer { IOObjectRelease(service) }
```

### Процесс pull request

1. Форкните репозиторий и создайте ветку:
   ```bash
   git checkout -b feature/название-функции
   ```
2. Внесите изменения согласно стилю выше
3. Проверьте сборку: `./scripts/build.sh` — должно быть 0 ошибок
4. Обновите `CHANGELOG.md` в разделе `[Не выпущено]`
5. Откройте pull request в ветку `main`

### Формат сообщений коммитов

```
тип: краткое описание
```

| Тип | Когда использовать |
|-----|-------------------|
| `feat` | Новая функція |
| `fix` | Исправление бага |
| `docs` | Только документация |
| `refactor` | Рефакторинг без изменения поведения |
| `chore` | Сборка, CI, инструменты |

### Отчёт об ошибке

Укажите в сообщении:
- Версию macOS
- Модель и чип Mac (например, MacBook Pro M3 14")
- Версию PulseBar (Настройки → About)
- Шаги воспроизведения
- Логи из Console.app с фильтром "PulseBar"

### Лицензия

Внося вклад, вы соглашаетесь с условиями [MIT License](LICENSE).
