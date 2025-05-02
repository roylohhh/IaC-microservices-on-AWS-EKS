variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_a_cidr" {}
variable "public_subnet_b_cidr" {}

variable "private_subnet_a_cidr" {}
variable "private_subnet_b_cidr" {}
variable "private_subnet_c_cidr" {}
variable "private_subnet_d_cidr" {}

variable "cluster_name" {
  description = "EKS cluster name used for tagging subnets"
  type        = string
}


