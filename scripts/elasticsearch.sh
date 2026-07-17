#!/bin/bash

elastic_dir="/opt/docker-compose/configs/elk/elasticsearch"
logstash_dir="/opt/docker-compose/configs/elk/logstash"
kibana_dir="/opt/docker-compose/configs/elk/kibana"
server_ip=$(ip -br a | grep '10.0.' | awk '{print $3}' | awk -F/ '{print $1}' | head -n1)

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

# Создание диреторий
mkdir -p "$elastic_dir/data/"
sudo chown -R 1000:1000 /opt/docker-compose/configs/elk/elasticsearch/data/
sudo chmod -R u+rwx /opt/docker-compose/configs/elk/elasticsearch/data/
mkdir -p "$logstash_dir/config/"
mkdir -p "$logstash_dir/pipeline/"
mkdir -p "$kibana_dir/config/"

# Установка elasticsearch
if [ -e $elastic_dir/docker-compose.yml ]; then
rm -f $elastic_dir/docker-compose.yml
fi
sudo tee $elastic_dir/docker-compose.yml << EOF
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.14.3
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - ES_JAVA_OPTS=-Xms1g -Xmx1g
    volumes:
      - $elastic_dir/data/:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    restart: unless-stopped
EOF

# Установка logstash
if [ -e $logstash_dir/docker-compose.yml ]; then
rm -f $logstash_dir/docker-compose.yml
fi
sudo tee $logstash_dir/docker-compose.yml << EOF
services:
  logstash:
    image: docker.elastic.co/logstash/logstash:8.14.3
    container_name: logstash
    volumes:
      - $logstash_dir/config/logstash.yml:/usr/share/logstash/config/logstash.yml:ro
      - $logstash_dir/config/pipelines.yml:/usr/share/logstash/config/pipelines.yml:ro
      - $logstash_dir/pipeline:/usr/share/logstash/pipeline:ro
    ports:
      - "5044:5044"
      - "5000:5000/tcp"
      - "5000:5000/udp"
      - "9600:9600"
    restart: unless-stopped
EOF

sudo tee $logstash_dir/config/logstash.yml << EOF
api.http.host: 0.0.0.0
node.name: logstash
xpack.monitoring.enabled: false
EOF

sudo tee $logstash_dir/config/pipelines.yml << EOF
- pipeline.id: main
  path.config: "/usr/share/logstash/pipeline/logstash.conf"
EOF

sudo tee $logstash_dir/pipeline/logstash.conf << EOF
input {
  beats {
    port => 5044
  }
}

output {
  elasticsearch {
    hosts => ["http://$server_ip:9200"]
    index => "logs-%{+YYYY.MM.dd}"
  }
  stdout {
    codec => rubydebug
  }
}
EOF

# Установка kibana
if [ -e $kibana_dir/docker-compose.yml ]; then
rm -f $kibana_dir/docker-compose.yml
fi
sudo tee $kibana_dir/docker-compose.yml << EOF
services:
  kibana:
    image: docker.elastic.co/kibana/kibana:8.14.3
    container_name: kibana
    ports:
      - "5601:5601"
    volumes:
      - $kibana_dir/config/kibana.yml:/usr/share/kibana/config/kibana.yml:ro
    restart: unless-stopped
EOF

sudo tee $kibana_dir/config/kibana.yml << EOF
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://$server_ip:9200"]
EOF

sudo sysctl -w vm.max_map_count=1048576

#Запуск контейнеров
if sudo docker ps -a --format '{{.Names}}' | grep -qx 'elasticsearch'; then
    sudo docker compose -f $elastic_dir/docker-compose.yml down
fi
sudo docker compose -f "$elastic_dir/docker-compose.yml" up -d
sleep 20


if sudo docker ps -a --format '{{.Names}}' | grep -qx 'logstash'; then
    sudo docker compose -f $logstash_dir/docker-compose.yml down
fi
sudo docker compose -f "$logstash_dir/docker-compose.yml" up -d
sleep 10


if sudo docker ps -a --format '{{.Names}}' | grep -qx 'kibana'; then
    sudo docker compose -f $kibana_dir/docker-compose.yml down
fi
sudo docker compose -f "$kibana_dir/docker-compose.yml" up -d


