#!/bin/bash

master_user="repl"
config_file="/etc/mysql/mysql.conf.d/mysqld.cnf"
backup_file="/etc/mysql/mysql.conf.d/mysqld.cnf.bak"

echo "Настройка slave-сервера"

sudo apt update -y
sudo apt install -y mysql-server

if [ ! -f "$backup_file" ]; then
    sudo cp "$config_file" "$backup_file"
fi

sudo tee "$config_file" > /dev/null <<EOF
[mysqld]
user = mysql

bind-address = 0.0.0.0

server_id = 2
log_bin = mysql-bin
relay_log = relay-log-server
read_only = ON
super_read_only = ON
gtid_mode = ON
enforce_gtid_consistency = ON
log_replica_updates = ON
EOF

sudo systemctl restart mysql

read -rp "Введите IP адрес Master-server: " master_address
echo
read -rsp "Введите пароль для УЗ подключения к Master: " pass
echo

if [ -z "$pass" ]; then
    echo "Пароль не может быть пустым"
    exit 1
fi

sudo mysql -e "STOP REPLICA;"
sudo mysql -e "CHANGE REPLICATION SOURCE TO SOURCE_HOST='${master_address}', SOURCE_USER='${master_user}', SOURCE_PASSWORD='${pass}', SOURCE_AUTO_POSITION=1, GET_SOURCE_PUBLIC_KEY=1;"
sudo mysql -e "START REPLICA;"
sudo mysql -e "SHOW REPLICA STATUS\\G"

echo "Настройка slave-server завершена"
