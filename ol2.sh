#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Проверка наличия bc и установка, если не установлен
if ! command -v bc &> /dev/null; then
    sudo apt update
    sudo apt install bc -y
fi
sleep 1

# Проверка версии Ubuntu
UBUNTU_VERSION=$(lsb_release -rs)
REQUIRED_VERSION=22.04

if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    echo -e "${RED}Для этой ноды нужна минимальная версия Ubuntu 22.04${NC}"
    exit 1
fi

# Установка ноды OpenLedger
echo -e "${BLUE}Установка ноды OpenLedger...${NC}"

# Проверка и установка Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker не установлен. Устанавливаем Docker...${NC}"
    apt remove docker docker-engine docker.io containerd runc -y
    apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    echo -e "${GREEN}Docker успешно установлен.${NC}"
else
    echo -e "${GREEN}Docker уже установлен.${NC}"
fi

# Проверка и запуск Docker
if systemctl is-active --quiet docker; then
    echo "Docker уже запущен."
else
    echo "Запускаем Docker..."
    sudo systemctl start docker
fi

if systemctl is-enabled --quiet docker; then
    echo "Docker уже добавлен в автозагрузку."
else
    echo "Добавляем Docker в автозагрузку..."
    sudo systemctl enable docker
fi

# Установка зависимостей
sudo apt update && sudo apt upgrade -y
sudo apt install ubuntu-desktop xrdp unzip screen -y
sudo apt install -y desktop-file-utils libgbm1 libasound2
sudo apt-get install libasound2t64
sudo dpkg --configure -a

# Настройка XRDP
sudo adduser xrdp ssl-cert
sudo systemctl start gdm
sudo systemctl enable xrdp
sudo systemctl restart xrdp

# Установка OpenLedger
wget https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip
unzip openledger-node-1.0.0-linux.zip
sudo dpkg -i openledger-node-1.0.0.deb

# Проверка и настройка screen
if screen -list | grep -q "openledger"; then
    screen -S openledger -X quit
    echo -e "${YELLOW}Существующие сессии screen openledger удалены.${NC}"
fi
screen -dmS openledger_node bash -c 'openledger-node --no-sandbox --disable-gpu; sleep infinity'

# Завершающий вывод
echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
echo -e "${YELLOW}Команда для входа в сессию screen:${NC}" 
echo "screen -r openledger_node"
echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
