# Contributing to PulseBar

Thank you for your interest in contributing! Every contribution matters. 🎉

---

## Ways to Contribute

| | |
|--|--|
| 🐛 | Report bugs via [GitHub Issues](https://github.com/USERNAME/PulseBar/issues/new?template=bug_report.md) |
| 💡 | Suggest features via [GitHub Issues](https://github.com/USERNAME/PulseBar/issues/new?template=feature_request.md) |
| 🔧 | Submit Pull Requests |
| 📖 | Improve documentation |
| ⭐ | Star the repo (helps others discover it!) |

---

## Development Setup

```bash
# 1. Fork & clone
git clone https://github.com/YOUR_USERNAME/PulseBar.git
cd PulseBar

# 2. One-command setup (installs xcodegen, generates .xcodeproj)
./scripts/setup.sh

# 3. Open and run
open PulseBar.xcodeproj
# Press ⌘R in Xcode
```

In **Debug builds**, all Pro features are unlocked automatically — no purchase required.

---

## Code Style Guide

### General
- Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- Use SwiftUI where possible; AppKit only when required (status items, windows, popovers)
- Keep files ≤ 300 lines; split into extensions if longer

### Threading
```swift
// ✅ Correct — all @Published updates on MainActor
await MainActor.run { self.cpuData = newData }
DispatchQueue.main.async { self.someProperty = value }

// ❌ Wrong — @Published mutation on background thread
self.cpuData = newData  // from background queue
```

### Optionals
```swift
// ✅ Correct
guard let value = optionalValue else { return }
let result = optional ?? defaultValue

// ❌ Wrong
let value = optional!  // never force-unwrap
```

### IOKit
```swift
// ✅ Always guard + defer release
let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
guard service != IO_OBJECT_NULL else { return }
defer { IOObjectRelease(service) }
```

### Comments
- Use `// MARK: - Section Name` to organize long files
- Document public APIs with `///` doc comments
- Mark bug fixes: `// FIXED: brief description`

---

## Pull Request Process

1. **Fork** the repo + create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/bug-description
   ```

2. **Make your changes** following the style guide above

3. **Verify the build passes**:
   ```bash
   ./scripts/build.sh
   ```

4. **Update `CHANGELOG.md`** under `[Unreleased]` with your change

5. **Open a PR** against `main` — fill in the PR template

---

## Commit Message Format

```
type: short description (max 72 chars)

Optional longer body explaining WHY (not what).
```

| Type | When to use |
|------|-------------|
| `feat` | New feature or enhancement |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `refactor` | Code restructure, no behavior change |
| `test` | Test additions |
| `chore` | Build scripts, CI, dependencies |

**Examples:**
```
feat: add fan speed animation with RPM display
fix: CPU temperature reading on M3 chips (add TCXC SMC key)
docs: add Pushover setup instructions to api-keys.md
```

---

## Bug Reports

Include in your report:
- macOS version (System Settings → General → About)
- Mac model and chip (e.g. MacBook Pro M3 14", Apple M3)
- PulseBar version (About panel in Settings)
- Steps to reproduce
- Expected vs actual behavior
- Console logs: open `Console.app`, filter by "PulseBar", copy relevant lines

---

## Feature Requests

Please check [existing issues](https://github.com/USERNAME/PulseBar/issues) first.  
Describe: **who** benefits, **what** they'd do, **why** it matters.

---

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
