output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "rds_hostname" {
  value = aws_db_instance.postgres.address
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}
