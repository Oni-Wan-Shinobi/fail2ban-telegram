#!/bin/bash

# ============================================
# Универсальный установщик защиты сервера (v28 - Production Final)
# ============================================

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  SSH Brute-Force Protection v28${NC}"
echo -e "${GREEN}========================================${NC}"

# Выбор языка / Language selection
echo ""
echo -e "${BLUE}Select language / Выберите язык:${NC}"
echo "  1) English"
echo "  2) Русский"
read -r LANG_CHOICE
if [[ "$LANG_CHOICE" == "2" ]]; then
    LANG="ru"
else
    LANG="en"
fi

# Строки интерфейса / UI strings
if [ "$LANG" = "ru" ]; then
    T_HEADER="Установка системы защиты сервера v28"
    T_ENTER_TOKEN="Введите токен Telegram бота (формат: 123456:ABC-DEF...):"
    T_CHECKING_TOKEN="Проверка токена..."
    T_TOKEN_OK="✅ Токен валиден"
    T_TOKEN_BAD_FORMAT="Ошибка: неверный формат токена!"
    T_TOKEN_INVALID="Ошибка: токен недействителен!"
    T_ENTER_CHATID="Введите ваш Telegram Chat ID:"
    T_CHATID_BAD="Ошибка: Chat ID должен быть числом!"
    T_ENTER_IP="Введите ваш белый IP (Enter - определить автоматически):"
    T_IP_AUTO="Автоматически определён IP:"
    T_IP_FAIL="Ошибка: не удалось определить публичный IP!"
    T_ENTER_EXTRA_IP="Введите дополнительный белый IP (Enter - пропустить):"
    T_EXTRA_IP_ADDED="Добавлен резервный IP:"
    T_EXTRA_IP_BAD="Неверный формат, пропускаем"
    T_ENTER_RETRY="Количество попыток до бана (Enter - 3):"
    T_RETRY_BAD="Некорректное значение, используем 3"
    T_DISABLE_PASSWORD="Отключить аутентификацию по паролю? (y/n, Enter - нет):"
    T_PASSWORD_DISABLED="✅ Аутентификация по паролю отключена"
    T_DISABLE_ROOT="Отключить вход для root? (y/n, Enter - нет):"
    T_ROOT_DISABLED="✅ Вход для root отключён"
    T_CHANGE_PORT="Сменить порт SSH? (Enter - оставить 22, новый порт):"
    T_PORT_FREE="Порт свободен"
    T_PORT_BUSY="Ошибка: порт уже занят! Оставляем порт 22"
    T_STARTING="Начинаю установку..."
    T_SSH_OK="✅ SSH конфиг валиден и применён"
    T_SSH_FAIL="❌ Ошибка в конфиге SSH! Откат изменений..."
    T_SSH_RESTORED="⚠️ SSH конфиг восстановлен из бэкапа. Установка прервана."
    T_ALIASES_OK="✅ Алиасы добавлены"
    T_TG_OK="✅ Тестовое сообщение отправлено"
    T_TG_FAIL="⚠️ Не удалось отправить тестовое сообщение. Проверьте токен и Chat ID."
    T_DONE="УСТАНОВКА ЗАВЕРШЕНА!"
    T_PORT_CHANGED="⚠️ SSH порт изменён на"
    T_CONNECT="Подключайтесь:"
    T_PASSWORD_WARNING="⚠️ Аутентификация по паролю ОТКЛЮЧЕНА"
    T_KEY_SETUP="Убедитесь, что SSH ключ настроен:"
    T_ROOT_WARNING="⚠️ Вход для root ОТКЛЮЧЁН"
    T_ROOT_USE_SUDO="Используйте sudo:"
    T_COMMANDS="Полезные команды:"
else
    T_HEADER="SSH Brute-Force Protection Installer v28"
    T_ENTER_TOKEN="Enter Telegram bot token (format: 123456:ABC-DEF...):"
    T_CHECKING_TOKEN="Checking token..."
    T_TOKEN_OK="✅ Token is valid"
    T_TOKEN_BAD_FORMAT="Error: invalid token format!"
    T_TOKEN_INVALID="Error: token is invalid!"
    T_ENTER_CHATID="Enter your Telegram Chat ID:"
    T_CHATID_BAD="Error: Chat ID must be a number!"
    T_ENTER_IP="Enter your whitelisted IP (Enter - detect automatically):"
    T_IP_AUTO="Automatically detected IP:"
    T_IP_FAIL="Error: could not detect public IP!"
    T_ENTER_EXTRA_IP="Enter additional whitelisted IP (Enter - skip):"
    T_EXTRA_IP_ADDED="Added backup IP:"
    T_EXTRA_IP_BAD="Invalid format, skipping"
    T_ENTER_RETRY="Failed attempts before ban (Enter - 3):"
    T_RETRY_BAD="Invalid value, using 3"
    T_DISABLE_PASSWORD="Disable password authentication? (y/n, Enter - no):"
    T_PASSWORD_DISABLED="✅ Password authentication disabled"
    T_DISABLE_ROOT="Disable root login? (y/n, Enter - no):"
    T_ROOT_DISABLED="✅ Root login disabled"
    T_CHANGE_PORT="Change SSH port? (Enter - keep 22, or enter new port):"
    T_PORT_FREE="Port is available"
    T_PORT_BUSY="Error: port already in use! Keeping port 22"
    T_STARTING="Starting installation..."
    T_SSH_OK="✅ SSH config is valid and applied"
    T_SSH_FAIL="❌ SSH config error! Rolling back..."
    T_SSH_RESTORED="⚠️ SSH config restored from backup. Installation aborted."
    T_ALIASES_OK="✅ Aliases added"
    T_TG_OK="✅ Test message sent"
    T_TG_FAIL="⚠️ Could not send test message. Check token and Chat ID."
    T_DONE="INSTALLATION COMPLETE!"
    T_PORT_CHANGED="⚠️ SSH port changed to"
    T_CONNECT="Connect using:"
    T_PASSWORD_WARNING="⚠️ Password authentication is DISABLED"
    T_KEY_SETUP="Make sure your SSH key is configured:"
    T_ROOT_WARNING="⚠️ Root login is DISABLED"
    T_ROOT_USE_SUDO="Use sudo:"
    T_COMMANDS="Useful commands:"
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ${T_HEADER}${NC}"
echo -e "${GREEN}========================================${NC}"

