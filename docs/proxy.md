# Инструкция по развертыванию proxy сервера

## Proxy сервер состоит из:
 - Docker для развертывания proxy сервера
 - Агент node_expoter для передачи метрик в prometheus
 - Filebeat для передачи логовоч в logstash

## Файлы использумые при развертыании

### Скрипты
- `scripts/proxy.sh` (для развертывания docker контейнера с  wordpress c nginx)
- `scripts/agents.sh` (для установки агентов node_exporter и filebeat)

### Docker-compose файлы
- docker/nginx/docker-compose.yml

### Конфигурационные файлы
- configs/filebeat/filebeat.yml
- configs/Nginx/nginx.conf

## Порядок развертывания

### Настройка Proxy сервера
1. Подключиться к серверу `proxy`, повысить права до root.
2. Скачать скрипт proxy.sh, выполнив команду:<br/>
```curl -O https://raw.githubusercontent.com/RanisAbit/otus/refs/heads/main/scripts/proxy.sh```
3. Сделать файл исполняемым.
```chmod +x proxy.sh```
4. Запустить скрипт c аргументами, в качестве аргументов необходимо передать IP адреа backend-1 и backend-2 <br.>
```./proxy.sh ip_adress ip_adress```
5. Проверить работу балансироввки при помощи команды: <br/>
```curl -S http://127.0.0.1/health.txt ```<br/>
В ответе должны меня hostname backend сереров.

## Примичание