# API Keys Setup

> API keys are stored in the macOS Keychain — they never leave your Mac (except for the actual API calls you make).

---

## Claude AI — AI Anomaly Analysis (Pro)

AI analysis sends a snapshot of your last 10 minutes of CPU/RAM/process data to Anthropic Claude for a 2-sentence insight.

### Setup Steps

1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Sign up (free trial credit available)
3. Navigate to **API Keys** → **Create Key**
4. Copy the key (starts with `sk-ant-…`)
5. In PulseBar: **Settings → Alerts → AI Analysis → API Key field**
6. Paste the key → it's immediately saved to Keychain

### What data is sent?

```
CPU temp: avg 62°C, peak 78°C
CPU load: avg 45%, peak 82%
RAM: 8.3 GB avg
Top process: Xcode using 68% CPU
Anomalies: sustained high CPU: Xcode
```

No personal information. No identifiers. Snapshot only.

### Free Tier Limits

Anthropic provides ~$5 credit on signup — enough for **hundreds of analyses**.  
Responses are capped at 200 tokens (~2 sentences).

### Model Used

`claude-sonnet-4-20250514` — fast, intelligent, low cost.

---

## Pushover — iPhone Push Notifications (Pro)

Pushover delivers PulseBar alerts to your iPhone/iPad/Watch as native push notifications.

### Cost

$5 one-time purchase per platform (iOS or Android). Free 30-day trial.

### Setup Steps

1. Go to [pushover.net](https://pushover.net) → Create account
2. Your **User Key** is shown on the dashboard
3. Go to **Your Applications** → **Create an Application**
   - Name: "PulseBar" 
   - Type: Application
4. Copy the **App Token/API Key**
5. In PulseBar: **Settings → Network → iPhone Push**
6. Enter both User Key and App Token → tap **Test Push**

### What notifications look like

```
⚠️ PulseBar: 🔴 CPU Temp 91°C
CPU temperature at 91°C for 2m 15s, and still rising. 
Xcode is using 94% CPU.
```

### Priority Levels

| Alert Severity | Pushover Priority |
|----------------|------------------|
| Warning | 0 (Normal) |
| Critical | 1 (High priority, bypasses quiet hours) |

---

## Security Guarantee

- Claude API key: stored in **Keychain** (`com.danyaczhan.pulsebar` service)
- Pushover credentials: stored in `UserDefaults` (public-safe identifiers)
- Neither key is ever logged, written to disk, or included in crash reports