# Конфигурация
MAX_HARD_ATTEMPTS=10
STORAGE_DIR="/var/lib/ssh-monitor"
LIB_DIR="/usr/local/lib/ssh-monitor"
ENV_FILE="/etc/ssh-telegram/.env"
LOG_FILE="/var/log/two-stage-ban.log"
IPSET_FILE="/etc/iptables/ipsets"
TG_RATE_LIMIT=60

# Функции для установщика
validate_ipv4() {
    local ip="$1"
    if [[ "$ip" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]]; then
        for octet in 1 2 3 4; do
            [ "${BASH_REMATCH[$octet]}" -gt 255 ] && return 1
        done
        return 0
    fi
    return 1
}

validate_ipv6() {
    local ip="$1"
    if [[ "$ip" =~ ^([0-9a-f]{1,4}:){0,7}[0-9a-f]{1,4}$ ]] || \
       [[ "$ip" =~ ^([0-9a-f]{1,4}:){1,7}:$ ]] || \
       [[ "$ip" =~ ^::([0-9a-f]{1,4}:){0,6}[0-9a-f]{1,4}$ ]]; then
        return 0
    fi
    if [[ "$ip" =~ ^::ffff:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        local ipv4="${ip#::ffff:}"
        validate_ipv4 "$ipv4" && return 0
    fi
    return 1
}

is_private_ip() {
    local ip="$1"
    [[ "$ip" =~ ^10\. ]] || [[ "$ip" =~ ^172\.1[6-9]\. ]] || [[ "$ip" =~ ^172\.2[0-9]\. ]] || \
    [[ "$ip" =~ ^172\.3[0-1]\. ]] || [[ "$ip" =~ ^192\.168\. ]] || [[ "$ip" =~ ^100\.6[4-9]\. ]] || \
    [[ "$ip" =~ ^100\.[7-9][0-9]\. ]] || [[ "$ip" =~ ^100\.1[0-1][0-9]\. ]] || [[ "$ip" =~ ^100\.12[0-7]\. ]]
}

validate_bot_token() {
    [[ "$1" =~ ^[0-9]+:[a-zA-Z0-9_-]+$ ]]
}

check_port_available() {
    local port="$1"
    if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
        return 1
    fi
    return 0
}

# Ввод данных
echo ""
echo -e "${BLUE}${T_ENTER_TOKEN}${NC}"
read -r BOT_TOKEN
if ! validate_bot_token "$BOT_TOKEN"; then
    echo -e "${RED}${T_TOKEN_BAD_FORMAT}${NC}"
    exit 1
fi

echo -e "${BLUE}${T_CHECKING_TOKEN}${NC}"
if ! curl -s --max-time 10 "https://api.telegram.org/bot${BOT_TOKEN}/getMe" | grep -q '"ok":true'; then
    echo -e "${RED}${T_TOKEN_INVALID}${NC}"
    exit 1
fi
echo -e "${GREEN}${T_TOKEN_OK}${NC}"

echo -e "${BLUE}${T_ENTER_CHATID}${NC}"
read -r CHAT_ID
if [[ ! "$CHAT_ID" =~ ^-?[0-9]+$ ]]; then
    echo -e "${RED}${T_CHATID_BAD}${NC}"
    exit 1
fi

echo -e "${BLUE}${T_ENTER_IP}${NC}"
read -r WHITE_IP
if [ -z "$WHITE_IP" ]; then
    WHITE_IP=$(curl -s --max-time 10 -4 ifconfig.me)
    if ! validate_ipv4 "$WHITE_IP" || is_private_ip "$WHITE_IP"; then
        echo -e "${RED}${T_IP_FAIL}${NC}"
        exit 1
    fi
    echo -e "${GREEN}${T_IP_AUTO} $WHITE_IP${NC}"
fi

echo -e "${BLUE}${T_ENTER_EXTRA_IP}${NC}"
read -r EXTRA_IP
if [ -n "$EXTRA_IP" ]; then
    if validate_ipv4 "$EXTRA_IP" && ! is_private_ip "$EXTRA_IP"; then
        WHITE_IP="$WHITE_IP $EXTRA_IP"
        echo -e "${GREEN}${T_EXTRA_IP_ADDED} $EXTRA_IP${NC}"
    else
        echo -e "${RED}${T_EXTRA_IP_BAD}${NC}"
    fi
fi

echo -e "${BLUE}${T_ENTER_RETRY}${NC}"
read -r MAX_RETRY
if [ -z "$MAX_RETRY" ]; then
    MAX_RETRY=3
elif [[ ! "$MAX_RETRY" =~ ^[0-9]+$ ]] || [ "$MAX_RETRY" -lt 1 ]; then
    echo -e "${YELLOW}${T_RETRY_BAD}${NC}"
    MAX_RETRY=3
fi

echo -e "${BLUE}${T_DISABLE_PASSWORD}${NC}"
read -r DISABLE_PASSWORD
if [[ "$DISABLE_PASSWORD" =~ ^[Yy]$ ]]; then
    DISABLE_PASSWORD="yes"
else
    DISABLE_PASSWORD="no"
fi

echo -e "${BLUE}${T_DISABLE_ROOT}${NC}"
read -r DISABLE_ROOT
if [[ "$DISABLE_ROOT" =~ ^[Yy]$ ]]; then
    DISABLE_ROOT="yes"
else
    DISABLE_ROOT="no"
fi

echo -e "${BLUE}${T_CHANGE_PORT}${NC}"
read -r NEW_SSH_PORT
if [ -n "$NEW_SSH_PORT" ] && [[ "$NEW_SSH_PORT" =~ ^[0-9]+$ ]] && [ "$NEW_SSH_PORT" -gt 1024 ] && [ "$NEW_SSH_PORT" -lt 65535 ]; then
    if check_port_available "$NEW_SSH_PORT"; then
        CHANGE_PORT=true
        echo -e "${GREEN}${T_PORT_FREE}${NC}"
    else
        echo -e "${RED}${T_PORT_BUSY}${NC}"
        CHANGE_PORT=false
        NEW_SSH_PORT="22"
    fi
else
    CHANGE_PORT=false
    NEW_SSH_PORT="22"
fi

echo ""
echo -e "${YELLOW}${T_STARTING}${NC}"

# 1. Установка пакетов
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[1/25] Установка пакетов..." || echo "[1/25] Installing packages...")${NC}"
sudo apt update
sudo apt install -y fail2ban curl jq iptables-persistent rsyslog ipset

# 2. Создание директорий
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[2/25] Создание директорий..." || echo "[2/25] Creating directories...")${NC}"
sudo mkdir -p "$STORAGE_DIR" "$LIB_DIR"
sudo mkdir -p /etc/ssh-telegram
sudo mkdir -p /etc/fail2ban/action.d
sudo mkdir -p /etc/fail2ban/jail.d
sudo mkdir -p /etc/iptables
sudo chmod 755 "$LIB_DIR"
sudo chmod 750 "$STORAGE_DIR"
sudo chmod 750 /etc/ssh-telegram

# 3. Создание пользователя для сервиса
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[3/25] Создание пользователя для мониторинга..." || echo "[3/25] Creating monitor user...")${NC}"
if ! id "ssh-monitor" &>/dev/null; then
    sudo useradd -r -s /usr/sbin/nologin -d "$STORAGE_DIR" ssh-monitor
fi
sudo usermod -aG systemd-journal ssh-monitor
sudo chown -R ssh-monitor:ssh-monitor "$STORAGE_DIR"

# 4. Настройка sudoers для ssh-monitor
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[4/25] Настройка sudoers..." || echo "[4/25] Configuring sudoers...")${NC}"
sudo tee /etc/sudoers.d/ssh-monitor > /dev/null << 'EOF'
# Права для мониторинга Fail2Ban
ssh-monitor ALL=(ALL) NOPASSWD: /usr/bin/fail2ban-client status sshd-instant
EOF
sudo chmod 440 /etc/sudoers.d/ssh-monitor

# 5. SSH HARDENING с проверкой конфига
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[5/25] Настройка безопасности SSH..." || echo "[5/25] Hardening SSH...")${NC}"
BACKUP_FILE="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"
sudo cp /etc/ssh/sshd_config "$BACKUP_FILE"

if [ "$DISABLE_PASSWORD" = "yes" ]; then
    sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    echo -e "${GREEN}${T_PASSWORD_DISABLED}${NC}"
fi

if [ "$DISABLE_ROOT" = "yes" ]; then
    sudo sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    echo -e "${GREEN}${T_ROOT_DISABLED}${NC}"
fi

sudo sed -i 's/^#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config
sudo sed -i 's/^MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sudo sed -i 's/^#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sudo sed -i 's/^PermitEmptyPasswords yes/PermitEmptyPasswords no/' /etc/ssh/sshd_config

# Валидация SSH конфига перед применением
if ! sudo sshd -t; then
    echo -e "${RED}${T_SSH_FAIL}${NC}"
    sudo cp "$BACKUP_FILE" /etc/ssh/sshd_config
    sudo systemctl reload sshd
    echo -e "${RED}${T_SSH_RESTORED}${NC}"
    exit 1
fi
sudo systemctl reload sshd
echo -e "${GREEN}${T_SSH_OK}${NC}"

# 6. Смена порта SSH с проверкой
if [ "$CHANGE_PORT" = true ]; then
    echo -e "${GREEN}[6/25] Смена порта SSH на $NEW_SSH_PORT...${NC}"
    sudo sed -i "s/^#Port 22/Port $NEW_SSH_PORT/" /etc/ssh/sshd_config
    sudo sed -i "s/^Port 22/Port $NEW_SSH_PORT/" /etc/ssh/sshd_config
    
    if sudo sshd -t; then
        sudo systemctl restart sshd
        echo -e "${GREEN}✅ Порт SSH изменён на $NEW_SSH_PORT${NC}"
    else
        echo -e "${RED}❌ Ошибка в конфиге SSH! Откат...${NC}"
        sudo sed -i "s/^Port $NEW_SSH_PORT/Port 22/" /etc/ssh/sshd_config
        sudo systemctl restart sshd
        CHANGE_PORT=false
        NEW_SSH_PORT="22"
    fi
fi

# 7. Настройка ipset
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[7/25] Настройка ipset..." || echo "[7/25] Configuring ipset...")${NC}"
sudo ipset create ssh-hardbans hash:ip timeout 2592000 2>/dev/null || true
sudo ipset create ssh-hardbans6 hash:ip family inet6 timeout 2592000 2>/dev/null || true
sudo ipset save > "$IPSET_FILE" 2>/dev/null || true

# 8. Правила iptables
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[8/25] Настройка iptables..." || echo "[8/25] Configuring iptables...")${NC}"
sudo iptables -I INPUT -m set --match-set ssh-hardbans src -j DROP 2>/dev/null || true
sudo iptables -I FORWARD -m set --match-set ssh-hardbans src -j DROP 2>/dev/null || true
sudo ip6tables -I INPUT -m set --match-set ssh-hardbans6 src -j DROP 2>/dev/null || true
sudo ip6tables -I FORWARD -m set --match-set ssh-hardbans6 src -j DROP 2>/dev/null || true

# 9. .env файл
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[9/25] Создание конфигурации..." || echo "[9/25] Creating configuration...")${NC}"
sudo tee "$ENV_FILE" > /dev/null << EOF
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
HOSTNAME="$(hostname)"
MAX_RETRY="$MAX_RETRY"
MAX_HARD_ATTEMPTS="$MAX_HARD_ATTEMPTS"
LOG_FILE="$LOG_FILE"
STORAGE_DIR="$STORAGE_DIR"
IPSET_FILE="$IPSET_FILE"
TG_RATE_LIMIT="$TG_RATE_LIMIT"
SSH_PORT="$NEW_SSH_PORT"
NOTIFY_LANG="$LANG"
EOF
sudo chmod 600 "$ENV_FILE"
sudo chown root:ssh-monitor "$ENV_FILE"
sudo chmod 640 "$ENV_FILE"
sudo chown root:ssh-monitor /etc/ssh-telegram
sudo chmod 750 /etc/ssh-telegram

# 10. Библиотека common.sh
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[10/25] Создание библиотеки функций..." || echo "[10/25] Creating function library...")${NC}"
sudo tee "$LIB_DIR/common.sh" > /dev/null << 'EOF'
#!/bin/bash
validate_ipv4() { [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && [ $(echo "$1" | cut -d. -f1) -le 255 ] && [ $(echo "$1" | cut -d. -f2) -le 255 ] && [ $(echo "$1" | cut -d. -f3) -le 255 ] && [ $(echo "$1" | cut -d. -f4) -le 255 ]; }
validate_ipv6() {
    local ip="$1"
    if [[ "$ip" =~ ^([0-9a-f]{1,4}:){0,7}[0-9a-f]{1,4}$ ]] || [[ "$ip" =~ ^([0-9a-f]{1,4}:){1,7}:$ ]] || [[ "$ip" =~ ^::([0-9a-f]{1,4}:){0,6}[0-9a-f]{1,4}$ ]]; then return 0; fi
    if [[ "$ip" =~ ^::ffff:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then local ipv4="${ip#::ffff:}"; validate_ipv4 "$ipv4" && return 0; fi
    return 1
}
is_private_ip() { [[ "$1" =~ ^10\. ]] || [[ "$1" =~ ^172\.1[6-9]\. ]] || [[ "$1" =~ ^172\.2[0-9]\. ]] || [[ "$1" =~ ^172\.3[0-1]\. ]] || [[ "$1" =~ ^192\.168\. ]] || [[ "$1" =~ ^100\.6[4-9]\. ]] || [[ "$1" =~ ^100\.[7-9][0-9]\. ]] || [[ "$1" =~ ^100\.1[0-1][0-9]\. ]] || [[ "$1" =~ ^100\.12[0-7]\. ]]; }
is_localhost() { [[ "$1" == "::1" ]] || [[ "$1" == "127.0.0.1" ]] || [[ "$1" == "localhost" ]]; }
escape_markdown() { printf '%s' "$1" | sed 's/_/\\_/g; s/\*/\\*/g; s/\[/\\[/g; s/\]/\\]/g'; }
COUNTRY_CACHE_DIR=""
init_country_cache() { COUNTRY_CACHE_DIR="$1"; mkdir -p "$COUNTRY_CACHE_DIR"; }
is_valid_country() { [[ "$1" =~ ^[A-Z]{2}$ ]]; }
country_flag() {
    case "$1" in
        CN) echo "🇨🇳 CN" ;; RU) echo "🇷🇺 RU" ;; US) echo "🇺🇸 US" ;;
        DE) echo "🇩🇪 DE" ;; NL) echo "🇳🇱 NL" ;; FR) echo "🇫🇷 FR" ;;
        GB) echo "🇬🇧 GB" ;; BR) echo "🇧🇷 BR" ;; IN) echo "🇮🇳 IN" ;;
        KR) echo "🇰🇷 KR" ;; JP) echo "🇯🇵 JP" ;; VN) echo "🇻🇳 VN" ;;
        ID) echo "🇮🇩 ID" ;; TR) echo "🇹🇷 TR" ;; UA) echo "🇺🇦 UA" ;;
        HK) echo "🇭🇰 HK" ;; SG) echo "🇸🇬 SG" ;; TW) echo "🇹🇼 TW" ;;
        PL) echo "🇵🇱 PL" ;; IR) echo "🇮🇷 IR" ;; TH) echo "🇹🇭 TH" ;;
        AU) echo "🇦🇺 AU" ;; CA) echo "🇨🇦 CA" ;; IT) echo "🇮🇹 IT" ;;
        ES) echo "🇪🇸 ES" ;; RO) echo "🇷🇴 RO" ;; BG) echo "🇧🇬 BG" ;;
        PK) echo "🇵🇰 PK" ;; BD) echo "🇧🇩 BD" ;; MX) echo "🇲🇽 MX" ;;
        *) echo "🌍 $1" ;;
    esac
}
get_country() {
    local ip="$1"
    if [ -z "$COUNTRY_CACHE_DIR" ]; then echo "Неизвестно"; return; fi
    local cache_file="${COUNTRY_CACHE_DIR}/country-${ip}"
    if is_localhost "$ip" || ! (validate_ipv4 "$ip" || validate_ipv6 "$ip"); then echo "Локальный"; return; fi
    if [ -f "$cache_file" ]; then
        local cache_age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
        if [ "$cache_age" -lt 86400 ]; then cat "$cache_file"; return; fi
    fi
    local country=""
    country=$(curl -s --max-time 5 "https://ipapi.co/${ip}/country/" 2>/dev/null)
    is_valid_country "$country" || country=""
    if [ -z "$country" ]; then
        country=$(curl -s --max-time 5 "https://ip2c.org/${ip}" 2>/dev/null | cut -d';' -f2)
        is_valid_country "$country" || country=""
    fi
    if [ -z "$country" ]; then
        country=$(curl -s --max-time 5 "https://ipinfo.io/${ip}/country" 2>/dev/null | tr -d '\n')
        is_valid_country "$country" || country=""
    fi
    [ -z "$country" ] && country="Неизвестно"
    local display; display="$(country_flag "$country")"
    echo "$display" > "$cache_file"
    echo "$display"
}
load_config() {
    if [ ! -f /etc/ssh-telegram/.env ]; then return 1; fi
    local owner=$(stat -c %u /etc/ssh-telegram/.env 2>/dev/null)
    local mode=$(stat -c %a /etc/ssh-telegram/.env 2>/dev/null)
    if [ "$owner" != "0" ] || [ "${mode:2:1}" != "0" ]; then echo "ERROR: insecure .env" >&2; return 1; fi
    BOT_TOKEN=$(grep '^BOT_TOKEN=' /etc/ssh-telegram/.env | cut -d'"' -f2)
    CHAT_ID=$(grep '^CHAT_ID=' /etc/ssh-telegram/.env | cut -d'"' -f2)
    HOSTNAME=$(grep '^HOSTNAME=' /etc/ssh-telegram/.env | cut -d'"' -f2)
    MAX_HARD_ATTEMPTS=$(grep '^MAX_HARD_ATTEMPTS=' /etc/ssh-telegram/.env | cut -d'"' -f2)
    LOG_FILE=$(grep '^LOG_FILE=' /etc/ssh-telegram/.env | cut -d'"' -f2)
    STORAGE_DIR=$(grep '^STORAGE_DIR=' /etc/ssh-telegram/.env | cut -d'"' -f2)
    IPSET_FILE=$(grep '^IPSET_FILE=' /etc/ssh-telegram/.env | cut -d'"' -f2)
    TG_RATE_LIMIT=$(grep '^TG_RATE_LIMIT=' /etc/ssh-telegram/.env | cut -d'"' -f2)
    [ -z "$MAX_HARD_ATTEMPTS" ] && MAX_HARD_ATTEMPTS=10
    [ -z "$LOG_FILE" ] && LOG_FILE="/var/log/two-stage-ban.log"
    [ -z "$STORAGE_DIR" ] && STORAGE_DIR="/var/lib/ssh-monitor"
    [ -z "$IPSET_FILE" ] && IPSET_FILE="/etc/iptables/ipsets"
    [ -z "$TG_RATE_LIMIT" ] && TG_RATE_LIMIT=60
    NOTIFY_LANG=$(grep '^NOTIFY_LANG=' /etc/ssh-telegram/.env | cut -d'"' -f2)
    [ -z "$NOTIFY_LANG" ] && NOTIFY_LANG="en"
    init_country_cache "$STORAGE_DIR"
    return 0
}
declare -A LAST_TG_NOTIFY
is_tg_rate_limited() { local ip="$1"; local now=$(date +%s); local last=${LAST_TG_NOTIFY[$ip]:-0}; if [ $((now - last)) -lt ${TG_RATE_LIMIT:-60} ]; then return 0; fi; LAST_TG_NOTIFY[$ip]=$now; return 1; }
send_telegram() {
    local message="$1"; local bot_token="$2"; local chat_id="$3"; local log_file="$4"; local ip="$5"
    if is_tg_rate_limited "$ip"; then echo "$(date): TG rate limited for $ip" >> "$log_file"; return 0; fi
    local text_escaped
    text_escaped=$(printf '%s' "$message" | sed 's/\\/\\\\/g; s/"/\\"/g')
    local payload="{\"chat_id\":\"${chat_id}\",\"text\":\"${text_escaped}\",\"parse_mode\":\"Markdown\"}"
    ( exec curl -s --max-time 10 -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
        -H "Content-Type: application/json" -d "$payload" > /dev/null 2>&1 )
    echo "$(date): TG send for $ip - exit code $?" >> "$log_file"
}
hard_ban_ip() { local ip="$1"; local ipsets_file="${2:-/etc/iptables/ipsets}"; if validate_ipv6 "$ip" && [[ "$ip" != "::1" ]]; then ipset add ssh-hardbans6 "$ip" timeout 2592000 2>/dev/null; ipset test ssh-hardbans6 "$ip" 2>/dev/null || return 1; elif validate_ipv4 "$ip" && ! is_private_ip "$ip"; then ipset add ssh-hardbans "$ip" timeout 2592000 2>/dev/null; ipset test ssh-hardbans "$ip" 2>/dev/null || return 1; else return 1; fi; ipset save > "$ipsets_file" 2>/dev/null; return 0; }
EOF
sudo chmod 644 "$LIB_DIR/common.sh"

