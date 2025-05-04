## Kubernetes Resource Deployment on EKS

### Setting up ECR Image Pull and DB secrets

**1. Run this command**
```
kubectl create secret docker-registry ecr-secret \
  --docker-server=<AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/<IMAGE_NAME> \
  --docker-username=AWS \
  --docker-password="$(aws ecr get-login-password --region us-east-1)" \
  --docker-email=unused@example.com \
  --namespace=default
```
What this does:
- ```docker-server:``` Your ECR registry URL

- ```docker-username:``` Always AWS for ECR

- ```docker-password:``` A short-lived auth token

- ```--namespace:``` The namespace where your app will be deployed

Reference the Secret in Helm ```values.yaml```.

**2. Create a file named accounts-db-secret.yaml:**
```
apiVersion: v1
kind: Secret
metadata:
  name: accounts-db-secret
  namespace: accounts
type: Opaque
stringData:
  username: username
  password: password
```

Repeat this for other microservices.

**3. Apply the Secret to the Cluster**

```kubectl apply -f accounts-db-secret.yaml```

Reference the Secret in Your Helm values.yaml

```
env:
  - name: DB_USERNAME
    valueFrom:
      secretKeyRef:
        name: accounts-db-secret
        key: username
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: accounts-db-secret
        key: password
```