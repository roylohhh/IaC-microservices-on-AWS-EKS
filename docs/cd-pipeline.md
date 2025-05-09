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


## 3. CD Pipeline — GitHub Actions Workflow

### Trigger:

**Manual trigger:** Used for controlled, one-off or development-stage deployments. In production, push or pull_request triggers tied to branches are used instead.

### Job 1: ``provision-infra``

This job provisions AWS infrastructure using Terraform and extracts dynamic outputs (RDS endpoints, ALB SG ID) for use in later jobs.

### Key Steps
| Step                        | Description                  | Why It’s Done                                               |
| --------------------------- | ---------------------------- | ----------------------------------------------------------- |
| `Checkout`                  | Clones the infra repo        | Required to access Terraform files                          |
| `Configure AWS Credentials` | Sets up AWS access           | Enables Terraform to deploy infrastructure to AWS           |
| `Terraform Init & Apply`    | Provisions all AWS resources | Creates VPC, EKS, RDS, ALB, etc.                            |
| `Extract Terraform Outputs` | Captures RDS and ALB outputs | Needed to inject into Secrets Manager and Helm charts later |

**Reasoning:** Terraform owns infra lifecycle; GitHub Actions dynamically retrieves outputs to inject downstream.

### Job 2: ``update-secrets``

Update AWS Secrets Manager with credentials and dynamic values (like RDS endpoints) using Python (boto3)

### Key Steps
| Step                | Description                      | Why It’s Done                                                 |
| ------------------- | -------------------------------- | ------------------------------------------------------------- |
| `Checkout`          | Access the secrets update script | Script is versioned in the repo                               |
| `Install Boto3`     | Install AWS SDK for Python       | Required by `update_secrets.py`                               |
| `Run Python Script` | Executes `update_secrets.py`     | Merges RDS endpoint + DB credentials into AWS Secrets Manager |

Python is used here because boto3 and json in Python is far more readable and maintainable than nested jq and bash loops, making it more scalable.

### Job 3: ``update-values``
Update the values.yaml files in each Helm chart with the dynamically created ALB Security Group ID using Python

### Key Steps
| Step                  | Description                   | Why It’s Done                                       |
| --------------------- | ----------------------------- | --------------------------------------------------- |
| `Checkout`            | Access Helm values.yaml files | Needed to modify ingress config                     |
| `Install ruamel.yaml` | Install YAML parser           | Enables safe in-place YAML modification             |
| `Run Python Script`   | Executes `patch_values.py`    | Patches ALB SG ID into `.ingress.annotations` field |

Modifying structured YAML in multiple charts is best handled with a proper parser (ruamel.yaml) instead of brittle yq commands.

### Job 4: ``create-ecr-secret``
Creates a Kubernetes ``ecr-secret`` to allow pulling private Docker images from Amazon ECR.

### Key Steps
| Step                        | Description                                           | Why It’s Done                                                 |
| --------------------------- | ----------------------------------------------------- | ------------------------------------------------------------- |
| `Configure AWS Credentials` | Injects AWS access keys into the environment          | Required to run `aws eks` and `aws ecr` CLI commands          |
| `Set up kubeconfig for EKS` | Authenticates kubectl with your EKS cluster           | Ensures `kubectl` points to the correct cluster context       |
| `Create ECR Secret`         | Creates a `docker-registry` secret named `ecr-secret` | Enables Kubernetes to authenticate with ECR for image pulling |


The ecr-secret is created in the default namespace and automatically used in your Helm charts via the imagePullSecrets field. This step is idempotent — if the secret already exists, it will skip creation to avoid failure.

### Job 5: ``commit-changes``
Commit and push the modified values.yaml files (i.e. ALB SG ID updates) back to the Git repo so ArgoCD can sync them.

### Key Steps
| Step                  | Description                       | Why It’s Done                                             |
| --------------------- | --------------------------------- | --------------------------------------------------------- |
| `Checkout`            | Clones the repo to stage changes  | Required before `git commit`                              |
| `git add/commit/push` | Pushes updated values.yaml to Git | ArgoCD syncs the updated Helm charts to EKS automatically |

**GitOps Principle:** Git is the source of truth. Updating manifests in Git and letting ArgoCD sync them keeps everything declarative and auditable.

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


