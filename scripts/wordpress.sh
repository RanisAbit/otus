#!/bin/bash

docker_file="/opt/docker-compose/configs/wordpress/docker-compose.yml"

read -rp "Введите IP адрес Master-server: " $IP_MASTER_MYSQL
echo

read -rsp "Введите пароль для УЗ подключения к Master: " pass
echo

if [ -z "$pass" ]; then
    echo "Пароль не может быть пустым"
    exit 1
fi

# Установка docker
if [ -x /usr/bin/docker ]; then
    :
else
    sudo apt update
    sudo apt install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
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

if [ ! -e "$docker_file" ]; then
    sudo mkdir -p /opt/docker-compose/configs/wordpress/html
fi

sudo tee "$docker_file" > /dev/null <<EOF
services:
  wordpress:
    image: wordpress:6-apache
    container_name: wp-app
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: $IP_MASTER_MYSQL:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: $pass
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - /opt/docker-compose/configs/wordpress/html:/var/www/html
EOF

echo "$(hostname)" | sudo tee /opt/docker-compose/configs/wordpress/html/health.txt > /dev/null

if sudo docker ps -a --format '{{.Names}}' | grep -qx 'wp-app'; then
    sudo docker compose -f "$docker_file" down
fi
sudo docker compose -f "$docker_file" up -d


