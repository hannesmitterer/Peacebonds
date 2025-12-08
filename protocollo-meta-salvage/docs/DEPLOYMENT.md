# Protocollo Meta Salvage - Deployment Guide

## Prerequisites

### Software Requirements
- Kubernetes 1.27+
- Helm 3.12+
- Terraform 1.5+
- kubectl 1.27+
- Docker 24.0+

### Infrastructure Requirements
- Kubernetes cluster with 16+ CPUs and 32GB+ RAM
- Persistent storage with 500GB+ available
- Network policies support
- LoadBalancer or Ingress controller

### Access Requirements
- Cluster admin access
- Docker registry access
- Cloud provider credentials (for managed services)

## Installation Steps

### 1. Prepare the Environment

```bash
# Clone the repository
git clone https://github.com/hannesmitterer/Peacebonds.git
cd Peacebonds/protocollo-meta-salvage

# Set environment variables
export NAMESPACE=protocollo-meta-salvage
export ENVIRONMENT=production
export CLUSTER_NAME=protocollo-cluster
```

### 2. Deploy Infrastructure with Terraform

```bash
# Navigate to infrastructure directory
cd infrastructure

# Initialize Terraform
terraform init

# Review the plan
terraform plan \
  -var="namespace=$NAMESPACE" \
  -var="peace_bond_active=false" \
  -var="throughput_limit=10000" \
  -var="compute_limit=10" \
  -var="memory_limit=20"

# Apply infrastructure
terraform apply -auto-approve

# Verify deployment
kubectl get namespaces | grep protocollo
kubectl get all -n $NAMESPACE
```

### 3. Deploy Monitoring Stack

```bash
# Deploy Kafka
helm install kafka bitnami/kafka \
  --namespace $NAMESPACE \
  --values config/kafka-values.yaml \
  --wait

# Deploy Prometheus
helm install prometheus prometheus-community/prometheus \
  --namespace $NAMESPACE \
  --values config/prometheus-values.yaml \
  --wait

# Deploy Grafana
helm install grafana grafana/grafana \
  --namespace $NAMESPACE \
  --set adminPassword=admin123 \
  --wait

# Deploy Elasticsearch
helm install elasticsearch elastic/elasticsearch \
  --namespace $NAMESPACE \
  --set replicas=3 \
  --wait
```

### 4. Deploy Decision Engine

```bash
# Create OPA ConfigMaps
kubectl create configmap opa-policies \
  --from-file=decision-engine/opa-policies.rego \
  -n $NAMESPACE

kubectl create configmap opa-config \
  --from-file=decision-engine/opa-config.yaml \
  -n $NAMESPACE

# Deploy OPA
kubectl apply -f infrastructure/kubernetes-manifests.yaml
```

### 5. Deploy Orchestration

```bash
# Deploy Apache Airflow
helm install airflow apache-airflow/airflow \
  --namespace $NAMESPACE \
  --set dags.gitSync.enabled=true \
  --set dags.gitSync.repo=https://github.com/hannesmitterer/Peacebonds.git \
  --set dags.gitSync.branch=main \
  --set dags.gitSync.subPath=protocollo-meta-salvage/orchestration \
  --wait

# Deploy Argo Workflows
kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml

# Deploy workflow templates
kubectl apply -f orchestration/argo-workflows.yaml
```

### 6. Deploy Audit Pipeline

```bash
# Create PostgreSQL for audit storage
helm install postgresql bitnami/postgresql \
  --namespace $NAMESPACE \
  --set auth.postgresPassword=auditpass \
  --set primary.persistence.size=100Gi \
  --wait

# Create MongoDB for audit storage
helm install mongodb bitnami/mongodb \
  --namespace $NAMESPACE \
  --set auth.rootPassword=mongopass \
  --wait

# Deploy audit pipeline configuration
kubectl create configmap audit-config \
  --from-file=audit-pipeline/audit-config.yaml \
  -n $NAMESPACE
```

### 7. Deploy ML Feedback System

