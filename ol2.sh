#!/bin/bash

# Выход при ошибке
set -e

# Функция для вывода сообщений с цветом
print_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Проверка и установка curl
if ! command -v curl &> /dev/null; then
    sudo apt install curl -y
fi

# Отображаем логотип
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# Проверка и установка bc
if ! command -v bc &> /dev/null; then
    sudo apt install bc -y
fi

# Проверка версии Ubuntu
UBUNTU_VERSION=$(lsb_release -rs)
REQUIRED_VERSION=22.04

if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    print_message "${RED}" "Для этой ноды нужна минимальная версия Ubuntu 22.04"
    exit 1
fi

# Проверка и установка Docker
if ! command -v docker &> /dev/null; then
    print_message "${YELLOW}" "Docker не установлен. Устанавливаем Docker..."
    sudo apt remove docker docker-engine docker.io containerd runc -y || true
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    print_message "${GREEN}" "Docker успешно установлен."
else
    print_message "${GREEN}" "Docker уже установлен."
fi

# Запуск и автозагрузка Docker
sudo systemctl start docker
sudo systemctl enable docker

# Установка дополнительных зависимостей
sudo apt install -y ubuntu-desktop xrdp unzip screen desktop-file-utils libgbm1 libasound2

# Настройка XRDP
sudo adduser xrdp ssl-cert || true
sudo systemctl start gdm
sudo systemctl enable xrdp
sudo systemctl restart xrdp

# Загрузка и установка OpenLedger
wget -q https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip -O /tmp/openledger-node.zip
unzip -qq /tmp/openledger-node.zip -d /tmp
sudo dpkg -i /tmp/openledger-node-1.0.0.deb

# Удаление старых сессий screen и запуск новой
if screen -list | grep -q "openledger_node"; then
    screen -S openledger_node -X quit
fi
screen -dmS openledger_node bash -c 'openledger-node --no-sandbox --disable-gpu; sleep infinity'

# Очистка временных файлов
rm -f /tmp/openledger-node.zip /tmp/openledger-node-1.0.0.deb

# Завершающее сообщение
print_message "${GREEN}" "Нода OpenLedger успешно установлена и запущена."
print_message "${CYAN}" "Для доступа к сессии screen используйте команду: screen -r openledger_node"
print_message "${CYAN}" "Наш Telegram: https://t.me/cryptoforto"
