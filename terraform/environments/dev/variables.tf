variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  description = "cidr block for vpc"
  default = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "cidr block for public subnet a"
  default = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "cidr block for public subnet b"
  default = "10.0.2.0/24"
}

variable "private_subnet_a_cidr" {
  description = "cidr block for private subnet a"
  default = "10.0.3.0/24"
}

variable "private_subnet_b_cidr" {
  description = "cidr block for private subnet b"
  default = "10.0.4.0/24"
}

variable "private_subnet_c_cidr" {
  description = "cidr block for private subnet c"
  default = "10.0.5.0/24"
}

variable "private_subnet_d_cidr" {
  description = "cidr block for private subnet d"
  default = "10.0.6.0/24"
}

variable "cluster_name" {
  
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
