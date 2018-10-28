FROM ubuntu:18.04
MAINTAINER Paranin Pavel <xackmaster@gmail.com>

WORKDIR /app
VOLUME /app
COPY startup.sh /startup.sh

RUN apt-get install -y mysql mysql-client
COPY my.cnf /etc/mysql/my.cnf

EXPOSE 3306
CMD ["/startup.sh"]