```bash
# Create PVCs for ML training
kubectl apply -f infrastructure/kubernetes-manifests.yaml

# Deploy ML training pipeline
kubectl create configmap ml-training-config \
  --from-file=ml-feedback/training-pipeline.yaml \
  -n $NAMESPACE

# Deploy MLflow
helm install mlflow community-charts/mlflow \
  --namespace $NAMESPACE \
  --wait
```

## Verification

### Check All Components

```bash
# Check all pods are running
kubectl get pods -n $NAMESPACE

# Check services
kubectl get services -n $NAMESPACE

# Check persistent volumes
kubectl get pvc -n $NAMESPACE

# Check ConfigMaps and Secrets
kubectl get configmaps,secrets -n $NAMESPACE
```

### Test Monitoring

```bash
# Port-forward Prometheus
kubectl port-forward -n $NAMESPACE svc/prometheus-server 9090:80

# Access Prometheus UI: http://localhost:9090

# Port-forward Grafana
kubectl port-forward -n $NAMESPACE svc/grafana 3000:80

# Access Grafana UI: http://localhost:3000
# Default credentials: admin/admin123
```

### Test Decision Engine

```bash
# Port-forward OPA
kubectl port-forward -n $NAMESPACE svc/opa 8181:8181

# Test OPA policy
curl -X POST http://localhost:8181/v1/data/protocollo/meta_salvage/decision \
  -H 'Content-Type: application/json' \
  -d '{
    "input": {
      "metrics": {
        "symbiosis_score": 0.65,
        "lock_in_risk_score": 0.82,
        "data_flow_anomaly_rate": 0.03,
        "current_throughput": 8500
      },
      "provider": {
        "id": "test-provider",
        "metadata_completeness": 0.95,
        "compliance_status": "compliant"
      }
    }
  }'
```

### Test Orchestration

```bash
# Access Airflow UI
kubectl port-forward -n $NAMESPACE svc/airflow-webserver 8080:8080

# Access Airflow UI: http://localhost:8080
# Default credentials: admin/admin

# Check Argo Workflows
kubectl get workflows -n $NAMESPACE
```

## Configuration

### Peace Bond Activation

To activate Peace Bonds restrictions:

```bash
# Update Terraform variables
terraform apply \
  -var="peace_bond_active=true" \
  -var="throughput_limit=5000" \
  -var="compute_limit=5" \
  -var="memory_limit=10"

# Verify resource quotas are applied
kubectl get resourcequota -n $NAMESPACE
kubectl get limitrange -n $NAMESPACE
```

### Adjust Thresholds

Edit OPA policies:

```bash
# Edit OPA policies ConfigMap
kubectl edit configmap opa-policies -n $NAMESPACE

# Restart OPA pods to reload policies
kubectl rollout restart deployment opa -n $NAMESPACE
```

### Configure Monitoring Alerts

```bash
# Edit Prometheus alert rules
kubectl edit configmap prometheus-server -n $NAMESPACE

# Reload Prometheus configuration
kubectl exec -n $NAMESPACE prometheus-server-0 -- \
  killall -HUP prometheus
```

## Scaling

### Horizontal Scaling

```bash
# Scale Peace Bonds Controller
kubectl scale deployment peace-bonds-controller \
  --replicas=5 -n $NAMESPACE

# Scale OPA
kubectl scale deployment opa \
  --replicas=3 -n $NAMESPACE
```

### Vertical Scaling

```bash
# Update resource requests/limits in Terraform
terraform apply \
  -var="compute_limit=20" \
  -var="memory_limit=40"
```

## Backup and Recovery

### Backup Procedure

```bash
# Backup Elasticsearch indices
curl -X PUT "http://elasticsearch:9200/_snapshot/protocollo-backup" \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "s3",
    "settings": {
      "bucket": "protocollo-backups",
      "region": "eu-central-1"
    }
  }'

# Create snapshot
curl -X PUT "http://elasticsearch:9200/_snapshot/protocollo-backup/snapshot_1?wait_for_completion=true"

# Backup PostgreSQL
kubectl exec -n $NAMESPACE postgresql-0 -- \
  pg_dump -U postgres audit_db > audit_backup.sql

# Backup Terraform state (automatic with S3 backend)
terraform state pull > terraform.tfstate.backup
```

