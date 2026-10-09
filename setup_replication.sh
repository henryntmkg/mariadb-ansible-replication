#!/bin/bash
set -e

# Переменные (укажите IP Master-сервера)
MASTER_IP="192.168.1.10"
REPL_USER="replica_pdns"
REPL_PASS="replicapassword"
DB_NAME="pdns"

echo "=== [1/4] Создаем пользователя репликации на Master ==="
docker exec -i mariadb_node mysql -uroot -prootpassword -e "
CREATE USER IF NOT EXISTS '$REPL_USER'@'%' IDENTIFIED BY '$REPL_PASS';
GRANT REPLICATION SLAVE ON *.* TO '$REPL_USER'@'%';
FLUSH PRIVILEGES;
"

echo "=== [2/4] Снимаем дамп с зафиксированной позицией Binlog ==="
docker exec -i mariadb_node mysqldump -uroot -prootpassword --master-data=2 --single-transaction --databases $DB_NAME > /tmp/pdns_dump.sql

echo "=== [3/4] Извлекаем LOG_FILE и LOG_POS из дампа ==="
LOG_FILE=$(grep -m1 "MASTER_LOG_FILE" /tmp/pdns_dump.sql | sed -n "s/.*MASTER_LOG_FILE='\([^']*\)'.*/\1/p")
LOG_POS=$(grep -m1 "MASTER_LOG_POS" /tmp/pdns_dump.sql | sed -n "s/.*MASTER_LOG_POS=\([0-9]*\).*/\1/p")

echo "Найдены параметры: File = $LOG_FILE | Position = $LOG_POS"

echo "=== [4/4] Сохраняем команду восстановления для Slave ==="
cat <<EOF > /tmp/start_slave.sql
STOP SLAVE;
CHANGE MASTER TO
  MASTER_HOST='$MASTER_IP',
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASS',
  MASTER_LOG_FILE='$LOG_FILE',
  MASTER_LOG_POS=$LOG_POS;
START SLAVE;
EOF

echo "Скрипт дампа завершен. Файлы /tmp/pdns_dump.sql и /tmp/start_slave.sql готовы."
