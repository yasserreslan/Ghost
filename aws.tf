# Create an ECR repository
resource "aws_ecr_repository" "my_ecr_repository" {
  name = "ghost"
}

# Create a Docker image and push it to ECR
resource "null_resource" "docker_build_push" {
  triggers = {
    ecr_repository_url = aws_ecr_repository.my_ecr_repository.repository_url
  }

  provisioner "local-exec" {
    command = "docker pull ghost"
  }

  provisioner "local-exec" {
    command = "aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.my_ecr_repository.repository_url}"
  }

  provisioner "local-exec" {
    command = "docker tag ghost:latest ${aws_ecr_repository.my_ecr_repository.repository_url}:latest"
  }

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.my_ecr_repository.repository_url}:latest"
  }
  
}

# Define your ECS cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-ecs-cluster"
}

# Create a VPC and subnets for the cluster
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_a" {
  count = 2
  cidr_block = "10.0.${count.index + 1}.0/24"
  vpc_id = aws_vpc.my_vpc.id
  availability_zone = element(
    ["eu-central-1a", "eu-central-1b"],
    count.index
  )
}

# Create a security group for Fargate services
resource "aws_security_group" "fargate_sg" {
  name_prefix = "my-fargate-sg-"
  vpc_id      = aws_vpc.my_vpc.id

  # Ingress rule to allow traffic from ALB to Fargate services
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Allow traffic from ALB security group
  }

  # Egress rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM execution role and policy remain the same

# Define the Fargate-compatible task definition
resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "my-task-family"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu                      = "256"  # Adjust based on your needs
  memory                   = "512"  # Adjust based on your needs

  network_mode = "awsvpc" # Required for Fargate

  container_definitions = jsonencode([{
    name  = "ghost"
    image = "${aws_ecr_repository.my_ecr_repository.repository_url}:latest"
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

# ALB and ALB security group remain the same

# Define the Fargate ECS service
resource "aws_ecs_service" "my_service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets = aws_subnet.subnet_a[*].id
    security_groups = [aws_security_group.fargate_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "my-container"
    container_port   = 80
  }

  desired_count = 1
}

# Define a target group for the load balancer
resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}