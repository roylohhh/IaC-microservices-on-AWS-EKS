variable "identifier" {
  type = string
}

variable "db_name" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
  sensitive = true
}

variable "instance_class" {
  type = string
}

variable "subnet_group" {
  type = string
}

variable "engine_version" {
  type = string
  default = "15.10"
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "backup_retention_period" {
  type    = number
  default = 0
}

variable "vpc_id" {
  type = string
}

variable vpc_security_group_ids {
  description = "List of SG IDs to associate with the RDS instance"
  type        = list(string)
}