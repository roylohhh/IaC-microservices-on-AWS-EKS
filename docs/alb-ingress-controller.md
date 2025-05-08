## AWS Load Balancer Controller with IAM & OIDC (IRSA)

To dynamically provision Application Load Balancers (ALBs) in Kubernetes using Ingress, this project deploys the AWS Load Balancer Controller via Helm. It authenticates securely using IAM Roles for Service Accounts (IRSA) — a best-practice method that avoids granting unnecessary permissions to all EKS worker nodes.

### IAM & OIDC Integration

Instead of assigning AWS permissions cluster-wide, this setup uses fine-grained IAM access tied to a specific Kubernetes Service Account via the EKS OIDC provider. This ensures the Load Balancer Controller can perform its actions without compromising security elsewhere.

### 1. Fetch OIDC Provider:

Fetches the OIDC provider created by EKS to establish trust between IAM roles and Kubernetes service accounts via Web Identity Federation.

```hcl
data "aws_iam_openid_connect_provider" "this" {
  url = var.oidc_provider_url
}
```

### 2. IAM Policy for the Load Balancer Controller:

Loads an IAM policy that grants the AWS Load Balancer Controller access to required AWS APIs. This is sourced from a JSON file provided by AWS.

```hcl
resource "aws_iam_policy" "alb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/iam-policy-alb-controller.json")
}
```

### 3. IAM Role for Service Account:

Defines a role that can be assumed by the Kubernetes Service Account using Web Identity. The trust policy limits the role usage to the aws-load-balancer-controller service account in the kube-system namespace.

```hcl
resource "aws_iam_role" "alb_controller_irsa" {
  ...
}
```

### 4. Attach IAM Policy to Role:

Attaches the previously defined IAM policy to the IRSA role.

```hcl
resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_controller_irsa.name
  policy_arn = aws_iam_policy.alb_controller.arn
}
```

### 5. Kubernetes Service Account (with IAM Role Annotation):

Creates the corresponding Kubernetes ServiceAccount in the kube-system namespace and binds it to the IAM role using the eks.amazonaws.com/role-arn annotation. This allows the controller to assume the IAM role via IRSA.

```hcl
resource "kubernetes_service_account" "alb_controller" {
  ...
}
```

### 6. Install AWS Load Balancer Controller via Helm:

Installs the controller with Helm, using the predefined service account and configuring it with the EKS cluster name, region, and VPC ID. The controller image is pulled from AWS ECR.

```hcl
resource "helm_release" "alb_controller" {
  ...
}
```

### About the IAM Policy
The IAM policy attached to the controller allows it to:

- Create and manage ALBs, Target Groups, Listeners, Rules, etc.

- Configuring Target Groups, Listeners, and Routing Rules

- Modify and tag security groups

- Interact with AWS WAF, ACM, and Shield

- Accessing EC2 and VPC-related networking resources

This policy follows AWS recommendations and should be updated regularly based on official documentation.

### Benefits of This Setup
- **Security:** Uses least privilege via IRSA to isolate permissions

- **Scalability:** Automatically provisions and manages ALBs via Kubernetes ``Ingress``

- **Automation:** Entire setup is managed via Terraform and Helm, ensuring repeatability and consistency

