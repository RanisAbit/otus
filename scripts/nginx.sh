#!/bin/bash

### В качестве параметра указываем адреса бэкенд серверов без масок

balance_srv1=$1
balance_srv2=$2

if [ $# -ne 2 ]; then
    echo "Нужно указать два параметра"
    exit 1
fi

if [ -x /usr/bin/docker ]; then
    :
else
    sudo apt update
    sudo apt install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl start docker
fi

if [ -e /opt/docker-compose/configs/nginx/docker-compose.yml ]; then
    :
else
    sudo mkdir -p /opt/docker-compose/configs/nginx
    sudo tee /opt/docker-compose/configs/nginx/docker-compose.yml <<EOF
version: "3.8"

services:
  nginx:
    image: nginx:alpine
    container_name: proxy
    ports:
      - "80:80"
    volumes:
      - /var/conf/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    restart: unless-stopped
EOF
fi

sudo mkdir -p /var/conf/nginx/
sudo curl https://raw.githubusercontent.com/RanisAbit/otus/main/configs/nginx.conf -o /var/conf/nginx/default.conf


sudo sed -i "s/srv_address1/${balance_srv1}/g" /var/conf/nginx/default.conf
sudo sed -i "s/srv_address2/${balance_srv2}/g" /var/conf/nginx/default.conf

# Запуск сервера
if sudo docker ps -a --format '{{.Names}}' | grep -qx 'proxy'; then
    sudo docker compose -f /opt/docker-compose/configs/nginx/docker-compose.yml down
fi

sudo docker compose -f /opt/docker-compose/configs/nginx/docker-compose.yml up -d
