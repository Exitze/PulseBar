# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 1.x.x   | ✅ Active support  |

---

## Reporting a Vulnerability

> **Do NOT open a public GitHub issue for security vulnerabilities.**

Use one of these private channels:

- **GitHub Security Advisory**: Repository → Security → Advisories → New draft advisory *(preferred)*
- **Email**: security@pulsebar.app

### Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact assessment
- Suggested fix (optional but appreciated)

### Response commitment:
- Acknowledgement within **48 hours**
- Status update within **72 hours**
- Patch released within **7 days** for critical issues

---

## Security Design Notes

### API Keys & Credentials
- All API keys (Claude/Anthropic) stored in **macOS Keychain** via `Security.framework`
- Never stored in `UserDefaults`, plist, or any file on disk
- Pushover credentials stored in `UserDefaults` (non-sensitive identifiers only)

### Data Privacy
- **No telemetry** — PulseBar never phones home
- **No analytics** — no crash reporters, no usage tracking
- **No account required** — no sign-in, no cloud sync

### Network Access
Data leaving your Mac is strictly opt-in:

| Feature | Data sent | When |
|---------|-----------|------|
| AI Analysis | CPU/RAM/process metrics snapshot | When user taps "Analyze" |
| Push notifications | Alert title + body | When alert threshold crossed |
| Ping check | HTTPS HEAD to captive.apple.com | Every N seconds |

### Entitlements
The app runs **unsandboxed** (required for IOKit SMC access and process monitoring).  
No `com.apple.security.app-sandbox` entitlement is claimed.

### IOKit Access
SMC reads use `IOServiceOpen` with `kIOMainPortDefault` — standard public API.  
No private API usage.

### Process Kill
`SIGTERM` only (graceful quit). Never `SIGKILL`. Auto-kill rules require explicit user configuration.
