#!/bin/bash

### В качестве параметра указываем адреса бэкенд серверов без масок

balance_srv1=$1
balance_srv2=$2

if [ $# -ne 2 ]; then
    echo "Нужно указать IP сереров"
    exit 1
fi

if [ -e /usr/bin/docker ]; then
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

    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl start docker
fi

if [ ! -e /opt/docker-compose/configs/nginx/docker-compose.yml ]; then
 sudo mkdir -p /opt/docker-compose/configs/nginx
sudo tee /opt/docker-compose/configs/nginx/docker-compose.yml <<EOF
services:
  nginx:
    image: nginx:alpine
    container_name: proxy
    ports:
      - "80:80"
    volumes:
      - /opt/docker-compose/configs/nginx/config/default.conf:/etc/nginx/conf.d/default.conf:ro
    restart: unless-stopped
EOF
fi

sudo mkdir -p /opt/docker-compose/configs/nginx/config/
sudo tee /opt/docker-compose/configs/nginx/config/default.conf <<EOF
# Balance server

upstream backend {
    server srv_address1:8080;
    server srv_address2:8080;
}

log_format upstreamlog '\$remote_addr - \$remote_user [\$time_local] '
                       '"\$request" \$status \$body_bytes_sent '
                       '"\$http_referer" "\$http_user_agent" '
                       'host="\$host" '
                       'upstream="\$upstream_addr" '
                       'upstream_status="\$upstream_status" '
                       'upstream_connect_time="\$upstream_connect_time" '
                       'upstream_response_time="\$upstream_response_time" '
                       'request_time="\$request_time"';

server {
    listen 80;
    listen [::]:80;
    server_name _;
    root /usr/share/nginx/html;

    access_log /dev/stdout upstreamlog;
    error_log /dev/stderr warn;

    include /etc/nginx/default.d/*.conf;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo sed -i "s/srv_address1/${balance_srv1}/g" /opt/docker-compose/configs/nginx/config/default.conf
sudo sed -i "s/srv_address2/${balance_srv2}/g" /opt/docker-compose/configs/nginx/config/default.conf

# Запуск сервера
if sudo docker ps -a --format '{{.Names}}' | grep -qx 'proxy'; then
    sudo docker compose -f /opt/docker-compose/configs/nginx/docker-compose.yml down
fi

sudo docker compose -f /opt/docker-compose/configs/nginx/docker-compose.yml up -d
