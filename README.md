build image:

docker build --tag="majordomo" docker/build

___________________________________________

enter into container:

docker run -it majordomo bash

___________________________________________

remove all containers:

docker rm -f $(docker ps -a | grep "docker_" | awk '{print $1}')
