#!/bin/bash
dir="/tmp/sql_dump"
db=$(sudo mysql '--skip-column-names' -e "SHOW DATABASES";)
bin_log="$dir/binlog_postition.$(date +%Y%m%d).txt "
sudo mkdir -p "$dir"
sudo mysql -e "show replica status\G" | grep -w  Source_Log_File > $bin_log
sudo mysql -e "show replica status\G" | grep -w Exec_Source_Log_Pos >> $bin_log

for base in $db; do
    mkdir -p "$dir/$base"
        tables=$(sudo mysql '--skip-column-names' -e "SHOW TABLES FROM $base";)
            for table in $tables; do
            sudo mysqldump --set-gtid-purged=OFF --add-drop-table --single-transaction --quick $base $table > "$dir/$base/$table.sql" 2>/dev/null
            done
done