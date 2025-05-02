variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  description = "cidr block for vpc"
}

variable "public_subnet_a_cidr" {
  description = "cidr block for public subnet a"
}

variable "public_subnet_b_cidr" {
  description = "cidr block for public subnet b"
}

variable "private_subnet_a_cidr" {
  description = "cidr block for private subnet a"
}

variable "private_subnet_b_cidr" {
  description = "cidr block for private subnet b"
}

variable "private_subnet_c_cidr" {
  description = "cidr block for private subnet c"
}

variable "private_subnet_d_cidr" {
  description = "cidr block for private subnet d"
}

variable "cluster_name" {
  default = "dev-eks-cluster"
}

variable "accountsdb_password" {
  type      = string
  sensitive = true
}

variable "cardsdb_password" {
  type      = string
  sensitive = true
}

variable "loansdb_password" {
  type      = string
  sensitive = true
}