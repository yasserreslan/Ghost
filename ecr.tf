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


# ECR VPC Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = aws_vpc.my_vpc.id
  service_name       = "com.amazonaws.eu-central-1.ecr.api"
  vpc_endpoint_type  = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.subnet_a[0].id, aws_subnet.subnet_a[1].id]

  security_group_ids = [aws_security_group.fargate_sg.id]

  tags = {
    Name = "ecr-api-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = aws_vpc.my_vpc.id
  service_name       = "com.amazonaws.eu-central-1.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.subnet_a[0].id, aws_subnet.subnet_a[1].id]

  security_group_ids = [aws_security_group.fargate_sg.id]

  tags = {
    Name = "ecr-dkr-endpoint"
  }
}