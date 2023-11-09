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

# # Define your ECS cluster
# resource "aws_ecs_cluster" "my_cluster" {
#   name = "my-ecs-cluster"
# }

# # Create a VPC and subnets for the cluster
# resource "aws_vpc" "my_vpc" {
#   cidr_block = "10.0.0.0/16"
# }

# resource "aws_subnet" "subnet_a" {
#   count = 2
#   cidr_block = "10.0.1.${count.index}/24"
#   vpc_id = aws_vpc.my_vpc.id
#   availability_zone = "us-east-1a"
# }

# # Define an Auto Scaling Group
# resource "aws_launch_configuration" "my_launch_config" {
#   name_prefix = "my-launch-config-"
#   image_id = "ami-12345678" # Specify your desired EC2 AMI
#   instance_type = "t2.micro" # Change this as needed

# user_data = <<-EOF
#               #!/bin/bash
#               echo ECS_CLUSTER=${aws_ecs_cluster.my_cluster.name} >> /etc/ecs/ecs.config
          
#               # Install the SSM agent
#               yum install -y https://s3.eu-central-1.amazonaws.com/amazon-ssm-eu-central-1/latest/linux_amd64/amazon-ssm-agent.rpm
#               systemctl enable amazon-ssm-agent
#               systemctl start amazon-ssm-agent
          
#               # Install the ECS agent
#               amazon-linux-extras install -y ecs
#               systemctl enable ecs
#               systemctl start ecs
#             EOF

#   security_groups = [aws_security_group.my_security_group.id]
#   key_name = "my-keypair" # Replace with your SSH key name if needed
# }

# resource "aws_security_group" "my_security_group" {
#   name_prefix = "my-sg-"

#   # Ingress rule to allow traffic from alb to the ec2
#   ingress {
#     from_port   = 80 # Use the port used by your ALB listener
#     to_port     = 80 # Use the same port as from_port
#     protocol    = "tcp"
#     cidr_blocks = [aws_security_group.alb_sg.id] # Allow traffic from alb
#   }
#   # Egress rule to allow all outbound traffic
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
  
# }

# resource "aws_autoscaling_group" "my_auto_scaling_group" {
#   name_prefix = "my-auto-scaling-group-"
#   launch_configuration = aws_launch_configuration.my_launch_config.name
#   min_size = 1
#   max_size = 2
#   desired_capacity = 1
#   vpc_zone_identifier = aws_subnet.subnet_a[*].id
# }

# # Create an IAM execution role for ECS tasks and attach the AmazonECSTaskExecutionRole policy
# resource "aws_iam_role" "ecs_execution_role" {
#   name = "my-ecs-execution-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action = "sts:AssumeRole",
#       Effect = "Allow",
#       Principal = {
#         Service = "ecs-tasks.amazonaws.com"
#       }
#     }]
#   })
# }

# # Attach an IAM policy that provides ECR permissions to the execution role
# resource "aws_iam_policy" "ecs_execution_policy" {
#   name        = "my-ecs-execution-policy"
#   description = "ECR Access Policy for ECS Execution Role"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action = [
#         "ecr:GetDownloadUrlForLayer",
#         "ecr:GetRepositoryPolicy",
#         "ecr:BatchCheckLayerAvailability",
#         "ecr:GetAuthorizationToken",
#         "ecr:GetImageManifest",
#         "ecr:InitiateLayerUpload",
#         "ecr:UploadLayerPart",
#         "ecr:CompleteLayerUpload",
#         "ecr:PutImage",
#       ],
#       Effect   = "Allow",
#       Resource = "*",
#     }]
#   })
# }

# # Attach the ECR policy to the execution role
# resource "aws_iam_policy_attachment" "ecs_execution_role_ecr_attachment" {
#   name       = "ecs_execution_role_ecr_attachment"
#   roles      = [aws_iam_role.ecs_execution_role.name]
#   policy_arn = aws_iam_policy.ecs_execution_policy.arn
# }

# resource "aws_iam_role" "ecs_task_role" {
#   name = "my-ecs-task-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# # Define the task definition referencing the execution role and task role
# resource "aws_ecs_task_definition" "my_task_definition" {
#   family                   = "my-task-family"
#   network_mode             = "bridge"
#   requires_compatibilities = ["EC2"]
#   execution_role_arn        = aws_iam_role.ecs_execution_role.arn # Reference the execution role ARN
#   task_role_arn            = aws_iam_role.ecs_task_role.arn # Reference the task role ARN

#   container_definitions = jsonencode([{
#     name  = "my-container"
#     image = "${aws_ecr_repository.my_ecr_repository.repository_url}:latest"
#     portMappings = [{
#       containerPort = 80
#       hostPort      = 80
#     }]
#   }])
# }

# # Create a security group for the ALB
# resource "aws_security_group" "alb_sg" {
#   name        = "my-alb-sg"
#   description = "Security Group for Application Load Balancer"
#   vpc_id      = aws_vpc.my_vpc.id # Use your VPC ID

#   # Ingress rule to allow traffic from internet to the alb
#   ingress {
#     from_port   = 80 # Use the port used by your ALB listener
#     to_port     = 80 # Use the same port as from_port
#     protocol    = "tcp"
#     cidr_blocks = [0.0.0.0/32] # Allow traffic from everywhere
#   }
#   # Egress rule to allow all outbound traffic
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

# }

# # Define an Application Load Balancer
# resource "aws_lb" "my_load_balancer" {
#   name               = "my-alb"
#   internal           = false
#   load_balancer_type = "application"
#   subnets            = aws_subnet.subnet_a[*].id
#   enable_deletion_protection = false
#   security_groups = [aws_security_group.alb_sg.id] # Attach the ALB security group
# }

# # Define a listener for the load balancer
# resource "aws_lb_listener" "my_listener" {
#   load_balancer_arn = aws_lb.my_load_balancer.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "fixed-response"
#     fixed_response {
#       content_type = "text/plain"
#       status_code  = "200"
#       content      = "OK"
#     }
#   }
# }

# # Define an ECS service
# resource "aws_ecs_service" "my_service" {
#   name            = "my-ecs-service"
#   cluster         = aws_ecs_cluster.my_cluster.id
#   task_definition = aws_ecs_task_definition.my_task_definition.arn
#   launch_type     = "EC2"

#   network_configuration {
#     subnets = aws_subnet.subnet_a[*].id
#     security_groups = [aws_security_group.my_security_group.id]
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.my_target_group.arn
#     container_name   = "my-container"
#     container_port   = 80
#   }
# }

# # Define a target group for the load balancer
# resource "aws_lb_target_group" "my_target_group" {
#   name     = "my-target-group"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.my_vpc.id

#   health_check {
#     path                = "/"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     matcher             = "200"
#   }
# }