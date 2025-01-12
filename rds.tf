resource "aws_db_instance" "ghost_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "ghost_db"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"
}

resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-sg-"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


