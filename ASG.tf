resource "aws_autoscaling_group" "FrontendASG" {
  name_prefix          = "frontend-asg-"
  desired_capacity     = 2
  max_size             = 3
  min_size             = 2
  health_check_type    = "EC2"
  vpc_zone_identifier = aws_subnet.frontend_private[*].id
  target_group_arns   = [aws_lb_target_group.frontend-tg.arn]

  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }

}

resource "aws_autoscaling_group" "BackendASG" {
  name_prefix          = "backend-asg-"
  desired_capacity     = 2
  max_size             = 3
  min_size             = 2
  health_check_type    = "EC2"
  vpc_zone_identifier = aws_subnet.backend_private[*].id
  target_group_arns   = [aws_lb_target_group.backend-tg.arn]

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

}