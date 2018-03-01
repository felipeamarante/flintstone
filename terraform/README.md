## Hello!

This is a terraform template which performs a rolling container deployment with some very basic aws components.


### Usage

  * Download and install latest version of terraform 
  * change your desired parameters at env.tf (vpc, subnet, docker_image) 
  * terraform init 
  * terraform apply 
  * Change the docker image at docker_image at env.tf 
  * terraform apply 
  * behold the magic!


#### Info!
  Docker run params can be changed at templates/user_data.tpl