# 11. Скрипт определения страны
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[11/25] Скрипт определения страны..." || echo "[11/25] Country detection script...")${NC}"
sudo tee /usr/local/bin/get-country.sh > /dev/null << 'EOF'
#!/bin/bash
source /usr/local/lib/ssh-monitor/common.sh
load_config
get_country "$1"
EOF
sudo chmod +x /usr/local/bin/get-country.sh

# 12. Action для Fail2Ban
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[12/25] Action Fail2Ban..." || echo "[12/25] Fail2Ban action...")${NC}"
sudo tee /etc/fail2ban/action.d/two-stage-ban.conf > /dev/null << 'EOF'
[Definition]
actionban = /usr/local/bin/two-stage-ban.sh ban <ip>
actionunban = /usr/local/bin/two-stage-ban.sh unban <ip>
EOF

# 13. Скрипт блокировки
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[13/25] Создание two-stage-ban.sh..." || echo "[13/25] Creating two-stage-ban.sh...")${NC}"
sudo tee /usr/local/bin/two-stage-ban.sh > /dev/null << 'EOF'
#!/bin/bash
source /usr/local/lib/ssh-monitor/common.sh
load_config
ACTION="$1"
IP="$2"
if ! (validate_ipv4 "$IP" || validate_ipv6 "$IP"); then echo "$(date): Invalid IP $IP" >> "$LOG_FILE"; exit 1; fi
COUNTRY=$(get_country "$IP")
[ -z "$COUNTRY" ] && COUNTRY=$([ "$NOTIFY_LANG" = "ru" ] && echo "Неизвестно" || echo "Unknown")
ESCAPED_COUNTRY=$(escape_markdown "$COUNTRY")
NOW=$(date '+%Y-%m-%d %H:%M:%S')
case "$ACTION" in
    ban)
        if [ "$NOTIFY_LANG" = "ru" ]; then
            MSG=$(printf '🔴 *БЛОКИРОВКА* 🔴\n━━━━━━━━━━━━━━━━━━\n🌍 *IP:* %s\n📍 *Страна:* %s\n⏰ *Время:* %s\n🖥️ *Сервер:* %s\n━━━━━━━━━━━━━━━━━━\n🚫 IP ЗАБЛОКИРОВАН' "$IP" "$ESCAPED_COUNTRY" "$NOW" "$HOSTNAME")
        else
            MSG=$(printf '🔴 *BANNED* 🔴\n━━━━━━━━━━━━━━━━━━\n🌍 *IP:* %s\n📍 *Country:* %s\n⏰ *Time:* %s\n🖥️ *Server:* %s\n━━━━━━━━━━━━━━━━━━\n🚫 IP BLOCKED' "$IP" "$ESCAPED_COUNTRY" "$NOW" "$HOSTNAME")
        fi
        send_telegram "$MSG" "$BOT_TOKEN" "$CHAT_ID" "$LOG_FILE" "$IP"
        echo "$(date): STAGE 1 - $IP banned" >> "$LOG_FILE"
        ;;
    unban)
        if [ "$NOTIFY_LANG" = "ru" ]; then
            MSG=$(printf '🟢 *РАЗБЛОКИРОВКА* 🟢\n━━━━━━━━━━━━━━━━━━\n🌍 *IP:* %s\n📍 *Страна:* %s\n⏰ *Время:* %s\n🖥️ *Сервер:* %s\n━━━━━━━━━━━━━━━━━━\n✅ IP РАЗБЛОКИРОВАН' "$IP" "$ESCAPED_COUNTRY" "$NOW" "$HOSTNAME")
        else
            MSG=$(printf '🟢 *UNBANNED* 🟢\n━━━━━━━━━━━━━━━━━━\n🌍 *IP:* %s\n📍 *Country:* %s\n⏰ *Time:* %s\n🖥️ *Server:* %s\n━━━━━━━━━━━━━━━━━━\n✅ IP UNBLOCKED' "$IP" "$ESCAPED_COUNTRY" "$NOW" "$HOSTNAME")
        fi
        send_telegram "$MSG" "$BOT_TOKEN" "$CHAT_ID" "$LOG_FILE" "$IP"
        echo "$(date): UNBAN - $IP" >> "$LOG_FILE"
        ;;
