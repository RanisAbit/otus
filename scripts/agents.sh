#!/bin/bash
# Установка агента promtheus
if [ ! -e /usr/lib/systemd/system/prometheus-node-exporter.service ]; then
sudo apt update -y
sudo apt install prometheus-node-exporter-collectors -y > /dev/null
systemctl start prometheus-node-exporter.service
fi

#Установка агента filebeat
if [ ! -e /usr/lib/systemd/system/filebeat.service ]; then
sudo apt update -y
sudo apt install prometheus-node-exporter-collectors -y > /dev/null
sudo wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt  install apt-transport-https
sudo echo "deb https://artifacts.elastic.co/packages/9.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-9.x.list
sudo apt update -y
sudo apt install filebeat -y
sudo systemctl enable filebeat
fi

if [ ! -e /etc/filebeat/filebeat.yml.bac ]; then
  sudo cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.bac
fi

read -rp "Введите адрес ELK сервера: " server_ip

sudo tee /etc/filebeat/filebeat.yml >/dev/null <<EOF
filebeat.inputs:
  - type: filestream
    id: system-logs
    enabled: true
    paths:
      - /var/log/syslog
      - /var/log/auth.log
      - /var/log/kern.log

  - type: filestream
    id: mysql-logs
    enabled: true
    paths:
      - /var/log/mysql/*.log

  - type: filestream
    id: docker-nginx
    enabled: true
    paths:
      - /var/lib/docker/containers/*/*.log
    parsers:
      - container: ~
    processors:
      - add_docker_metadata:
          host: "unix:///var/run/docker.sock"
      - drop_event:
          when:
            not:
              or:
                - contains:
                    container.name: nginx
                - contains:
                    container.name: logstash
                - contains:
                    container.name: kibana
                - contains:
                    container.name: elasticsearch
                - contains:
                    container.name: graf
                - contains:
                    container.name: prom
                - contains:
                    docker.container.name: nginx
                - contains:
                    docker.container.name: logstash
                - contains:
                    docker.container.name: kibana
                - contains:
                    docker.container.name: elasticsearch
                - contains:
                    docker.container.name: graf
                - contains:
                    docker.container.name: prom

output.logstash:
  hosts: ["$server_ip:5044"]

logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
  permissions: 0644

EOF

sudo filebeat test config -c /etc/filebeat/filebeat.yml
sudo systemctl restart filebeat
sudo systemctl status filebeat --no-pager