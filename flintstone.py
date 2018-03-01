import click, boto3, docker, subprocess, os, fabric, time
from retrying import retry
from fabric.api import *


repo_user = os.environ['DOCKER_REPO_USER']
repo_secret = os.environ['DOCKER_REPO_SECRET']
ssh_user = "ec2-user"
ssh_key_path = "/root/.ssh/your-ssh.pem"


@click.command()
@click.option('--image', help='Your Local Docker Image')
@click.option('--loadbalancer','-elb', help='Elastic Load Balancer Name')
@click.argument('hosts', nargs=-1)
def cli(image,loadbalancer,hosts):
    """Usage : flintstone.py --image dockerhub/whatever --elb myelb host1 host2 host3 hostn"""

    #Checking and dealing with the Docker Image

    def checkImage(dockerimage):
        c = docker.from_env()
        print ("Searchin for Local image " + dockerimage)
        try:
            image = c.images.get(name=dockerimage)
        except:
            raise
            print ("Couldn't find image %s" % dockerimage)
            exit (1)
        print ("Docker image %s found, proceeding to next step!" % dockerimage)

    checkImage(image)


    # Pushing Docker Image to remote repo

    @retry(stop_max_attempt_number=5,wait_exponential_multiplier=500, wait_exponential_max=5000)
    def pushImage(dockerimage,repo_user,repo_secret):
        print ("Pushing Image "+ dockerimage +"  to repository")
        c = docker.from_env()
        try:
            c.login(username=repo_user, password=repo_secret, reauth=True)
            output = c.images.push(image, tag="latest")
        except:
            raise
            print ("Something went wrong when pushing the image. Exiting.")
            exit (1)

        print (output)
        print ("Image pushed to repository accordingly... Mooving on")

    pushImage(image,repo_user,repo_secret)



    #Checking if the ELB Exists

    @retry(stop_max_attempt_number=5,wait_exponential_multiplier=500, wait_exponential_max=5000)
    def checkElb(elbname):
        client = boto3.client('elb')
        try:
            print ("Looking for load balancer " + elbname)
            elb = client.describe_load_balancers(LoadBalancerNames=[elbname])
        except:
            print ("Something went wrong with the LOAD BALANCER!, call the cops! - Retying")
            raise
        print("Loadbalancer found!")
        print(elb)

    checkElb(loadbalancer)


    #Working with Fabric

    def fabricate(args,loadbalancer):
        print ("Running fabric to execute deployment instrunctions")

        # Fabric Environment Configuration
        env.hosts = args
        env.user = ssh_user
        env.key_filename = ssh_key_path
        env.skip_bad_hosts = True

        # For some unknown reason, the retries exponential backoff decorator is not working w/ Fabric... had to workaround with this very rudimentar technique.
        def copy_deployment_script(retry=False):
            with settings(warn_only=True):
                if put("*.sh", "/tmp/", mode="0755").failed:
                    if retry is True:
                        abort("Task failed miserably")
                    print ("something went wrong, retrying")
                    time.sleep(5)
                    copy_deployment_script(retry=True)

        def copy_docker_creds(retry=False):
            with settings(warn_only=True):
                # Resolve issues whenever running for the first time #
                run("mkdir -p ~/.docker/")
                if put("~/.docker/config.json", "~/.docker/config.json", mode="0600").failed:
                    if retry is True:
                        abort("Task failed miserably")
                    print ("something went wrong, retrying")
                    time.sleep(5)
                    copy_docker_creds(retry=True)

        def run_task(elb, image):
            run("sudo sh /tmp/deployment_script.sh " + elb + " " + image)

        execute(copy_deployment_script)
        execute(copy_docker_creds)
        execute(run_task, loadbalancer, image)
    fabricate(hosts,loadbalancer)



if __name__ == '__main__':
    cli()

