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

resource "aws_security_group" "alb_sg" {
  name_prefix = "my-alb-sg-"
  vpc_id      = aws_vpc.my_vpc.id

  # Ingress rule to allow traffic from the internet to the ALB
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic from anywhere on the internet
  }

  # Egress rule to allow all outbound traffic from the ALB
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name = "my-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/my-ecs-service" # The name should match the one specified in the task definition
  retention_in_days = 30      # Set the log retention period as required
}



# IAM execution role and policy

# Define the Fargate-compatible task definition
resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "ghost"
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

    logConfiguration = {
        logDriver = "awslogs"
        options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
        awslogs-region        = "eu-central-1" # Replace with your AWS region
        awslogs-stream-prefix = "ecs"
        }
    }
    }])
}



# ALB and ALB security group remain the same
# Create an IAM execution role for ECS tasks and attach the AmazonECSTaskExecutionRole policy
resource "aws_iam_role" "ecs_execution_role" {
  name = "my-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Attach an IAM policy that provides ECR permissions to the execution role
resource "aws_iam_policy" "ecs_execution_policy" {
  name        = "my-ecs-execution-policy"
  description = "ECR Access Policy for ECS Execution Role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetAuthorizationToken",
        "ecr:GetImageManifest",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage",
      ],
      Effect   = "Allow",
      Resource = "*",
    }]
  })
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}


resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.my_vpc.main_route_table_id // Replace with your route table ID if not using the default
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}



# Attach the ECR policy to the execution role
resource "aws_iam_policy_attachment" "ecs_execution_role_ecr_attachment" {
  name       = "ecs_execution_role_ecr_attachment"
  roles      = [aws_iam_role.ecs_execution_role.name]
  policy_arn = aws_iam_policy.ecs_execution_policy.arn
}

resource "aws_iam_policy" "cloudwatch_logs_policy" {
  name        = "ecs-cloudwatch-logs-policy"
  description = "Allow ECS to send logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_policy_attachment" "ecs_execution_role_cloudwatch_logs_attachment" {
  name       = "ecs-execution-role-cloudwatch-logs-attachment"
  roles      = [aws_iam_role.ecs_execution_role.name]
  policy_arn = aws_iam_policy.cloudwatch_logs_policy.arn
}



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
    container_name   = "ghost"
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
  target_type = "ip"
  
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# Create an Application Load Balancer
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.subnet_a[*].id
}

# Create a Listener for the ALB
resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}