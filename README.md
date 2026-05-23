🇷🇺 [Русский](#ru) · 🇬🇧 [English](#en)

---

<a name="ru"></a>

# Система защиты SSH-сервера v28

## Что делает скрипт

Устанавливает автоматическую двухуровневую защиту SSH на Debian-based системах с уведомлениями в Telegram. После установки сервер самостоятельно обнаруживает атаки, блокирует атакующих и сообщает вам об этом в реальном времени.

**Уровень 1 — быстрый бан (fail2ban):** если с одного IP пришло 3 неудачных попытки входа за 10 минут — IP блокируется на 720 часов. В Telegram приходит уведомление с флагом страны.

**Уровень 2 — жёсткий бан (ipset):** если заблокированный IP продолжает ломиться и набирает 10 попыток после бана — он блокируется на уровне ядра на 30 дней. Блокируются все порты, не только SSH.

**Уведомления в Telegram** на каждое событие: бан, предупреждение (6/10 попыток после бана), жёсткий бан, разбан.

---

## Установка

```bash
curl -O https://raw.githubusercontent.com/Oni-Wan-Shinobi/fail2ban-telegram/main/fail2ban-telegram.sh
sudo bash fail2ban-telegram.sh
```

В процессе установки пакетов система один раз спросит про сохранение правил iptables — нажмите **Yes** на оба вопроса:

```
Save current IPv4 rules?
                 <Yes>                <No>

Save current IPv6 rules?
                 <Yes>                <No>
```

Это происходит автоматически при установке пакета `iptables-persistent` и больше не повторяется.

---

Скрипт задаёт 8 вопросов:

**1. Язык интерфейса**
```
Select language / Выберите язык:
  1) English
  2) Русский
> 2
```

**2. Токен Telegram бота**
```
Введите токен Telegram бота (формат: 123456:ABC-DEF...):
> 123456789:AAF-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
Получить у @BotFather командой /newbot. Скрипт автоматически проверяет валидность токена.

**3. Telegram Chat ID**
```
Введите ваш Telegram Chat ID:
> 123456789
```
Узнать свой Chat ID можно у @userinfobot — напишите ему любое сообщение, он ответит вашим ID.

**4. Белый IP (ваш основной адрес)**
```
Введите ваш белый IP (Enter - определить автоматически):
> (Enter)
✅ Автоматически определен IP: 79.139.194.117
```
Нажмите Enter — скрипт определит IP сам. Или введите вручную если знаете. Этот IP никогда не будет заблокирован.

**5. Дополнительный белый IP (резервный)**
```
Введите дополнительный белый IP (Enter - пропустить):
> (Enter)
```
Если подключаетесь с нескольких мест (офис, дом) — введите второй IP. Иначе просто Enter.

**6. Количество попыток до бана**
```
Количество попыток до бана (Enter - 3):
> (Enter)
```
Рекомендуется оставить 3. Меньше — риск заблокировать себя при опечатке.

**7. Отключить аутентификацию по паролю**
```
Отключить аутентификацию по паролю? (y/n, Enter - нет):
> y
```
Если у вас настроены SSH-ключи — введите y (безопаснее). Если нет — оставьте Enter, иначе потеряете доступ.

**8. Отключить вход для root**
```
Отключить вход для root? (y/n, Enter - нет):
> y
```
Если есть отдельный sudo-пользователь — введите y. Если входите только как root — оставьте Enter.

**9. Сменить порт SSH**
```
Сменить порт SSH? (Enter - оставить 22, новый порт):
> (Enter)
```
Нестандартный порт снижает количество сканов. Если меняете — запомните новый порт, иначе потеряете доступ. Рекомендуется 2222–65000.

После ответов на вопросы установка занимает 1–2 минуты и завершается сообщением в Telegram.

---

## Полезные команды после установки

```bash
banned          # список забаненных IP прямо сейчас
f2b-status      # полный статус fail2ban
f2b-ban IP      # заблокировать IP вручную
f2b-unban IP    # разблокировать IP
ban-stages      # лог всех блокировок
hard-banned     # список жёстко заблокированных IPv4
hard-banned6    # список жёстко заблокированных IPv6
monitor-status  # статус сервиса мониторинга
```

---

## Для кого и когда полезен

**Целевая аудитория:** владельцы VPS и выделенных серверов — разработчики, системные администраторы, небольшие команды.

**Когда ставить:**
- Сервер смотрит в интернет по SSH
- Нет специалиста который следит за логами вручную
- Нужна видимость что происходит с сервером без входа на него

Любой публичный сервер получает сотни попыток брутфорса в сутки от автоматических сканеров. Первые баны после установки приходят в течение нескольких минут — это норма.

---

## Плюсы

- **Нулевой порог входа** — один скрипт, 2 минуты, только Ubuntu 22.04 без доп. зависимостей
- **Двойной эшелон защиты** — fail2ban на уровне порта + ipset на уровне ядра
- **Уведомления в реальном времени** — IP, страна с флагом, время, сервер
- **Геолокация без API-ключей** — три бесплатных источника с автоматическим fallback
- **Умный rate limiting** — не спамит при массовой атаке
- **Health check** — таймер каждые 5 минут следит что защита жива
- **Сохранение после перезагрузки** — правила восстанавливаются автоматически

## Минусы

- **Только Debian-based системы** — Ubuntu 20.04/22.04/24.04, Debian 11/12. На CentOS, RHEL, Arch не работает без правок
- **Telegram как единственный канал** — если бот недоступен, уведомления не придут; защита при этом работает
- **Риск заблокировать коллегу** — если несколько раз ошибётся с паролем с нового IP; решается добавлением IP в белый список
- **Не защищает от распределённых атак** — если ботнет бьёт с тысяч IP по одной попытке, fail2ban не сработает

---

## Требования

- Ubuntu 20.04 / 22.04 / 24.04 LTS или Debian 11 / 12
- Root-доступ
- Telegram-бот (создать за 1 минуту у @BotFather)
- Ваш Telegram Chat ID (узнать у @userinfobot)

---

[▲ Наверх](#ru) · 🇬🇧 [English version](#en)

---
---

<a name="en"></a>

# SSH Server Protection System v28

## What the script does

Installs automatic two-layer SSH protection on Debian-based systems with Telegram notifications. Once set up, the server detects attacks on its own, blocks attackers, and reports everything to you in real time.

**Layer 1 — quick ban (fail2ban):** if an IP makes 3 failed login attempts within 10 minutes, it gets blocked for 720 hours. A Telegram notification with the country flag is sent immediately.

**Layer 2 — hard ban (ipset):** if a already-banned IP keeps trying and reaches 10 post-ban attempts, it gets blocked at the kernel level for 30 days. All ports are blocked, not just SSH.

**Telegram notifications** for every event: ban, warning (6/10 post-ban attempts), hard ban, unban.

---

## Installation

```bash
curl -O https://raw.githubusercontent.com/Oni-Wan-Shinobi/fail2ban-telegram/main/fail2ban-telegram.sh
sudo bash fail2ban-telegram.sh
```

During package installation the system will ask once about saving iptables rules — press **Yes** on both prompts:

```
Save current IPv4 rules?
                 <Yes>                <No>

Save current IPv6 rules?
                 <Yes>                <No>
```

This happens automatically when `iptables-persistent` is installed and won't appear again.

---

The script asks 9 questions:

**1. Interface language**
```
Select language / Выберите язык:
  1) English
  2) Русский
