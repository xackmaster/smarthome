#!/bin/bash
# Codepage UTF-8

# aka Олло Александр aka ekzorchik (Telegram: @ekzorchik)

# Подготавливаю систему Ubuntu Bionic Server к инсталляции MajorDoMo
rm -Rf /var/lib/apt/lists
rm -f /var/lib/dpkg/lock
sed -i '/Prompt/s/lts/never/' /etc/update-manager/release-upgrades

dpkg --configure -a

#Timezone
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime

mv /var/lib/dpkg/lock /var/lib/dpkg/lock-backup

apt-get update && apt-get upgrade -y
# Удаляю из системы пакет Cloud Init
bash -c "echo 'datasource_list: [ None ]' -s tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg"
apt purge -y cloud-init
rm -Rf /etc/cloud /var/lib/cloud
#Устанавливаю необходимые пакеты
apt-get install -y git systemctl apache2 apache2-bin apache2-utils libapache2-mod-php7.2 php7.2-curl mysql-client mysql-server dbconfig-mysql php7.2-mbstring php7.2-mysql php-mysql ntpdate

#NTP
bash -c "echo '@reboot /usr/sbin/ntpdate -s 0.pool.ntp.org > /dev/null'" | -s tee /var/spool/cron/crontabs/root

mysqladmin -u root password 712mbddr@
# Включаем мод rewrite для Apache
a2enmod rewrite
# Скачиваем систему MajorDoMo с GitHab
rm -rf /var/lib/mysql/db_terminal
rm -Rf /usr/src/majordomo/
git clone https://github.com/sergejey/majordomo.git /usr/src/majordomo
# Переносим систему в директорию WEB-сервера
cp -rp /usr/src/majordomo/* /var/www
cp -rp /usr/src/majordomo/.htaccess /var/www
# Создаем конфигурационный файл для системы
cp /var/www/config.php.sample /var/www/config.php
# Назначаем права и владельца для директории с системой
chown -R www-data:www-data /var/www
find /var/www/ -type f -exec chmod 0666 {} \;
find /var/www/ -type d -exec chmod 0777 {} \;
# Создаю базу, пользователя и пароля для сервиса mysql
mysql -u root -p712mbddr@ -e "drop database db_terminal"
mysql -u root -p712mbddr@ -e "drop user 'us_majordomo'@'localhost'"
mysql -u root -p712mbddr@ -e "create database db_terminal character set utf8"
mysql -u root -p712mbddr@ db_terminal < /var/www/db_terminal.sql
mysql -u root -p712mbddr@ -e "create user 'us_majordomo'@'localhost' identified by '612mbddr@'"
mysql -u root -p712mbddr@ -e "grant all on db_terminal.* to 'us_majordomo'@'localhost';"
# Прописываю в файле сервиса MajorDoMo данные по пользователю MySQL, базе и паролю
cp /var/www/config.php.sample /var/www/config.php
sed -i "s/Define('DB_NAME', '')/Define('DB_NAME','db_terminal')/" /var/www/config.php
sed -i "s/Define('DB_USER', 'root')/Define('DB_USER','us_majordomo')/" /var/www/config.php
sed -i "s/Define('DB_PASSWORD', '')/Define('DB_PASSWORD','612mbddr@')/" /var/www/config.php

# Настраиваем Apache
sed -i 's/None/All/g' /etc/apache2/apache2.conf
echo "ServerName localhost" | tee -a /etc/apache2/apache2.conf
sed -i '/short_open_tag/s/Off/On/' /etc/php/7.2/apache2/php.ini 
sed -i '/error_reporting/s/~E_DEPRECATED & ~E_STRICT/~E_NOTICE/' /etc/php/7.2/apache2/php.ini
sed -i '/max_execution_time/s/30/90/' /etc/php/7.2/apache2/php.ini
sed -i '/max_input_time/s/60/180/' /etc/php/7.2/apache2/php.ini
sed -i '/post_max_size/s/8/200/' /etc/php/7.2/apache2/php.ini
sed -i '/upload_max_filesize/s/2/50/' /etc/php/7.2/apache2/php.ini
sed -i '/max_file_uploads/s/20/150/' /etc/php/7.2/apache2/php.ini
#timezone
sed -i 's#^;date\.timezone[[:space:]]=.*$#date.timezone = "Europe/Moscow"#' /etc/php/7.2/apache2/php.ini

# Настраиваем PHP для коммандной строки
sed -i '/short_open_tag/s/Off/On/' /etc/php/7.2/cli/php.ini

# Отключаем режим "Strict mode" для MySQL (для избавления от наследственных ошибок)
tee /etc/mysql/conf.d/disable_strict_mode.cnf << EOF
[mysqld]
sql_mode=IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
EOF

# Создаем описание сервиса для запуска основного цикла системы

tee /etc/systemd/system/majordomo.service << EOF
[Unit]
Description=MajorDoMo

[Service]
Requires=mysql.service
Requires=apache2.service
Type=simple
WorkingDirectory=/var/www
ExecStart=/usr/bin/php /var/www/cycle.php
Restart=always
User=www-data
Group=www-data

[Install]
WantedBy=multi-user.target
EOF

# Обновляем и перезапускаем службы
systemctl daemon-reload
apache2ctl restart
service mysql restart
# Добавляем главный цикл системы в автозагрузку
systemctl daemon-reload
systemctl enable majordomo.service
systemctl start majordomo.service

#замене DocumentRoot с /var/www/html on /var/www
sed -i 's!/var/www/html!/var/www!g' /etc/apache2/apache2.conf /etc/apache2/sites-available/000-default.conf
systemctl reload apache2

usermod -aG audio www-data

#Cycle in crontab
echo "@reboot /usr/bin/php /var/www/cycle.php" | tee -a /var/spool/cron/crontabs/root
systemctl restart apache2

#Локализация серверной Ubuntu 18.04 Server
locale-gen ru_RU

# Смена языка интерфейса
mysql -u us_majordomo -p612mbddr@ -h localhost db_terminal -e "update settings set value='Europe/Moscow' where id='74'";
#по умолчанию данной строки в таблице нет и ее нужно добавить
mysql -u us_majordomo -p612mbddr@ -h localhost db_terminal -e "delete from settings where NAME='SITE_LANGUAGE'"
mysql -u us_majordomo -p612mbddr@ -h localhost db_terminal -e "insert into settings(NAME,TITLE,VALUE,TYPE) VALUES('SITE_LANGUAGE','Language','ru','text')"
#mysql -u us_majordomo -p612mbddr@ -h localhost db_terminal -e "update settings set value='ru' where Name='SITE_LANGUAGE'";
mysql -u us_majordomo -p612mbddr@ -h localhost db_terminal -e "update settings set value='ru' where name='VOICE_LANGUAGE'";
mysql -u us_majordomo -p612mbddr@ -h localhost db_terminal -e "update users set EMAIL='support@ekzorchik.ru'"
mysql -u root -p712mbddr@ -h localhost db_terminal -e "flush privileges"