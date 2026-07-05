#! /bin/bash

master_user=repl

echo "Настройка master сервера !!!"

sudo apt update
sudo apt install -y mysql-server

sudo tee /etc/mysql/mysql.conf.d/mysqld.cnf <<EOF
[mysqld]
bind-address = 0.0.0.0
server_id = 1
log_bin = mysql-bin
binlog_format = ROW
gtid_mode = ON
enforce_gtid_consistency = ON
log_replica_updates = ON
EOF

sudo systemctl restart mysql

read -rsp "Введите пароль для УЗ подключения к Мастеру: " pass
echo

sudo mysql -e "CREATE USER '${master_user}'@'%' IDENTIFIED BY '${pass}';"
sudo mysql -e "GRANT REPLICATION SLAVE ON *.* TO '${master_user}'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"

sudo mysql -e "SHOW BINARY LOG STATUS\G"
