# Monitoring with Prometheus & Grafana

This section outlines how the monitoring stack (Prometheus & Grafana) is deployed on EKS using Terraform and Helm, and how to configure Grafana to monitor the accounts microservice using Spring Boot Actuator metrics.

## Infrastructure Setup: Terraform + Helm

Prometheus and Grafana are deployed using the ``kube-prometheus-stack`` Helm chart via Terraform:
```hcl
module "kube_prometheus_stack" {
  ...
}
```

**What this does:**

- Deploys Prometheus and Grafana into the monitoring namespace

- Enables ServiceMonitor to scrape application metrics

- Exposes Grafana through ALB Ingress using the hostname grafana.fake.com

## Setting Up a Dashboard for the accounts Microservice

### Step 0: Expose Spring Boot Metrics
As a prerequisite, ensure your Spring Boot accounts service exposes Prometheus metrics:

In application.yaml:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: prometheus
  metrics:
    export:
      prometheus:
        enabled: true
```

In the helm chart for accounts ``values.yaml``:

```yaml
# Monitoring config (for ServiceMonitor)
monitoring:
  enabled: true
  selectorLabels:
    app.kubernetes.io/instance: accounts
    app.kubernetes.io/name: accounts
  path: /actuator/prometheus
  interval: 15s
  scrapeTimeout: 10s
  labels:
    release: prometheus
```

Repeat for ``values.yaml`` in loans and cards.

### Step 1: Accessing Grafana

**Option A: Local Port Forward (for quick testing)**

```bash
kubectl port-forward svc/kube-prometheus-grafana 3000:80 -n monitoring
```

Then open: http://localhost:3000

**Option B:** Access via Ingress (simulated domain)

1. Get the ALB address:

```bash
kubectl get ingress -n monitoring
```

2. Update /etc/hosts (replace IP accordingly):

```bash
echo "3.92.248.108 grafana.fake.com" | sudo tee -a /etc/hosts
```

3. Open: http://grafana.fake.com

### Default Grafana Credentials

If credentials are not overridden, use:

- **Username:** admin

- **Password:**

```bash
kubectl get secret -n monitoring kube-prometheus-grafana -o jsonpath="{.data.admin-password}" 
```

### Step 2: Confirm Prometheus is Scraping Metrics

Port-forward the Prometheus service:

```bash
kubectl port-forward svc/kube-prometheus-kube-prome-prometheus 9090:9090 -n monitoring
```

Visit http://localhost:9090/targets

- Ensure the accounts microservice is listed

- Status should be ``UP``

### Step 3: Create Grafana Dashboard

**Option A: Import Dashboard ID 4701 (I did this)**

1. Go to: **Dashboards → Import**

2. Enter **Dashboard ID:** ``4701``

3. Click **Load**, then select your Prometheus data source

4. Click **Import**

This will load a comprehensive JVM and Micrometer monitoring dashboard — ideal for Spring Boot services exposing ``/actuator/prometheus``.

**Option B: Manually Create Custom Panels**

1. Open Grafana

2. Navigate to: **Dashboards → New → New Dashboard**

3. Click **Add new panel**

4. Use the following PromQL query:

```
http_server_requests_seconds_count{app_kubernetes_io_instance="accounts"}
jvm_memory_used_bytes
process_cpu_usage
```

| Component   | Access Method                                                             |
|------------|-----------------------------------------------------------------------------|
| Grafana    | http://localhost:3000 or http://grafana.fake.com                           |
| Prometheus | http://localhost:9090                                                      |
| Dashboards | Imported via Grafana (e.g., Dashboard ID 4701) or created using PromQL     |
| Metrics    | Exposed from `/actuator/prometheus` endpoints of
