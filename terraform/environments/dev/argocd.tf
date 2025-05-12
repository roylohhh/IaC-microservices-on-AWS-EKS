resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.52.1" # check latest stable
  create_namespace = true

  values = [
    file("${path.module}/../../../k8s-base/argocd/root-app.yaml")
  ]

  depends_on = [module.eks]
}
