resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "58.5.0"
  create_namespace = true

  values = [<<-EOF
    grafana:
      enabled: true
      service:
        type: ClusterIP
      ingress:
        enabled: true
        annotations:
          kubernetes.io/ingress.class: alb
        hosts:
          - grafana.fake.com
    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false
      serviceMonitor:
        enabled: true
  EOF
  ]

  depends_on = [module.eks]
}