esac
EOF
sudo chmod +x /usr/local/bin/two-stage-ban.sh

# 14. Мониторинг
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[14/25] Создание мониторинга..." || echo "[14/25] Creating monitor script...")${NC}"
sudo tee /usr/local/bin/check-post-ban-attacks.sh > /dev/null << 'EOF'
#!/bin/bash
source /usr/local/lib/ssh-monitor/common.sh
load_config
mkdir -p "$STORAGE_DIR"
if systemctl list-units --type=service | grep -q "sshd.service"; then SSH_UNIT="sshd"; else SSH_UNIT="ssh"; fi
NOTIFY_THRESHOLD=$((MAX_HARD_ATTEMPTS * 6 / 10))
[ "$NOTIFY_THRESHOLD" -lt 1 ] && NOTIFY_THRESHOLD=1
BANNED_CACHE=""; BANNED_CACHE_TIME=0
get_banned_ips() {
    local current_time=$(date +%s)
    local cache_age=0
    [ -n "$BANNED_CACHE_TIME" ] && cache_age=$((current_time - BANNED_CACHE_TIME))
    if [ -z "$BANNED_CACHE" ] || [ "$cache_age" -gt 5 ]; then
        BANNED_CACHE=$(sudo /usr/bin/fail2ban-client status sshd-instant 2>/dev/null | grep "Banned IP list" | sed 's/.*Banned IP list://' | tr ',' '\n' | sed '/^$/d')
        BANNED_CACHE_TIME=$current_time
    fi
    echo "$BANNED_CACHE"
}
is_ip_banned() { local ip="$1"; local banned_list=$(get_banned_ips); echo "$banned_list" | grep -q "^${ip}$"; }
while IFS= read -r line; do
    if echo "$line" | grep -q "Failed password"; then
        ip=$(echo "$line" | grep -oP 'from \K[0-9a-f:.]+')
        if (validate_ipv4 "$ip" && ! is_private_ip "$ip") || (validate_ipv6 "$ip" && [[ "$ip" != "::1" ]]); then
            if is_ip_banned "$ip"; then
                counter_file="${STORAGE_DIR}/counter-${ip}"
                lock_file="${counter_file}.lock"
                country_cache_file="${STORAGE_DIR}/country-${ip}"
                new=$(
                    flock -x -w 2 9 || { current=$(cat "$counter_file" 2>/dev/null || echo 0); echo "$current"; exit; }
                    current=$(cat "$counter_file" 2>/dev/null || echo 0)
                    new=$((current + 1))
                    echo "$new" > "$counter_file"
                    echo "$new"
                ) 9>"$lock_file"
                if [ "$new" -eq "$NOTIFY_THRESHOLD" ] && [ "$new" -lt "$MAX_HARD_ATTEMPTS" ]; then
                    COUNTRY=$(get_country "$ip")
                    [ -z "$COUNTRY" ] && COUNTRY=$([ "$NOTIFY_LANG" = "ru" ] && echo "Неизвестно" || echo "Unknown")
                    ESCAPED_COUNTRY=$(escape_markdown "$COUNTRY")
                    if [ "$NOTIFY_LANG" = "ru" ]; then
                        MSG=$(printf '⚠️ *IP ПРОДОЛЖАЕТ АТАКОВАТЬ* ⚠️\n━━━━━━━━━━━━━━━━━━\n🌍 *IP:* %s\n📍 *Страна:* %s\n━━━━━━━━━━━━━━━━━━\n📊 *Попыток после бана:* %s/%s\n⏳ *До жёсткого бана:* %s попыток\n━━━━━━━━━━━━━━━━━━\n⚠️ *При достижении %s попыток - IP будет полностью заблокирован*' "$ip" "$ESCAPED_COUNTRY" "$new" "$MAX_HARD_ATTEMPTS" "$((MAX_HARD_ATTEMPTS - new))" "$MAX_HARD_ATTEMPTS")
                    else
                        MSG=$(printf '⚠️ *IP KEEPS ATTACKING* ⚠️\n━━━━━━━━━━━━━━━━━━\n🌍 *IP:* %s\n📍 *Country:* %s\n━━━━━━━━━━━━━━━━━━\n📊 *Attempts after ban:* %s/%s\n⏳ *Until hard ban:* %s attempts\n━━━━━━━━━━━━━━━━━━\n⚠️ *At %s attempts - IP will be fully blocked*' "$ip" "$ESCAPED_COUNTRY" "$new" "$MAX_HARD_ATTEMPTS" "$((MAX_HARD_ATTEMPTS - new))" "$MAX_HARD_ATTEMPTS")
                    fi
                    send_telegram "$MSG" "$BOT_TOKEN" "$CHAT_ID" "$LOG_FILE" "$ip"
                fi
                if [ "$new" -ge "$MAX_HARD_ATTEMPTS" ]; then
                    if hard_ban_ip "$ip" "$IPSET_FILE"; then
                        COUNTRY=$(get_country "$ip")
                        [ -z "$COUNTRY" ] && COUNTRY=$([ "$NOTIFY_LANG" = "ru" ] && echo "Неизвестно" || echo "Unknown")
                        ESCAPED_COUNTRY=$(escape_markdown "$COUNTRY")
                        if [ "$NOTIFY_LANG" = "ru" ]; then
                            MSG=$(printf '🔴💀 *ЖЁСТКАЯ БЛОКИРОВКА* 💀🔴\n━━━━━━━━━━━━━━━━━━\n🌍 *IP:* %s\n📍 *Страна:* %s\n━━━━━━━━━━━━━━━━━━\n📊 *Попыток после бана:* %s\n🎯 *Достигнут лимит:* %s\n━━━━━━━━━━━━━━━━━━\n🚫 *IP ПОЛНОСТЬЮ ЗАБЛОКИРОВАН*\n🔒 *Блокированы все порты*\n⏰ *Длительность:* 30 дней' "$ip" "$ESCAPED_COUNTRY" "$new" "$MAX_HARD_ATTEMPTS")
                        else
                            MSG=$(printf '🔴💀 *HARD BAN* 💀🔴\n━━━━━━━━━━━━━━━━━━\n🌍 *IP:* %s\n📍 *Country:* %s\n━━━━━━━━━━━━━━━━━━\n📊 *Attempts after ban:* %s\n🎯 *Limit reached:* %s\n━━━━━━━━━━━━━━━━━━\n🚫 *IP FULLY BLOCKED*\n🔒 *All ports blocked*\n⏰ *Duration:* 30 days' "$ip" "$ESCAPED_COUNTRY" "$new" "$MAX_HARD_ATTEMPTS")
                        fi
                        send_telegram "$MSG" "$BOT_TOKEN" "$CHAT_ID" "$LOG_FILE" "$ip"
                        echo "$(date): HARD BAN - $ip after $new attempts" >> "$LOG_FILE"
                        rm -f "$counter_file" "$lock_file" "$country_cache_file"
                    fi
                fi
            fi
        fi
    fi
