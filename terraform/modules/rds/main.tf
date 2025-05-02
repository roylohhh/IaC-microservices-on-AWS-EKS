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
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = var.subnet_group
  skip_final_snapshot    = true
  apply_immediately      = true
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period 
}

