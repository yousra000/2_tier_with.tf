resource "aws_launch_template" "frontend" {
  name   = "frontend-"
  image_id      = data.aws_ami.fedora.id
  instance_type = "t2.micro"
  

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_instance_profile.name
  }

  user_data = filebase64("userdata.sh")

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.front.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "frontend-instance"
    }
  }
}


resource "aws_lb" "frontend-lb" {
  name               = "frontend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public_subnet[*].id
  depends_on         = [aws_internet_gateway.igw_vpc]
}

resource "aws_lb_target_group" "frontend-tg" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.frontend-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend-tg.arn
  }
}

resource "aws_launch_template" "backend" {
  name_prefix   = "backend-"
  image_id      = data.aws_ami.fedora.id
  instance_type = "t2.micro"

  user_data = filebase64("backend.sh")

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.back.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "backend-instance"
    }
  }
}


resource "aws_lb" "backend-lb" {
  name               = "backend-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb_sg.id]
  subnets            = aws_subnet.backend_private[*].id
  depends_on         = [aws_internet_gateway.igw_vpc]
}


resource "aws_lb_target_group" "backend-tg" {
  name     = "backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.backend-lb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend-tg.arn
  }
}
