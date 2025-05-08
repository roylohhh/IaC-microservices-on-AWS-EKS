# Continuous Deployment Pipeline with Terraform, GitHub Actions & ArgoCD

This document explains how to set up a production-grade CD pipeline using:

- **Terraform** to provision AWS infrastructure (EKS, RDS, ALB, IAM, etc.)
- **GitHub Actions** to run Terraform and dynamically update configurations
- **ArgoCD** to deploy Helm charts to EKS based on changes in the infra Git repository
- **AWS Secrets Manager** for secure secret management
- **GitOps** workflow for declarative, version-controlled Kubernetes deployment

## ArgoCD Setup 
### Overview
This project uses ArgoCD to implement GitOps-based continuous deployment for Kubernetes applications. ArgoCD continuously monitors and syncs application state in the cluster to match the declarative configuration stored in Git.

### ArgoCD Installation
ArgoCD is deployed to the EKS cluster using the official Helm chart, managed by Terraform:

- **Namespace:** argocd

- **Chart Version:** 5.52.1 (latest stable recommended)

- **Values File:** Customized via argocd-values.yaml

- **Repository:** https://argoproj.github.io/argo-helm

- **Provisioned With:** helm_release Terraform resource

- **Dependency:** Waits for the EKS cluster to be provisioned before install

### App of Apps Pattern
To manage multiple microservices and shared resources declaratively, this setup uses ArgoCD’s App of Apps pattern. This involves creating a single root application that points to a folder of child Application resources.

**Root Application** (``root-app.yaml``)

- **Location:** Synced by ArgoCD directly or initially applied manually via kubectl

- **Purpose:** Acts as the entrypoint to bootstrap all other ArgoCD applications

- **Git Path:** k8s-base/argocd/apps — this directory contains all child application manifests

- **Sync Policy:**

  - ``automated``: Enables auto-sync

  - ``prune``: Deletes obsolete resources

  - ``selfHeal``: Automatically corrects drift


## 3. GitOps-Based CD Pipeline — GitHub Actions Workflow
This CD pipeline enables infrastructure and application deployment using a declarative, Git-driven approach.

### CD Pipeline Explained (Step-by-Step)
#### 1. Terraform Apply: 
GitHub Actions runs terraform apply to provision infrastructure (EKS, RDS, ALB, IAM roles, etc.)

#### 2. Capture Outputs
RDS endpoint and ALB Security Group ID are captured using terraform output.

#### 3. Update Secrets Manager
The rds_endpoint is dynamically injected into the banking-microservices secret in AWS Secrets Manager.

#### 4. Update Helm values.yaml
The ALB SG ID is inserted into each Helm chart’s values.yaml under the ingress.annotations field.

#### 5. Create ecr-secret (Image Pull Secret)
The pipeline generates a Kubernetes docker-registry secret (ecr-secret) to authenticate to Amazon ECR.

#### 6. Commit and Push to Git
All modified files are committed and pushed to the infra repo's main branch.

#### 7. ArgoCD Auto-Sync
ArgoCD watches the repo and syncs the updated Helm charts to EKS.

This is a true GitOps pipeline — Git is the source of truth, and ArgoCD reconciles the cluster state automatically.

### Pipeline Summary

| Step | Action                                                                 |
|------|------------------------------------------------------------------------|
| 1    | Run `terraform apply`                                                  |
| 2    | Capture outputs (RDS endpoint, ALB SG ID)                              |
| 3    | Update Secrets Manager (`banking-microservices`) with RDS endpoint     |
| 4    | Modify `values.yaml` of Helm charts with ALB SG ID                     |
| 5	   | Create Kubernetes `ecr-secret` for private ECR image pulls             |
| 6    | Commit and push to `main` of infra repo                                |
| 7    | ArgoCD auto-syncs from Git and deploys changes to the cluster          |


## Simulate a Real Domain Locally using /etc/hosts

We will now simulate a real domain by accessing our local microservice via postman at:

```http://accounts.fake.com/actuator/health```

1. Firstly run this command:

```kubectl get ingress accounts -n default```

Take note of the ADDRESS value — that's your ALB's DNS.

2. Edit ```/etc/hosts``` on your machine

```sudo nano /etc/hosts```

3. Test in Postman.