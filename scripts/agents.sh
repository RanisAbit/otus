#!/bin/bash
# Установка агента promtheus
if [ ! -e /usr/lib/systemd/system/prometheus-node-exporter.service ]; then
sudo apt update -y
sudo apt install prometheus-node-exporter-collectors -y > /dev/null
systemctl start prometheus-node-exporter.service
fi

#Установка агента filebeat
if [ ! -e /usr/lib/systemd/system/filebeat.service ]; then
curl -O https://images-1f5c8b8d4bd14902abdb2b5b4d9a4a4e.hb.ru-msk.vkcloud-storage.ru/filebeat_8.17.1_amd64-224190-a5f894.deb
dpkg -i filebeat_8.17.1_amd64-224190-a5f894.deb
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
          host: "unix:/var/run/docker.sock"
      - drop_event:
          when:
            not:
              or:
                - contains:
                    container.name: proxy
                - contains:
                    container.name: logstash
                - contains:
                    container.name: kibana
                - contains:
                    container.name: elasticsearch
                - contains:
                    container.name: grafana
                - contains:
                    container.name: prometheus
                - contains:
                    container.name: wordpress

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