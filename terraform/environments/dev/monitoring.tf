module "kube_prometheus_stack" {
  source  = "terraform-module/kube-prometheus-stack/helm"
  version = "2.6.0"

  name             = "kube-prometheus"
  namespace        = "monitoring"
  create_namespace = true
  chart_version    = "58.5.0"

  values = [
    yamlencode({
      grafana = {
        enabled = true
        service = {
          type = "ClusterIP"
        }
        ingress = {
          enabled = true
          annotations = {
            "kubernetes.io/ingress.class" = "alb"
          }
          hosts = ["grafana.fake.com"]
        }
      }
      prometheus = {
        prometheusSpec = {
          serviceMonitorSelectorNilUsesHelmValues = false
        }
        serviceMonitor = {
          enabled = true
        }
      }
    })
  ]

  depends_on = [module.eks] 
}
