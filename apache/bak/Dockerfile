FROM ubuntu:18.04

MAINTAINER Paranin Pavel <xackmaster@gmail.com>

# Подготавливаю систему Ubuntu Bionic Server к инсталляции MajorDoMo
RUN rm -Rf /var/lib/apt/lists
RUN rm -f /var/lib/dpkg/lock
RUN sed -i '/Prompt/s/lts/never/' /etc/update-manager/release-upgrades

RUN dpkg --configure -a

#Timezone
RUN rm -f /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime

RUN mv /var/lib/dpkg/lock /var/lib/dpkg/lock-backup

RUN apt-get update
RUN apt-get upgrade -y
# Удаляю из системы пакет Cloud Init
RUN bash -c "echo 'datasource_list: [ None ]' sudo -s tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg"
RUN apt purge -y cloud-init
RUN rm -Rf /etc/cloud /var/lib/cloud
#Устанавливаю необходимые пакеты
RUN apt-get install -y git apache2 apache2-bin apache2-utils libapache2-mod-php7.2 php7.2-curl php7.2-mbstring php7.2-mysql php-mysql ntpdate

#NTP
RUN bash -c "echo '@reboot /usr/sbin/ntpdate -s 0.pool.ntp.org > /dev/null'" | sudo -s tee /var/spool/cron/crontabs/root

# Включаем мод rewrite для Apache
RUN a2enmod rewrite

# Скачиваем систему MajorDoMo с GitHab
RUN rm -Rf /usr/src/majordomo/
RUN git clone https://github.com/sergejey/majordomo.git /usr/src/majordomo

# Переносим систему в директорию WEB-сервера
RUN cp -rp /usr/src/majordomo/* /var/www
RUN cp -rp /usr/src/majordomo/.htaccess /var/www

# Создаем конфигурационный файл для системы
RUN cp /var/www/config.php.sample /var/www/config.php

# Назначаем права и владельца для директории с системой
RUN chown -R www-data:www-data /var/www
RUN find /var/www/ -type f -exec sudo chmod 0666 {} \;
RUN find /var/www/ -type d -exec sudo chmod 0777 {} \;

# Прописываю в файле сервиса MajorDoMo данные по пользователю MySQL, базе и паролю
RUN cp /var/www/config.php.sample /var/www/config.php
RUN sed -i "s/Define('DB_NAME', '')/Define('DB_NAME','db_terminal')/" /var/www/config.php
RUN sed -i "s/Define('DB_USER', 'root')/Define('DB_USER','us_majordomo')/" /var/www/config.php
RUN sed -i "s/Define('DB_PASSWORD', '')/Define('DB_PASSWORD','612mbddr@')/" /var/www/config.php

# Настраиваем Apache
RUN sed -i 's/None/All/g' /etc/apache2/apache2.conf
RUN echo "ServerName localhost" | tee -a /etc/apache2/apache2.conf
RUN sed -i '/short_open_tag/s/Off/On/' /etc/php/7.2/apache2/php.ini 
RUN sed -i '/error_reporting/s/~E_DEPRECATED & ~E_STRICT/~E_NOTICE/' /etc/php/7.2/apache2/php.ini
RUN sed -i '/max_execution_time/s/30/90/' /etc/php/7.2/apache2/php.ini
RUN sed -i '/max_input_time/s/60/180/' /etc/php/7.2/apache2/php.ini
RUN sed -i '/post_max_size/s/8/200/' /etc/php/7.2/apache2/php.ini
RUN sed -i '/upload_max_filesize/s/2/50/' /etc/php/7.2/apache2/php.ini
RUN sed -i '/max_file_uploads/s/20/150/' /etc/php/7.2/apache2/php.ini

#timezone
RUN sed -i 's#^;date\.timezone[[:space:]]=.*$#date.timezone = "Europe/Moscow"#' /etc/php/7.2/apache2/php.ini

# Настраиваем PHP для коммандной строки
RUN sed -i '/short_open_tag/s/Off/On/' /etc/php/7.2/cli/php.ini


RUN tee /etc/systemd/system/majordomo.service << EOF
EOF

# Обновляем и перезапускаем службы
RUN systemctl daemon-reload
RUN apache2ctl restart

# Добавляем главный цикл системы в автозагрузку
RUN systemctl start majordomo.service

#замене DocumentRoot с /var/www/html on /var/www
RUN sed -i 's!/var/www/html!/var/www!g' /etc/apache2/apache2.conf /etc/apache2/sites-available/000-default.conf
RUN systemctl reload apache2

RUN usermod -aG audio www-data

#Cycle in crontab
RUN echo "@reboot /usr/bin/php /var/www/cycle.php" | tee -a /var/spool/cron/crontabs/root
RUN systemctl restart apache2

#Локализация серверной Ubuntu 18.04 Server
RUN locale-gen ru_RU