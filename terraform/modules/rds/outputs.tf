output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "rds_hostname" {
  value = aws_db_instance.postgres.address
}


