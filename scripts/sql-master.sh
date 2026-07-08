#!/bin/bash

master_user="repl"
config_file="/etc/mysql/mysql.conf.d/mysqld.cnf"
backup_file="/etc/mysql/mysql.conf.d/mysqld.cnf.bak"

echo "Выполняется настройка master-server"

sudo apt update -y
sudo apt install -y mysql-server

if [ ! -f "$backup_file" ]; then
    sudo cp "$config_file" "$backup_file"
fi

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
else
    echo "Конфиг содержит настройки master-server"
fi
read -rsp "Введите пароль для УЗ подключения к Мастеру: " pass
echo

if [ -z "$pass" ]; then
    echo "Пароль не может быть пустым"
    exit 1
fi

sudo mysql -e "CREATE USER IF NOT EXISTS '${master_user}'@'%' IDENTIFIED BY '${pass}';"
sudo mysql -e "ALTER USER '${master_user}'@'%' IDENTIFIED BY '${pass}';"
sudo mysql -e "GRANT REPLICATION SLAVE ON *.* TO '${master_user}'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"
sudo mysql -e "SHOW BINARY LOG STATUS\G"
echo "Master-server настроен"
