# Инструкция по развертыванию backend серверов

## Backend сервер состоит из:
 - Mysql в репликации master/slave
 - Docker для развертывания wordpress
 - Агент node_expoter для передачи метрик в prometheus
 - Filebeat для передачи логовоч в logstash

## Файлы использумые при развертыании

### Скрипты
- `scripts/sql-master.sh` (для установки и настройки master-server)
- `scripts/sql-slave.sh` (для установки и настройки slave-server)
- `scripts/sql-wp.sh` (для настройки БД для wordpress)
- `scripts/wordpress.sh` (для развертывания docker контейнера с  wordpress)
- `scripts/proxy.sh` (для развертывания docker контейнера с  wordpress c nginx)
- `scripts/agents.sh` (для установки агентов node_exporter и filebeat)
- `scripts/sqldump.sh` (для создания потабличного бэкапа с сохранением позии бинлога)

### Docker-compose файлы
- docker/wordpress/docker-compose.yml
- docker/nginx/docker-compose.yml
  
### Конфигурационные файлы
- configs/sql-master-server/mysqld.cnf
- configs/sql-slave-server/mysqld.cnf
- configs/filebeat/filebeat.yml
- configs/Nginx/nginx.conf

## Порядок развертывания
### Настройка сервера `backend-1`
1. Подключиться к серверу `backend-1`, повысить права до root.
2. Скачать скрипт sql-master.sh, выполнив команду:<br/>
```curl -O https://raw.githubusercontent.com/RanisAbit/otus/refs/heads/main/scripts/sql-master.sh ```<br/>
Провервить что скрипт скачался корректно<br/>
```cat sql-master.sh```<br/>
Если при скачивании скрипта возникли проблемы нужно создать файл sql-master.sh.<br/>
```touch sql-master.sh```<br/>
Открыть в текстовом редакторе и скопировать содежимое из scripts/sql-master.sh в файл.<br/>
3. Сделать файл исполняемым.
```chmod +x sql-master.sh```
4. Запустить скрипт
```./sql-master.sh```
5. Во время выполенения скрипта нужно создать пароль для пользвателя repl, `вводимый пароль не будет отображаться`.
6. После выполнения скрипта будет отображен статус master сервера.

### Настройка сервера `backend-2`
1. Подключиться к серверу `backend-2`, повысить права до root.
2. Скачать скрипт sql-slave.sh, выполнив команду:<br/>
```curl -O https://raw.githubusercontent.com/RanisAbit/otus/refs/heads/main/scripts/sql-slave.sh ```<br/>
Провервить что скрипт скачался корректно<br/>
```cat sql-slave.sh```<br/>
Если при скачивании скрипта возникли проблемы нужно создать файл sql-slave.sh.<br/>
```touch sql-slave.sh```<br/>
Открыть в текстовом редакторе и скопировать содежимое из scripts/sql-slave.sh в файл.<br/>
3. Сделать файл исполняемым.
```chmod +x sql-slave.sh```
4. Запустить скрипт
```./sql-slave.sh```
5. Во время выполенения скрипта нужно ввести IP адрес master-server
6. Во время выполенения скрипта нужно ввести пароль для пользвателя repl, `вводимый пароль не будет отображаться`.
6. После выполнения скрипта будет отображен статус master сервера.

### Настройка БД для  Wordpress
1. Подключиться к серверу `backend-1`, повысить права до root.
2. Скачать скрипт sql-wp.sh, выполнив команду:<br/>
```curl -O  https://raw.githubusercontent.com/RanisAbit/otus/refs/heads/main/scripts/sql-wp.sh ```<br/>
Провервить что скрипт скачался корректно<br/>
```cat sql-wp.sh```<br/>
Если при скачивании скрипта возникли проблемы нужно создать файл sql-wp.sh.<br/>
```touch sql-wp.sh```<br/>
Открыть в текстовом редакторе и скопировать содежимое из scripts/sql-wp.sh в файл.<br/>
3. Сделать файл исполняемым.
```chmod +x sql-wp.sh```
4. Запустить скрипт
```./sql-wp.sh```
5. Во время выполенения скрипта нужно создать пароль для пользвателя wordpress, `вводимый пароль не будет отображаться`.
6. После отображения уведомлления о том что БД и пользователь создан, нужно переключиться на сервер `backend-2`
7. Выполнить команду:
   ```sudo mysql -e "show databases;"``` <br/>
8. Убедиться что репликация работает, отображается база wordpress
   
### Настройка Wordpress
1. Подключиться к серверу `backend-1`, повысить права до root.
2. Скачать скрипт wordpress.sh, выполнив команду:<br/>
```curl -O https://raw.githubusercontent.com/RanisAbit/otus/refs/heads/main/scripts/wordpress.sh```
3. Сделать файл исполняемым.
```chmod +x wordpress.sh```
4. Запустить скрипт
```./wordpress.sh```
5. Во время выполенения скрипта нужно ввести адрес Master-server, и пароль для подключения к базе wordpress, `вводимый пароль не будет отображаться`.
6. После выполнени скрипта проверить что docker контейнер поднялся <br/>
```sudo docker ps -a```
7. Повторить шаги с 2 по 6 на сервере `backend-2`
8. На каждом из серверов запустить команду для проверки работы web сервера <br/>
```curl -S http://127.0.0.1:8080/health.txt```

### Настройка Proxy сервера
1. Подключиться к серверу `proxy`, повысить права до root.
2. Скачать скрипт proxy.sh, выполнив команду:<br/>
```curl -O https://raw.githubusercontent.com/RanisAbit/otus/refs/heads/main/scripts/proxy.sh```
3. Сделать файл исполняемым.
```chmod +x proxy.sh```
4. Запустить скрипт c аргументами, в качестве аргументов необходимо передать IP адреа backend-1 и backend-2
```./proxy.sh ip_adress ip_adress```
5.


## Примичание
- В скриптах для установки sql уже вшит пользователь repl, необходимо только придумать и ввести пароль для данной УЗ.
- В скрипте sql-wp уже прописаны имя базы и пользователя (wordpress/wordpress), необходимо только задать пароль.
- docker-compose.yml файлы и конфигурационные файлы уже присутсвуют в самих скриптах, и передаются через функцию EOF для избежания проблем во время развертывания. При доработке файлов необходимо так же `внести изменения в скрипте!`.
  