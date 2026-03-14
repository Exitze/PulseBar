<div align="center">

# Security Policy

[English](#english) · [Русский](#русский)

</div>

---

## English

### Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x.x   | Yes       |

### Reporting a Vulnerability

Do not open a public GitHub issue for security vulnerabilities.

**Preferred channel**: [GitHub Security Advisories](https://github.com/Exitze/PulseBar/security/advisories/new)

Include in your report:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (optional)

**Response timeline**: acknowledgement within 48 hours, patch within 7 days for critical issues.

### Security Design

**API keys and credentials**

All sensitive credentials are stored in the macOS Keychain via `Security.framework`. Nothing sensitive is written to disk, UserDefaults, or log files.

| Credential | Storage |
|------------|---------|
| Claude API key | macOS Keychain |
| Pushover User Key | UserDefaults (non-sensitive identifier) |
| Pushover App Token | UserDefaults (non-sensitive identifier) |

**Data privacy**

PulseBar does not collect telemetry, analytics, or crash reports. No data leaves your machine except:

| Feature | Data sent | Trigger |
|---------|-----------|---------|
| AI Analysis | CPU/RAM/process snapshot | User-initiated |
| Push notifications | Alert title and body | Threshold crossed |
| Ping check | HTTPS HEAD to captive.apple.com | Every N seconds |

**System access**

The app runs unsandboxed — required for IOKit SMC reads and process monitoring. No private APIs are used. Process termination uses `SIGTERM` only (graceful quit).

---

## Русский

### Поддерживаемые версии

| Версия | Поддержка |
|--------|-----------|
| 1.x.x  | Да        |

### Сообщить об уязвимости

Не открывайте публичный GitHub Issue для уязвимостей безопасности.

**Предпочтительный канал**: [GitHub Security Advisories](https://github.com/Exitze/PulseBar/security/advisories/new)

Укажите в сообщении:
- Описание уязвимости
- Шаги воспроизведения
- Потенциальное воздействие
- Предлагаемое исправление (необязательно)

**Сроки ответа**: подтверждение в течение 48 часов, патч в течение 7 дней для критических проблем.

### Архитектура безопасности

**API-ключи и учётные данные**

Все чувствительные данные хранятся в macOS Keychain через `Security.framework`. Ничего чувствительного не записывается на диск, в UserDefaults или в лог-файлы.

| Данные | Хранилище |
|--------|-----------|
| Ключ Claude API | macOS Keychain |
| Pushover User Key | UserDefaults (публичный идентификатор) |
| Pushover App Token | UserDefaults (публичный идентификатор) |

**Конфиденциальность данных**

PulseBar не собирает телеметрию, аналитику или отчёты о сбоях. Данные не покидают ваш Mac, кроме:

| Функция | Передаваемые данные | Когда |
|---------|--------------------|----|
| AI-анализ | Снимок CPU/RAM/процессов | По инициативе пользователя |
| Push-уведомления | Заголовок и текст алерта | При превышении порога |
| Проверка пинга | HTTPS HEAD на captive.apple.com | Каждые N секунд |

**Системный доступ**

Приложение работает без песочницы — это необходимо для чтения SMC через IOKit и мониторинга процессов. Приватные API не используются. Завершение процессов — только через `SIGTERM` (мягкое завершение).
