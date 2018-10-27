build image:

docker build --tag="majordomo" docker/build

___________________________________________

enter into container:

docker run -it majordomo bash

___________________________________________

remove all containers:

docker rm -f $(docker ps -a | grep "docker_" | awk '{print $1}')



Запуск

1) sudo docker run -d --name majordomo-webserver -p 80:80 -p 443:443 -p 8001:8001 -v /md:/app webdevops/php-apache:alpine

Запускаем с ключом -d (detached), считайте в режиме демона с именем majordomo-webserver, выставляя наружу порты 80, 443, 8001 и делая маппинг между папкой /md в материнской ОС и папкой /app внутри контейнера. 
Если вы еще не знакомы с Docker, то вы увидите, как система скачивает образ webdevops/php-apache:alpine, состоящий из многих слоев. 
Все в порядке. Вместе эти слои сформируют ваш образ, который затем можно использовать для многократного запуска контейнеров, давая каждому из них свои имена, параметры и прочее. 
