#! /bin/bash
master_user=repl
echo "Выполняется настройка master-server"
sudo apt update -y 
sudo apt install -y mysql-server 

if [ ! -f /etc/mysql/mysql.conf.d/mysqld.cnf.bak ]; then
sudo cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.bak
fi

if ! grep -q "server_id = 1" "$config_file"; then

sudo tee /etc/mysql/mysql.conf.d/mysqld.cnf <<EOF
[mysqld]
# * Basic Settings
user            = mysql
# pid-file      = /var/run/mysqld/mysqld.pid
# socket        = /var/run/mysqld/mysqld.sock
# port          = 3306
# datadir       = /var/lib/mysql
# Master Settings
bind-address            = 0.0.0.0
mysqlx-bind-address     = 127.0.0.1
key_buffer_size         = 16M
log_error = /var/log/mysql/error.log
server_id = 1
log-bin = mysql-bin
binlog_format = row
gtid-mode=ON
enforce_gtid_consistency = ON
log-replica-updates
max_binlog_size   = 100M

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

sudo mysql -e "ALTER USER 'repl'@'%'IDENTIFIED BY '${pass}';"
sudo mysql -e "GRANT REPLICATION SLAVE ON *.* TO '${master_user}'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"
sudo mysql -e "SHOW MASTER STATUS\G"

echo "Master-server настроен"