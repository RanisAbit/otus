#!/bin/bash

# Задаем переменные
master_user="repl"
config_file="/etc/mysql/mysql.conf.d/mysqld.cnf"
backup_file="/etc/mysql/mysql.conf.d/mysqld.cnf.bak"

# Проверяем наличие mysql в сисетме, если исполняемый файл отсутствует, тогда выполнить установку

if [ ! -e /usr/sbin/mysqld ]; then
echo "Выполняется настройка master-server"

sudo apt update -y
sudo apt install mysql-server -y

# Делаем бэкап дефолтного конфига 
if [ ! -e "$backup_file" ]; then
    sudo cp "$config_file" "$backup_file"
fi

# Если конфиг не настроен на репликацию тогда вписать настройки
if ! grep -q "server_id = 1" "$config_file"; then
    sudo tee "$config_file" > /dev/null <<EOF
[mysqld]
user = mysql
bind-address = 0.0.0.0
mysqlx-bind-address = 127.0.0.1
key_buffer_size = 16M
log_error = /var/log/mysql/error.log
server_id = 1
log_bin = mysql-bin
binlog_format = ROW
gtid_mode = ON
enforce_gtid_consistency = ON
log_replica_updates = ON
max_binlog_size = 100M
EOF
    sudo systemctl restart mysql
fi

# Запрашивем ввод пароля для будщего подключения слейва
read -rsp "Введите пароль для УЗ подключения к Мастеру: " pass
echo
# Проверка что пароль был введен
if [ -z "$pass" ]; then
    echo "Пароль не может быть пустым"
    exit 1
fi
# Выполнение команд в sql для настройки репликации
sudo mysql -e "CREATE USER IF NOT EXISTS '${master_user}'@'%' IDENTIFIED BY '${pass}';"
sudo mysql -e "ALTER USER '${master_user}'@'%' IDENTIFIED BY '${pass}';"
sudo mysql -e "GRANT REPLICATION SLAVE ON *.* TO '${master_user}'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"
sudo mysql -e "SHOW MASTER STATUS\G"
echo "Master-server настроен"