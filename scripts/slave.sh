#!/bin/bash

master_user="repl"
master_address="$1"

if [ -z "$master_address" ]; then
    echo "Передай IP master-сервера аргументом"
    exit 1
fi

echo "Настройка slave-сервера !!!"

sudo apt update
sudo apt install -y mysql-server

if [ ! -f /etc/mysql/mysql.conf.d/mysqld.cnf.bak ]; then
sudo cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.bak
fi

sudo tee /etc/mysql/mysql.conf.d/mysqld.cnf > /dev/null <<EOF
[mysqld]
# * Basic Settings
user            = mysql
# pid-file      = /var/run/mysqld/mysqld.pid
# socket        = /var/run/mysqld/mysqld.sock
# port          = 3306
# datadir       = /var/lib/mysql
# Slave Settings
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

read -rsp "Введите пароль для УЗ подключения к Master: " pass
echo

sudo mysql -e "STOP REPLICA;"
sudo mysql -e "CHANGE REPLICATION SOURCE TO SOURCE_HOST='${master_address}', SOURCE_USER='${master_user}', SOURCE_PASSWORD='${pass}', SOURCE_AUTO_POSITION=1, GET_SOURCE_PUBLIC_KEY = 1;"
sudo mysql -e "START REPLICA;"
sudo mysql -e "SHOW REPLICA STATUS\\G"
echo "Настройка slave-server зарешена"



