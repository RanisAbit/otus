#!/bin/bash

wp_db="wordpress"
wp_user="wordpress"

echo "Создание БД и пользователя для WordPress"

read -rsp "Введите пароль для пользователя WordPress: " wp_pass
echo

if [ -z "$wp_pass" ]; then
    echo "Пароль не может быть пустым"
    exit 1
fi

sudo mysql -e "CREATE DATABASE IF NOT EXISTS \`${wp_db}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER IF NOT EXISTS '${wp_user}'@'%' IDENTIFIED BY '${wp_pass}';"
sudo mysql -e "ALTER USER '${wp_user}'@'%' IDENTIFIED BY '${wp_pass}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON \`${wp_db}\`.* TO '${wp_user}'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"
sudo mysql -e "SHOW DATABASES LIKE '${wp_db}';"
sudo mysql -e "SHOW GRANTS FOR '${wp_user}'@'%';"

echo "БД и пользователь для WordPress созданы"
