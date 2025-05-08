resource "aws_iam_policy" "secretsmanager_read" {
  name        = "${var.cluster_name}-secretsmanager-read"
  description = "Policy for External Secrets Operator to read Secrets Manager"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:${var.secret_name_prefix}*"
      }
    ]
  })
}

module "irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                         = "${var.cluster_name}-external-secrets-irsa"
  attach_inline_policy              = true
  inline_policy                     = aws_iam_policy.secretsmanager_read.policy
  oidc_providers                    = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets-sa"]
    }
  }
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true

  set {
    name  = "serviceAccount.name"
    value = "external-secrets-sa"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa.iam_role_arn
  }

  depends_on = [module.irsa]
}
