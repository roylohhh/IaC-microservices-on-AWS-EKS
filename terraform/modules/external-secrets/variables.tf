variable "cluster_name" {}
variable "region" {}
variable "account_id" {}
variable "secret_name_prefix" {
  description = "Prefix of Secrets Manager secrets"
}
variable "oidc_provider_arn" {}
