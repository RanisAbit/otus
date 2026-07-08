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
