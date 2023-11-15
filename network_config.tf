# Create a VPC and subnets for the cluster
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
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

# Security group for Fargate services
resource "aws_security_group" "fargate_sg" {
  name_prefix = "my-fargate-sg-"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.alb_sg.id]

  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "alb_sg" {
  name_prefix = "my-alb-sg-"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
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


# Attach the AmazonECSTaskExecutionRolePolicy policy
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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


resource "aws_subnet" "my_public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone = "eu-central-1a"
}


resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.my_public_subnet.id
}

resource "aws_eip" "my_eip" {
  vpc = true
}

resource "aws_route" "nat_gateway_route" {
  route_table_id         = aws_vpc.my_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.my_nat_gateway.id
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

resource "aws_security_group" "ecs_tasks_sg" {
  name_prefix = "ecs-tasks-sg-"
  vpc_id      = aws_vpc.my_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}