done < <(journalctl -f -n 0 -u "$SSH_UNIT" 2>/dev/null)
EOF
sudo chmod +x /usr/local/bin/check-post-ban-attacks.sh

# 15. Backend для Fail2Ban
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[15/25] Настройка backend..." || echo "[15/25] Configuring backend...")${NC}"
# Всегда используем polling + auth.log — journald не пишет "Failed password"
# при отключённой парольной аутентификации, поэтому sshd-instant не видит попыток
BACKEND="polling"

# 16. Конфиг Fail2Ban
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[16/25] Конфиг Fail2Ban..." || echo "[16/25] Fail2Ban config...")${NC}"
sudo tee /etc/fail2ban/jail.d/ssh-instant.conf > /dev/null << EOF
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 $WHITE_IP
bantime = 720h
findtime = 10m
maxretry = $MAX_RETRY
allowipv6 = auto

[sshd-instant]
enabled = true
port = $NEW_SSH_PORT
filter = sshd
maxretry = $MAX_RETRY
bantime = 720h
findtime = 10m
action = two-stage-ban
backend = polling
logpath = /var/log/auth.log
EOF

# 17. Отключение старого jail
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[17/25] Отключение старого jail..." || echo "[17/25] Disabling old jail...")${NC}"
[ -f /etc/fail2ban/jail.d/ssh-telegram.conf ] && sudo sed -i 's/enabled = true/enabled = false/' /etc/fail2ban/jail.d/ssh-telegram.conf 2>/dev/null

