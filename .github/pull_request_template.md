## Summary
<!-- Briefly describe what this PR does and why -->

## Related Issue
Closes #<!-- issue number -->

## Type of Change
- [ ] 🐛 Bug fix (non-breaking change that fixes an issue)
- [ ] ✨ New feature (non-breaking change that adds functionality)
- [ ] 💥 Breaking change (fix or feature that changes existing behavior)
- [ ] 📖 Documentation update
- [ ] 🔧 Refactor / code quality improvement

## What Changed
<!-- List the specific changes made -->
- 

## Testing Performed
- [ ] Tested on macOS 13 Ventura
- [ ] Tested on macOS 14 Sonoma
- [ ] Tested on Apple Silicon (M-series)
- [ ] Tested on Intel Mac (if applicable)
- [ ] `./scripts/build.sh` passes with 0 errors

## Checklist
- [ ] Code follows project style guide (see [CONTRIBUTING.md](CONTRIBUTING.md))
- [ ] No force-unwraps (`!`) added
- [ ] All `@Published` updates via `MainActor` / `DispatchQueue.main`
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] No sensitive data committed (API keys, credentials, etc.)
- [ ] IOKit calls use `guard service != IO_OBJECT_NULL` + `defer { IOObjectRelease(service) }`

## Screenshots (if UI changes)
<!-- Add before/after screenshots for any visual changes -->
