#TF WOW#
variable "ami-id" {
  # Public ec2 newest ami.
  default = "ami-d834aba1"


}
variable "availability_zones" {
  default = "eu-west-1a,eu-west-1b,eu-west-1c"
  description = "List of availability zones"
}

variable "subnets"{
 # Change with the Subnets on your account - Subnets must reside at your selected VPC :)
 default = "subnet-xxxxxx,subnet-xxxxx,subnet-xxxxxx"

}

variable "vpc"{
 # Change with the VPC in your account
 default = "vpc-xxxxxx"

}


provider "aws" {
    region = "eu-west-1"
}


# Change the docker_image value to deploy your docker image. Docker run params can be changed at templates/user_data.tpl
resource "template_file" "user_data" {
    template = "${file("templates/user_data.tpl")}"
    vars {
        docker_image = "httpd"
    }
}


resource "aws_security_group" "default" {
  name = "tf_example_sg"
  description = "Default security group that allows inbound and outbound traffic from all instances in the VPC"
  vpc_id = "${var.vpc}"

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
}


resource "aws_elb" "elb_app" {
  name = "app-elb"
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 2
    timeout = 10
    target = "HTTP:80/"
    interval = 15
  }

  cross_zone_load_balancing = true
  idle_timeout = 60
  subnets         = ["${split(",", var.subnets)}"]
  security_groups = ["${aws_security_group.default.id}"]

  tags {
    Name = "app-elb"
  }
}


resource "aws_autoscaling_group" "asg_app" {
  lifecycle { create_before_destroy = true }

  # spread the app instances across the availability zones
  availability_zones = ["${split(",", var.availability_zones)}"]

  # interpolate the LC into the ASG name so it always forces an update
  name = "asg-app-${aws_launch_configuration.lc_app.name}"
  max_size = 5
  min_size = 2
  wait_for_elb_capacity = 2
  desired_capacity = 2
  health_check_grace_period = 120
  health_check_type = "ELB"
  launch_configuration = "${aws_launch_configuration.lc_app.name}"
  load_balancers = ["${aws_elb.elb_app.id}"]
  vpc_zone_identifier = ["${split(",", var.subnets)}"]

  tag {
    key = "Name"
    value = "app${count.index}"
    propagate_at_launch = true
  }
}



resource "aws_launch_configuration" "lc_app" {
    lifecycle { create_before_destroy = true }

    image_id = "${var.ami-id}"
    instance_type = "t2.large"
    security_groups = ["${aws_security_group.default.id}"]
    user_data = "${template_file.user_data.rendered}"

}

