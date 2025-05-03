resource "aws_db_instance" "postgres" {
  identifier         = var.identifier
  engine             = "postgres"
  engine_version     = var.engine_version
  instance_class     = var.instance_class
  username           = var.username
  password           = var.password
  db_name            = var.db_name
  allocated_storage  = 20
  max_allocated_storage = 100
  storage_type       = "gp2"
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = var.subnet_group
  skip_final_snapshot    = true
  apply_immediately      = true
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period 
}

resource "aws_security_group" "rds" {
  name   = "rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

