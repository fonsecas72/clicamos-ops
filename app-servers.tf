
resource "aws_elb" "elb_app" {
  name = "elb"

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
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 60
  subnets         = ["${split(",", module.network.public_subnet_ids)}"]
  security_groups = ["${aws_security_group.elb_web.id}"]

  tags {
    Name = "elb"
  }
}

resource "aws_autoscaling_group" "asg_app" {
  lifecycle { create_before_destroy = true }

  name = "asg-app - ${aws_launch_configuration.lc_app.name}"
  max_size = 1
  min_size = 1
  wait_for_elb_capacity = 1
  desired_capacity = 1
  health_check_grace_period = 300
  health_check_type = "ELB"
  launch_configuration = "${aws_launch_configuration.lc_app.id}"
  load_balancers = ["${aws_elb.elb_app.id}"]
  vpc_zone_identifier = ["${aws_subnet.private_az1.id}", "${aws_subnet.private_az2.id}", "${aws_subnet.private_az3.id}"]

  tag {
    key = "Name"
    value = "app${count.index}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "lc_app" {
  lifecycle { create_before_destroy = true }

  image_id = "${var.ami}"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.default.id}", "${aws_security_group.app.id}"]
  user_data = "${file("user_data/app-server.sh")}"
}
