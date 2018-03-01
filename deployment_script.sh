#!/bin/bash +xe

ELBNAME=$1
INSTANCEID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AWSREGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}')
REPO=$2

echo "######################################################"
echo "Deployment ELB is:"  ${ELBNAME}
echo "Instance Id id:" ${INSTANCEID}
echo "Repo is : "${REPO} 
echo "Region is :"${AWSREGION}
echo "######################################################"


function checkDependencies(){
	#Tests if all dependencies are met
	for CMD in aws curl docker ; do
  		type ${CMD} &> /dev/null || { echo "[WARN] - This script uses the command: [ ${CMD} ]."; return 1;}
	done
}

function installDep(){
        #Installing dependencies if its a first run	
	yum install -y aws-cli docker curl
	service docker start
	if docker info; then
		echo "docker is running!"
	fi
}



function deregisterelb(){
        echo "DEREGISTER INSTANCE ${INSTANCEID}"
	aws elb deregister-instances-from-load-balancer --instances ${INSTANCEID} --load-balancer-name ${ELBNAME} --region ${AWSREGION}
	echo "INSTANCE DEREGISTRED"
}



function deploy(){

# Stopping all containers
echo "Stopping containers"
docker kill $(docker ps -q) || true


# running containers 
echo "Running containers"
docker run -d -p 80:80 ${REPO} && echo "Containers running"

docker ps


}


function registertoelb(){
	echo "REGISTERING ${INSTANCEID}"
	aws elb register-instances-with-load-balancer --instances ${INSTANCEID} --load-balancer-name ${ELBNAME} --region ${AWSREGION}
	echo "INSTANCE REGISTERED"
}

checkDependencies || installDep
deregisterelb
deploy
registertoelb
