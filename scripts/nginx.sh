#!/bin/bash


### В качестве параметра указываем адреса бэкенд серверов без масок
balance_srv1=$1
balance_srv2=$2

if [ $# !=2 ];then
    echo "Нужно указать два параметра"
    exit 1
fi



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

sudo mkdir -p /opt/docker-compose/configs/nginx
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

sudo mkdir -p /var/conf/nginx/
sudo curl curl https://raw.githubusercontent.com/RanisAbit/otus/main/configs/nginx.conf -o /var/conf/nginx/nginx.conf

### Назначение адреса серверов

sudo sed -i 's/srv_address1/$balance_srv1/g' /var/conf/nginx/default.conf
sudo sed -i 's/srv_address2/$balance_srv2/g' /var/conf/nginx/default.conf

sudo cd /opt/docker-compose/configs/nginx/
sudo docker-compose up
sudo docker ps -a
sudo ss -ntlp | grep 80 