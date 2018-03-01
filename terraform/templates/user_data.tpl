#!/bin/bash +xe


exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

yum update -y
yum install -y docker
service docker start

docker pull ${docker_image}

docker run -d -p 80:80 ${docker_image}

docker ps

echo "nothing to do here anymore! :) "
