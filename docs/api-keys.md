<div align="center">

# API Keys Setup

[English](#english) · [Русский](#русский)

</div>

---

## English

PulseBar integrates with two external services, both optional and opt-in.

### Claude AI — Anomaly Analysis

The AI analysis feature sends a snapshot of recent metrics to Anthropic Claude and returns a 2-sentence insight.

**Setup**

1. Go to [console.anthropic.com](https://console.anthropic.com) and create an account
2. Navigate to **API Keys** → **Create Key**
3. Copy the key (begins with `sk-ant-…`)
4. In PulseBar: **Settings → Alerts → AI Analysis → API Key**
5. Paste the key — it is immediately stored in the macOS Keychain

The key is never written to disk, logged, or included in crash reports.

**What is sent**

```
CPU temp: avg 62°C, peak 78°C
CPU load: avg 45%, peak 82%
RAM: 8.3 GB
Top process: Xcode at 68% CPU
Anomalies detected: sustained high CPU load
```

No personal information. No device identifiers. Snapshot only.

**Pricing**

Anthropic provides approximately $5 in free credit on signup — sufficient for hundreds of analyses. Responses are capped at 200 tokens.

**Model**: `claude-sonnet-4-20250514`

---

### Pushover — iPhone Push Notifications

Pushover delivers PulseBar alerts to your iPhone, iPad, or Apple Watch as native push notifications.

**Setup**

1. Go to [pushover.net](https://pushover.net) and create an account ($5 one-time, 30-day free trial)
2. Your **User Key** is displayed on the dashboard
3. Go to **Your Applications** → **Create an Application** → name it "PulseBar"
4. Copy the **App Token**
5. In PulseBar: **Settings → Network → iPhone Push**
6. Enter your User Key and App Token → tap **Test Push**

**Notification format**

```
PulseBar: CPU Temp 91°C
Sustained for 2m 15s. Xcode is using 94% CPU.
```

**Priority**

| Severity | Pushover Priority |
|----------|------------------|
| Warning | Normal (0) |
| Critical | High (1) — bypasses quiet hours |

---

## Русский

PulseBar интегрируется с двумя внешними сервисами — оба опциональны и включаются вручную.

### Claude AI — анализ аномалий

Функция AI-анализа отправляет снимок недавних метрик в Anthropic Claude и возвращает краткое наблюдение.

**Настройка**

1. Перейдите на [console.anthropic.com](https://console.anthropic.com) и создайте аккаунт
2. Перейдите в **API Keys** → **Create Key**
3. Скопируйте ключ (начинается с `sk-ant-…`)
4. В PulseBar: **Настройки → Alerts → AI Analysis → API Key**
5. Вставьте ключ — он сразу сохраняется в macOS Keychain

Ключ никогда не записывается на диск, не логируется и не попадает в отчёты о сбоях.

**Что передаётся**

```
Температура CPU: среднее 62°C, пик 78°C
Загрузка CPU: среднее 45%, пик 82%
RAM: 8,3 ГБ
Топ-процесс: Xcode — 68% CPU
Обнаруженные аномалии: устойчивая высокая нагрузка CPU
```

Никакой личной информации. Никаких идентификаторов устройства. Только снимок метрик.

**Стоимость**

Anthropic предоставляет около $5 бесплатного кредита при регистрации — хватает на сотни анализов. Ответы ограничены 200 токенами.

**Модель**: `claude-sonnet-4-20250514`

---

### Pushover — push-уведомления на iPhone

Pushover доставляет алерты PulseBar на ваш iPhone, iPad или Apple Watch как нативные уведомления.

**Настройка**

1. Зайдите на [pushover.net](https://pushover.net) и создайте аккаунт ($5 единоразово, 30-дневный пробный период)
2. **User Key** отображается на главной странице
3. Перейдите в **Your Applications** → **Create an Application** → назовите "PulseBar"
4. Скопируйте **App Token**
5. В PulseBar: **Настройки → Network → iPhone Push**
6. Введите User Key и App Token → нажмите **Test Push**

**Формат уведомления**

```
PulseBar: Температура CPU 91°C
Держится 2 мин 15 сек. Xcode использует 94% CPU.
```

**Приоритет**

| Серьёзность | Приоритет Pushover |
|-------------|------------------|
| Предупреждение | Обычный (0) |
| Критический | Высокий (1) — обходит режим «Не беспокоить» |
