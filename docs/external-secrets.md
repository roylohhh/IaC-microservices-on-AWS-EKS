# External Secrets Operator Setup with AWS Secrets Manager (Terraform-Based)

This guide explains how to automate the integration of **AWS Secrets Manager** with **Kubernetes** using **External Secrets Operator (ESO)** and **Terraform**. The setup enables syncing secrets from Secrets Manager into Kubernetes `Secret` resources using GitOps-friendly workflows.

---

## Overview 

- Create an IAM policy to allow `secretsmanager:GetSecretValue`
- Bind the policy to a Kubernetes service account via IRSA (IAM Roles for Service Accounts)
- Install External Secrets Operator via Helm with the IRSA-attached service account
- One shared secret in AWS Secrets Manager (`banking-microservices`)
- Three Kubernetes `Secrets`, one per microservice (`accounts`, `loans`, `cards`)



## Terraform Module: modules/external-secrets

This module provisions:
- IAM permissions for ESO to read secrets
- An IRSA-bound Kubernetes service account (`external-secrets-sa`)
- ESO itself via Helm

#### ``aws_iam_policy`` — Grant ESO access to Secrets Manager
```hcl
resource "aws_iam_policy" "secretsmanager_read" { ... }
```

- **Purpose:** Defines a custom IAM policy that allows ESO to call: ``secretsmanager:GetSecretValue``

- **Resource:** Restricts access to secrets matching accounts-db* (e.g., accounts-db, accounts-db-prod)

- **Why:** ESO needs permission to read secrets from AWS so it can sync them into Kubernetes.


#### ``module "irsa"`` — IAM Role for Service Account (IRSA)
```hcl
module "irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  ...
}
```

- **Purpose:** Creates an IAM role that is "assumable" by a Kubernetes service account (external-secrets-sa in external-secrets namespace) via EKS OIDC.

- **Why:** This is how AWS securely links IAM permissions to pods in EKS using Kubernetes-native constructs.

- OIDC Details:
  - `oidc_provider_arn` links to your EKS cluster OIDC provider.
  - `namespace_service_accounts` tells AWS which service account can use this IAM role.


#### ``helm_release "external_secrets"`` — Install External Secrets Operator
```hcl
resource "helm_release" "external_secrets" { ... }
```

- **Purpose:** Deploys ESO into your EKS cluster.

- **Key Settings:**

- `serviceAccount.name:` Uses external-secrets-sa.

- `serviceAccount.annotations.eks.amazonaws.com/role-arn:` Binds the IRSA IAM role created above to the service account, giving it Secrets Manager access.

This lets ESO run in EKS and read AWS secrets securely.


## Secrets Manager Setup
Create a new secret in AWS Secrets Manager called banking-microservices:
```bash
aws secretsmanager create-secret \
  --name accounts-db \
  --secret-string '{
    "DB_USERNAME": "user",
    "DB_PASSWORD": "pass",
    "DB_HOST": "rds.amazon.com"
  }'
```
In production, this will be automated in GitHub Actions workflow after Terraform provisioning (e.g., dynamically inject the RDS endpoint).

## Kubernetes YAMLs in k8s-base/external-secrets/
``secretstore.yaml``
This file connects ESO to AWS Secrets Manager:
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secretsmanager
  namespace: default
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
```

``accounts-db-externalsecret.yaml``
This file tells ESO to extract only the accounts-related fields from the shared AWS secret and create a Kubernetes Secret named accounts-db-credentials.
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-secret
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: accounts-db-credentials
    creationPolicy: Owner
  data:
    - secretKey: DB_HOST
      remoteRef:
        key: banking-microservices
        property: ACCOUNTS_DB_HOST
    - secretKey: DB_NAME
      remoteRef:
        key: banking-microservices
        property: ACCOUNTS_DB_NAME
    - secretKey: DB_USERNAME
      remoteRef:
        key: banking-microservices
        property: ACCOUNTS_DB_USER
    - secretKey: DB_PASSWORD
      remoteRef:
        key: banking-microservices
        property: ACCOUNTS_DB_PASS
```
Repeat for loans and cards, updating the property: values and target.name.

Update your values.yaml for each microservice to inject environment variables from the synced Kubernetes secret:
```yaml
envFrom:
  - secretRef:
      name: accounts-db-credentials
```      

## Validation
Check synced Kubernetes Secret:
```bash
kubectl get secret db-credentials -n accounts -o yaml
```
Verify your application receives the correct environment variables.