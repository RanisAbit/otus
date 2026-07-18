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
- `scripts/agents.sh` (для установки агентов node_exporter и filebeat)
- `scripts/sqldump.sh` (для создания потабличного бэкапа с сохранением позии бинлога)

### Docker-compose файлы
- docker/wordpress/docker-compose.yml

### Конфигурационные файлы
- configs/sql-master-server/mysqld.cnf
- configs/sql-slave-server/mysqld.cnf
- configs/filebeat/filebeat.yml

## Порядок развертывание
### Настройка сервера `backend-1`
1. Подключиться к серверу `backend-1`, повысить права до root.
2. Скачать скрипт sql-master.sh, выполнив команду:
```curl -O https://raw.githubusercontent.com/RanisAbit/otus/refs/heads/main/scripts/sql-master.sh```
Провервить что скрипт скачался корректно
```cat sql-master.sh```
Если при скачивании скрипта возникли проблемы нужно создать файл sql-master.sh.
```touch sql-master.sh```
Открыть в текстовом редакторе и скопировать содежимое из scripts/sql-master.sh в файл.
3. Сделать файл исполняемым.
```chmod +x sql-master.sh```
4. Запустить скрипт
```./sql-master.sh```
5. Во время выполенения скрипта нужно создать пароль для пользвателя repl, `вводимый пароль не будет отображаться`.
6. После выполнения скрипта будет отображен статус master сервера.

## Примичание

docker-compose.yml файлы и конфигурационные файлы уже присутсвуют в самих скриптах, и передаются через функцию EOF для избежания проблем во время развертывания. При доработке файлов необходимо так же `внести изменения в скрипте!`.
  