# 18. Systemd сервис
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[18/25] Systemd сервис..." || echo "[18/25] Systemd service...")${NC}"
sudo tee /etc/systemd/system/post-ban-monitor.service > /dev/null << 'EOF'
[Unit]
Description=Post-Ban Attack Monitor
After=network.target
StartLimitIntervalSec=30
StartLimitBurst=5

[Service]
Type=simple
ExecStart=/usr/local/bin/check-post-ban-attacks.sh
Restart=on-failure
RestartSec=5
User=ssh-monitor
Group=ssh-monitor
WorkingDirectory=/var/lib/ssh-monitor
RuntimeDirectory=ssh-monitor
RuntimeDirectoryMode=0750

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/ssh-monitor /var/log /etc/ssh-telegram /etc/iptables
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW

[Install]
WantedBy=multi-user.target
EOF

# 19. Health check
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[19/25] Health check..." || echo "[19/25] Health check...")${NC}"
sudo tee /usr/local/bin/post-ban-healthcheck.sh > /dev/null << 'EOF'
#!/bin/bash
if ! systemctl is-active --quiet post-ban-monitor; then
    systemctl restart post-ban-monitor
    echo "$(date): Health check restarted service" >> /var/log/two-stage-ban.log
    source /usr/local/lib/ssh-monitor/common.sh
    load_config
    MSG=$(printf '🔄 *Восстановление защиты* 🔄\n━━━━━━━━━━━━━━━━━━\n🖥️ *Сервер:* %s\n⏰ *Время:* %s\n📋 *Событие:* Сервис мониторинга перезапущен\n━━━━━━━━━━━━━━━━━━\n✅ *Система восстановлена*' "$HOSTNAME" "$(date '+%Y-%m-%d %H:%M:%S')")
    send_telegram "$MSG" "$BOT_TOKEN" "$CHAT_ID" "$LOG_FILE" "healthcheck"
