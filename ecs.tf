# Define your ECS cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-ecs-cluster"
}

# Define the Fargate ECS service
resource "aws_ecs_service" "my_service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.subnet_a[0].id, aws_subnet.subnet_a[1].id] # Replace with your private subnet IDs
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "ghost"
    container_port   = 80
  }

  desired_count = 1

}

resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "ghost"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu                      = "256"
  memory                   = "512"

  network_mode = "awsvpc" 

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
        awslogs-region        = "eu-central-1"
        awslogs-stream-prefix = "ecs"
        }
    }
    }])
}