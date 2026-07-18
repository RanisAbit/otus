#!/bin/bash
# Задаем переменные
master_user="repl"
config_file="/etc/mysql/mysql.conf.d/mysqld.cnf"
backup_file="/etc/mysql/mysql.conf.d/mysqld.cnf.bak"

# Проверяем наличие mysql в сисетме, если исполняемый файл отсутствует, тогда выполнить установку
if [ ! -e /usr/sbin/mysqld ]; then
sudo apt update -y
sudo apt install mysql-server -y
fi
# Делаем бэкап дефолтного конфига 
if [ ! -e "$backup_file" ]; then
    sudo cp "$config_file" "$backup_file"
fi

# Если конфиг не настроен на репликацию тогда вписать настройки
if ! grep -q "server_id = 2" "$config_file"; then
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
fi

read -rp "Введите IP адрес Master-server: " master_address
echo
read -rsp "Введите пароль для подключения к Master-server: " pass
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
