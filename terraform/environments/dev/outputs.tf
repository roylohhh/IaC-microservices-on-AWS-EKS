output "accounts_rds_endpoint" {
  value = module.rds_accounts.rds_endpoint
}

output "cards_rds_endpoint" {
  value = module.rds_cards.rds_endpoint
}

output "loans_rds_endpoint" {
  value = module.rds_loans.rds_endpoint
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}