> 1
```

**2. Telegram bot token**
```
Enter Telegram bot token (format: 123456:ABC-DEF...):
> 123456789:AAF-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
Get it from @BotFather with /newbot. The script validates the token automatically.

**3. Telegram Chat ID**
```
Enter your Telegram Chat ID:
> 123456789
```
Find your Chat ID via @userinfobot — send it any message and it will reply with your ID.

**4. Whitelisted IP (your main address)**
```
Enter your whitelisted IP (Enter - detect automatically):
> (Enter)
✅ Automatically detected IP: 79.139.194.117
```
Press Enter and the script detects it automatically. Or enter it manually if you know it. This IP will never be blocked.

**5. Additional whitelisted IP (backup)**
```
Enter additional whitelisted IP (Enter - skip):
> (Enter)
```
If you connect from multiple places (office, home) — enter a second IP. Otherwise just press Enter.

**6. Number of attempts before ban**
```
Number of attempts before ban (Enter - 3):
> (Enter)
```
Recommended to keep at 3. Lower values increase the risk of locking yourself out with a typo.

**7. Disable password authentication**
```
Disable password authentication? (y/n, Enter - no):
> y
```
If you have SSH keys configured — enter y (more secure). If not — press Enter, otherwise you'll lose access.

**8. Disable root login**
```
Disable root login? (y/n, Enter - no):
> y
```
If you have a separate sudo user — enter y. If you only log in as root — press Enter.

**9. Change SSH port**
```
Change SSH port? (Enter - keep 22, or enter new port):
> (Enter)
```
A non-standard port reduces the number of scans. If you change it — remember the new port, otherwise you'll lose access. Recommended range: 2222–65000.

After answering all questions, installation takes 1–2 minutes and ends with a Telegram message.

---

## Useful commands after installation

```bash
banned          # list of currently banned IPs
f2b-status      # full fail2ban status
f2b-ban IP      # manually ban an IP
f2b-unban IP    # unban an IP
ban-stages      # log of all bans
hard-banned     # list of hard-banned IPv4 addresses
hard-banned6    # list of hard-banned IPv6 addresses
monitor-status  # monitoring service status
```

---

## Who it's for and when to use it

**Target audience:** VPS and dedicated server owners — developers, sysadmins, small teams.

**When to install:**
- Your server is publicly accessible via SSH
- You don't have a specialist monitoring logs manually
- You want visibility into what's happening on the server without logging in

Any public server receives hundreds of brute-force attempts per day from automated scanners. The first bans after installation arrive within minutes — that's normal.

---

## Pros

- **Zero entry threshold** — one script, 2 minutes, Ubuntu 22.04 only, no extra dependencies
- **Double-layer protection** — fail2ban at the port level + ipset at the kernel level
- **Real-time notifications** — IP, country with flag, timestamp, server name
- **Geolocation without API keys** — three free sources with automatic fallback
- **Smart rate limiting** — doesn't spam during mass attacks
- **Health check** — a timer every 5 minutes verifies the protection is alive
- **Persistence across reboots** — rules are restored automatically

## Cons

- **Debian-based systems only** — Ubuntu 20.04/22.04/24.04, Debian 11/12. Doesn't work on CentOS, RHEL, or Arch without modifications
- **Telegram as the only channel** — if the bot is unavailable, notifications won't arrive; protection still works
- **Risk of blocking a colleague** — if they fail the password several times from a new IP; solved by adding their IP to the whitelist
- **No protection against distributed attacks** — if a botnet hits from thousands of IPs with one attempt each, fail2ban won't trigger

---

## Requirements

- Ubuntu 20.04 / 22.04 / 24.04 LTS or Debian 11 / 12
- Root access
- A Telegram bot (create in 1 minute via @BotFather)
- Your Telegram Chat ID (get it from @userinfobot)

---

[▲ Top](#en) · 🇷🇺 [Русская версия](#ru)
