# MariaDB Master-Slave Replication in Docker with Ansible Automation

Автоматизированный стенд для разворачивания классической асинхронной репликации MariaDB 10.11 в Docker-контейнерах на двух независимых хостах (Debian 12) с помощью Ansible и Bash.

## 🚀 Архитектура и стек

* **OS:** Debian 12 (Bookworm)
* **Containerization:** Docker & Docker Compose
* **Database:** MariaDB 10.11
* **Automation:** Ansible (Provisioning) + Bash (Replication Bootstrap)

### Особенности решения:
1. **Разделение зон ответственности:** Ansible отвечает за подготовку окружения (установка пакетов, конфигурация, запуск Compose), а Bash-скрипт содержит динамическую логику репликации.
2. **Бесшовный bootstrap:** Использование `mysqldump --master-data=2` позволяет автоматически извлекать имя бинарного лога и точную позицию (`LOG_FILE` и `LOG_POS`) без остановки Master-сервера.
3. **Безопасность:** Отсутствие прокси-костылей (`rinetd`), изолированные сети контейнеров и явное разграничение прав пользователя репликации (`replica_pdns`@`%`).

---

## 🛠 Быстрый старт

### 1. Подготовка инвентаря
Скопируйте пример файла конфигурации и укажите реальные IP-адреса ваших хостов:
```
cp inventory.ini.example inventory.ini
nano inventory.ini
```
### 2. Разворачивание инфраструктуры через Ansible
Запустите плейбук для установки Docker, AppArmor, копирования конфигов и старта контейнеров:
```
ansible-playbook -i inventory.ini site.yml
```
### 3. Запуск репликации
3.1. На Master-узле выполните скрипт генерации дампа и координат:
```
cd /opt/mariadb_cluster && ./setup_replication.sh
```
3.2. Скопируйте сгенерированные файлы на Slave-узел:
```
scp /tmp/pdns_dump.sql /tmp/start_slave.sql root@<SLAVE_IP>:/tmp/
```
3.3. На Slave-узле импортируйте БД и запустите репликацию:
```
docker exec -i mariadb_node mysql -uroot -prootpassword pdns < /tmp/pdns_dump.sql
docker exec -i mariadb_node mysql -uroot -prootpassword < /tmp/start_slave.sql
```
### Проверка работоспособности
Выполните команду на Slave-узле:
```
docker exec -it mariadb_node mysql -uroot -prootpassword -e "SHOW SLAVE STATUS\G"
```
Ожидаемый результат:
```
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
```
