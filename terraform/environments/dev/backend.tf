terraform {
  backend "s3" {
    bucket         = "banking-microservices-infra-tf-state-bucket"
    key            = "eks/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
