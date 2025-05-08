module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr = var.vpc_cidr

  public_subnet_a_cidr = var.public_subnet_a_cidr
  public_subnet_b_cidr = var.public_subnet_b_cidr

  private_subnet_a_cidr = var.private_subnet_a_cidr
  private_subnet_b_cidr = var.private_subnet_b_cidr
  private_subnet_c_cidr = var.private_subnet_c_cidr
  private_subnet_d_cidr = var.private_subnet_d_cidr

  cluster_name = var.cluster_name
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = [module.vpc.private_subnet_a_id, module.vpc.private_subnet_b_id]

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
    ami_type       = "AL2023_x86_64_STANDARD"
  }

  eks_managed_node_groups = {
    dev_nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

module "rds_accounts" {
  source                 = "../../modules/rds"
  identifier             = "accounts-db"
  db_name                = "accountsdb"
  username               = "s3895134"
  password               = var.accountsdb_password
  instance_class         = "db.t3.micro"
  subnet_group           = aws_db_subnet_group.main.name
  vpc_id                 = module.vpc.vpc_id
  vpc_security_group_ids = [aws_security_group.rds.id]
}

module "rds_cards" {
  source                 = "../../modules/rds"
  identifier             = "cards-db"
  db_name                = "cardsdb"
  username               = "s3895134"
  password               = var.cardsdb_password
  instance_class         = "db.t3.micro"
  subnet_group           = aws_db_subnet_group.main.name
  vpc_id                 = module.vpc.vpc_id
  vpc_security_group_ids = [aws_security_group.rds.id]
}

module "rds_loans" {
  source                 = "../../modules/rds"
  identifier             = "loans-db"
  db_name                = "loansdb"
  username               = "s3895134"
  password               = var.loansdb_password
  instance_class         = "db.t3.micro"
  subnet_group           = aws_db_subnet_group.main.name
  vpc_id                 = module.vpc.vpc_id
  vpc_security_group_ids = [aws_security_group.rds.id]
}

resource "aws_db_subnet_group" "main" {
  name       = "rds_subnet_group"
  subnet_ids = [module.vpc.private_subnet_c_id, module.vpc.private_subnet_d_id]
  tags = {
    Name = "rds_subnet_group"
  }
}

module "alb_controller" {
  source            = "../../modules/alb-controller"
  cluster_name      = module.eks.cluster_name
  region            = var.region
  vpc_id            = module.vpc.vpc_id
  oidc_provider_url = module.eks.cluster_oidc_issuer_url

  depends_on = [module.eks]
}


module "external_secrets" {
  source            = "../../modules/external-secrets"
  cluster_name      = var.cluster_name
  region            = var.region
  account_id        = data.aws_caller_identity.current.account_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  secret_name_prefix = "db-secrets"
}




