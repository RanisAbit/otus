#!/bin/bash

work_dir="/opt/docker-compose/configs"

# Установка docker

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

# Установка prometheus
sudo mkdir -p $work_dir/prometheus/conf/

if [ -e $work_dir/prometheus/docker-compose.yml ]; then
rm -f $work_dir/prometheus/docker-compose.yml
fi
sudo tee $work_dir/prometheus/docker-compose.yml << EOF
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prom
    ports:
      - 9090:9090
    volumes:
      - $work_dir/prometheus/conf/prometheus.yml:/etc/prometheus/prometheus.yml
      - $work_dir/prometheus/conf/node_targets.yml:/etc/prometheus/file_sd/node_targets.yml
    restart: unless-stopped
EOF

# Установка grafana

read -rsp "Введите пароль для grafana:" pass
echo
sudo mkdir -p $work_dir/grafana/conf/
sudo mkdir -p $work_dir/grafana/data/
sudo chmod -R 777 $work_dir/grafana/data/

if [ -e $work_dir/grafana/docker-compose.yml ]; then
rm -f $work_dir/grafana/docker-compose.yml
fi
sudo tee $work_dir/grafana/docker-compose.yml << EOF
services:
  grafana:
    image: grafana/grafana
    container_name: graf
    ports:
      - 3000:3000
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=$pass
    volumes:
      - $work_dir/grafana/data/:/var/lib/grafana
EOF

# Загрузка конфигов

sudo curl -fL https://raw.githubusercontent.com/RanisAbit/otus/refs/heads/main/configs/prometheus.yml -O $work_dir/prometheus/conf/prometheus.yml
sudo curl -fL https://raw.githubusercontent.com/RanisAbit/otus/refs/heads/main/configs/node_targets.yml -O $work_dir/prometheus/conf/node_targets.yml

# Настройка prometheus

read -rp "Введите адрес Мастер сервера SQL:" sql_main
echo
read -rp "Введите адрес Слейв сервера SQL:" sql_slave
echo
read -rp "Введите адрес Proxy сервера :" proxy
echo
read -rp "Введите адрес Мониторинг сервера :" monitor
echo

sudo sed -i "s/sql_main/${sql_main}"/g $work_dir/prometheus/conf/node_targets.yml
sudo sed -i "s/sql_slave/${sql_slave}/g" $work_dir/prometheus/conf/node_targets.yml
sudo sed -i "s/proxy/${proxy}/g" $work_dir/prometheus/conf/node_targets.yml
sudo sed -i "s/monitor/${monitor}/g" $work_dir/prometheus/conf/node_targets.yml

#Запуск контейнеров
if sudo docker ps -a --format '{{.Names}}' | grep -qx 'prom'; then
    sudo docker compose -f $work_dir/prometheus/docker-compose.yml down
fi
sudo docker compose -f $work_dir/prometheus/docker-compose.yml up -d

if sudo docker ps -a --format '{{.Names}}' | grep -qx 'graf'; then
    sudo docker compose -f $work_dir/grafana/docker-compose.yml down
fi
sudo docker compose -f $work_dir/grafana/docker-compose.yml up -d

