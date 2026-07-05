#!/bin/bash

### Установка docker
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update

sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl status docker

### Файл docker-compose

mkdir -p /opt/docker-compose/configs/nginx
sudo touch /opt/docker-compose/configs/nginx/nginx.yml
sudo tee /opt/docker-compose/configs/nginx/nginx.yml <<EOF
version: "3.8"

services:
  nginx:
    image: nginx:alpine
    container_name: proxy
    ports:
      - "80:80"          # хост:контейнер
    volumes:
      - /var/conf/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    restart: unless-stopped
EOF

### Скачивание конфига

mkdir -p /var/conf/nginx/
 