### Recovery Procedure

```bash
# Restore Elasticsearch snapshot
curl -X POST "http://elasticsearch:9200/_snapshot/protocollo-backup/snapshot_1/_restore"

# Restore PostgreSQL
kubectl exec -i -n $NAMESPACE postgresql-0 -- \
  psql -U postgres audit_db < audit_backup.sql
```

## Troubleshooting

### Common Issues

#### Pods not starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n $NAMESPACE

# Check logs
kubectl logs <pod-name> -n $NAMESPACE

# Check events
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'
```

#### Kafka connection issues

```bash
# Check Kafka brokers
kubectl exec -it kafka-0 -n $NAMESPACE -- \
  kafka-broker-api-versions.sh --bootstrap-server localhost:9092

# Test Kafka connectivity
kubectl run kafka-test --rm -i --tty --restart=Never \
  --image=bitnami/kafka:latest -n $NAMESPACE -- \
  kafka-topics.sh --list --bootstrap-server kafka:9092
```

#### OPA policy issues

```bash
# Test OPA policy syntax
kubectl exec -it opa-0 -n $NAMESPACE -- \
  opa test /policies/opa-policies.rego

# Check OPA decision logs
kubectl logs -f opa-0 -n $NAMESPACE
```

#### Flink job failures

```bash
# Check Flink JobManager logs
kubectl logs -f flink-jobmanager-0 -n $NAMESPACE

# Check Flink TaskManager logs
kubectl logs -f flink-taskmanager-0 -n $NAMESPACE

# Access Flink UI
kubectl port-forward -n $NAMESPACE svc/flink-jobmanager 8081:8081
# Access: http://localhost:8081
```

## Monitoring and Alerts

### Key Metrics to Monitor

1. **System Health**
   - Pod status and restarts
   - Resource utilization (CPU, Memory)
   - Network throughput

2. **Peace Bonds Status**
   - Active Peace Bonds count
   - Throughput restrictions applied
   - Resource quota usage

3. **Ethical Metrics**
   - Symbiosis scores
   - Lock-in risk scores
   - Anomaly detection rate

4. **ML Model Performance**
   - Prediction accuracy
   - Inference latency
   - Model drift indicators

### Alert Channels

Configure alert routing in Prometheus AlertManager:

```bash
kubectl edit configmap alertmanager-config -n $NAMESPACE
```

Example configuration for Slack, Email, PagerDuty is included in the alert rules.

## Maintenance

### Regular Tasks

1. **Daily**
   - Check system health dashboards
   - Review audit logs
   - Monitor Peace Bonds activations

2. **Weekly**
   - Review ML model performance
   - Check backup success
   - Update security patches

3. **Monthly**
   - Review and optimize resource allocation
   - Update dependencies
   - Audit security configurations

### Upgrades

```bash
# Upgrade Terraform infrastructure
cd infrastructure
terraform plan
terraform apply

# Upgrade Helm charts
helm upgrade kafka bitnami/kafka \
  --namespace $NAMESPACE \
  --values config/kafka-values.yaml

helm upgrade prometheus prometheus-community/prometheus \
  --namespace $NAMESPACE \
  --values config/prometheus-values.yaml
```

## Security Hardening

### Enable Network Policies

```bash
kubectl apply -f infrastructure/network-policies.yaml
```

### Enable Pod Security Policies

```bash
kubectl apply -f infrastructure/pod-security-policies.yaml
```

### Rotate Credentials

```bash
# Rotate API credentials
kubectl create secret generic api-credentials-new \
  --from-literal=metrics_api_token=<new-token> \
  -n $NAMESPACE

kubectl patch deployment peace-bonds-controller \
  -n $NAMESPACE \
  -p '{"spec":{"template":{"spec":{"volumes":[{"name":"api-credentials","secret":{"secretName":"api-credentials-new"}}]}}}}'
```

## Support

For issues and questions:
- GitHub Issues: https://github.com/hannesmitterer/Peacebonds/issues
- Documentation: https://github.com/hannesmitterer/Peacebonds/wiki