fi
EOF
sudo chmod +x /usr/local/bin/post-ban-healthcheck.sh

sudo tee /etc/systemd/system/post-ban-healthcheck.service > /dev/null << 'EOF'
[Unit]
Description=Post-Ban Monitor Health Check
After=post-ban-monitor.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/post-ban-healthcheck.sh
User=root
NoNewPrivileges=true
EOF

sudo tee /etc/systemd/system/post-ban-healthcheck.timer > /dev/null << 'EOF'
[Unit]
Description=Health check timer for post-ban-monitor

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
EOF

# 20. Сохранение правил
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[20/25] Сохранение правил..." || echo "[20/25] Saving rules...")${NC}"
sudo ipset save > "$IPSET_FILE" 2>/dev/null || true
sudo netfilter-persistent save 2>/dev/null || true

# 21. Logrotate
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[21/25] Logrotate..." || echo "[21/25] Logrotate...")${NC}"
sudo tee /etc/logrotate.d/ssh-monitor > /dev/null << 'EOF'
/var/log/two-stage-ban.log {
    daily
    rotate 30
    compress
    missingok
    notifempty
    create 644 ssh-monitor ssh-monitor
}
EOF

# 22. Алиасы
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[22/25] Алиасы..." || echo "[22/25] Aliases...")${NC}"
if ! grep -q "# SSH-MONITOR ALIASES" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# SSH-MONITOR ALIASES / АЛИАСЫ SSH-MONITOR
alias banned='sudo fail2ban-client status sshd-instant | grep "Banned IP list" | sed "s/.*Banned IP list://" | tr "," "\n" | sed "/^$/d"'
alias f2b-status='sudo fail2ban-client status sshd-instant'
alias f2b-ban='sudo fail2ban-client set sshd-instant banip'
alias f2b-unban='sudo fail2ban-client set sshd-instant unbanip'
alias banstats='echo "=== Статистика банов ===" && sudo fail2ban-client status sshd-instant | grep -E "Currently banned|Total banned"'
alias ban-stages='sudo tail -20 /var/log/two-stage-ban.log'
alias hard-banned='sudo ipset list ssh-hardbans 2>/dev/null | grep -v "Members:" | grep -E "^[0-9]" | head -20'
alias hard-banned6='sudo ipset list ssh-hardbans6 2>/dev/null | grep -v "Members:" | grep -E "^[0-9a-f:]" | head -20'
alias monitor-status='systemctl status post-ban-monitor --no-pager'
# ======================================
EOF
    echo -e "${GREEN}${T_ALIASES_OK}${NC}"
