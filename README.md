## Custom Deployment Tool - flintstone
---

## Usage:
  * pip install -r requirements.txt
  * edit env.sh with your beloved docker credentials
  * source env.sh
  * python flintstone.py --image dockerhub/whatever --elb myelbname host1 host2 host3 hostn


## What Flintstone will do?
  * Check if your Load Balancer exists in your AWS Account
  * Check if the docker image provided is in your local image repository
  * Authenticate to Dockerhub, push the image to docker hub as latest.
  * Connect through the hosts by ssh (currently ec2-user set as user)
  * Deregister Instance from ELB
  * Install docker if not installed || Kill the containers running and spin up a new container with the recently pushed image.
  * Register instance to ELB if sucess
  * Proceed to next host.


## Important
  Your ec2 instances must have a IAM role which allows interaction with ELB (DeregisterInstancesFromLoadBalancer and RegisterInstancesWithLoadBalancer)


## Discalimer
    This code is actually a comparison on how terraform and imutable deployments can be good and safe for your architecture. Please check terraform directory and readme in this repository


Felipe A.