fi

# 23. Запуск сервисов
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[23/25] Запуск сервисов..." || echo "[23/25] Starting services...")${NC}"
sudo systemctl daemon-reload
sudo systemctl enable post-ban-monitor
sudo systemctl restart post-ban-monitor
sudo systemctl enable post-ban-healthcheck.timer
sudo systemctl start post-ban-healthcheck.timer
sudo systemctl restart fail2ban

# 24. Перезапуск SSH
if [ "$CHANGE_PORT" = true ]; then
    echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[24/25] Перезапуск SSH..." || echo "[24/25] Restarting SSH...")${NC}"
    sudo systemctl restart sshd
fi

# 25. Тестовое сообщение с проверкой
echo -e "${GREEN}$([ "$LANG" = "ru" ] && echo "[25/25] Отправка тестового сообщения..." || echo "[25/25] Sending test message...")${NC}"
WHITE_IP_DISPLAY=$(echo "$WHITE_IP" | tr ' ' '/')
if [ "$LANG" = "ru" ]; then
TG_TEXT="✅ *Система защиты v28 установлена!* ✅
━━━━━━━━━━━━━━━━━━
🖥️ *Сервер:* $(hostname)
🌍 *Белый IP:* ${WHITE_IP_DISPLAY}
🔌 *SSH порт:* ${NEW_SSH_PORT}
⚙️ *Настройки:*
  • Бан после ${MAX_RETRY} попыток
  • Жёсткая блокировка после ${MAX_HARD_ATTEMPTS} попыток
  • Backend: polling + auth.log
━━━━━━━━━━━━━━━━━━
🛡️ *Сервер защищён!*"
else
TG_TEXT="✅ *Protection system v28 installed!* ✅
━━━━━━━━━━━━━━━━━━
🖥️ *Server:* $(hostname)
🌍 *Whitelisted IP:* ${WHITE_IP_DISPLAY}
🔌 *SSH port:* ${NEW_SSH_PORT}
⚙️ *Settings:*
  • Ban after ${MAX_RETRY} attempts
  • Hard block after ${MAX_HARD_ATTEMPTS} attempts
  • Backend: polling + auth.log
━━━━━━━━━━━━━━━━━━
🛡️ *Server is protected!*"
fi
TG_TEXT_ESCAPED=$(printf '%s' "$TG_TEXT" | sed 's/\\/\\\\/g; s/"/\\"/g')
TG_PAYLOAD="{\"chat_id\":\"${CHAT_ID}\",\"text\":\"${TG_TEXT_ESCAPED}\",\"parse_mode\":\"Markdown\"}"
if curl -s --max-time 10 -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "$TG_PAYLOAD" > /dev/null 2>&1; then
    echo -e "${GREEN}${T_TG_OK}${NC}"
else
    echo -e "${RED}${T_TG_FAIL}${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ${T_DONE}${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
if [ "$CHANGE_PORT" = true ]; then
    echo -e "${YELLOW}${T_PORT_CHANGED} $NEW_SSH_PORT${NC}"
    echo -e "${YELLOW}   ${T_CONNECT} ssh -p $NEW_SSH_PORT user@$(hostname)${NC}"
    echo ""
fi
if [ "$DISABLE_PASSWORD" = "yes" ]; then
    echo -e "${YELLOW}${T_PASSWORD_WARNING}${NC}"
    echo -e "${YELLOW}   ${T_KEY_SETUP}${NC}"
    echo -e "   ssh-keygen -t ed25519"
    echo -e "   ssh-copy-id -p ${NEW_SSH_PORT} user@$(hostname)"
    echo ""
fi
if [ "$DISABLE_ROOT" = "yes" ]; then
    echo -e "${YELLOW}${T_ROOT_WARNING}${NC}"
    echo -e "   ${T_ROOT_USE_SUDO} ssh user@host -p ${NEW_SSH_PORT}"
    echo ""
fi
echo -e "${GREEN}${T_COMMANDS}${NC}"
if [ "$LANG" = "ru" ]; then
echo -e "  banned         - список забаненных IP"
echo -e "  f2b-status     - статус защиты"
echo -e "  f2b-ban IP     - забанить IP"
echo -e "  f2b-unban IP   - разбанить IP"
echo -e "  ban-stages     - логи блокировок"
echo -e "  hard-banned    - жёстко забаненные IPv4"
echo -e "  monitor-status - статус сервиса"
else
echo -e "  banned         - list of banned IPs"
echo -e "  f2b-status     - protection status"
echo -e "  f2b-ban IP     - ban an IP manually"
echo -e "  f2b-unban IP   - unban an IP"
echo -e "  ban-stages     - ban log"
echo -e "  hard-banned    - hard-banned IPv4 list"
echo -e "  monitor-status - monitor service status"
fi
echo ""