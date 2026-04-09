# Auto-Deploy Documentation

Automated deployment system for PeaceBonds security enhancements.

## Overview

The auto-deploy system provides two deployment methods:
1. **GitHub Actions Workflow** - Automated CI/CD pipeline
2. **Manual Script** - Local deployment script

## Quick Start

### Method 1: GitHub Actions (Recommended)

The workflow automatically triggers on:
- Push to `main` or `copilot/implement-monitoring-dashboard` branches
- Manual workflow dispatch

**Manual Trigger:**
1. Go to GitHub Actions tab
2. Select "Auto-Deploy Security Enhancements"
3. Click "Run workflow"
4. Choose environment (staging/production)
5. Set Peace Bond activation if needed

### Method 2: Manual Script

```bash
cd protocollo-meta-salvage/scripts
./autodeploy.sh --environment staging
```

**Options:**
- `--namespace NAME` - Set Kubernetes namespace (default: protocollo-meta-salvage)
- `--environment ENV` - Set environment (default: staging)
- `--dry-run` - Simulate deployment without changes
- `--help` - Show help message

**Examples:**
```bash
# Production deployment
./autodeploy.sh --environment production

# Dry run to preview changes
./autodeploy.sh --dry-run

# Custom namespace
./autodeploy.sh --namespace my-namespace
```

## Prerequisites

### For GitHub Actions
- GitHub repository with Actions enabled
- Kubernetes cluster configured (optional for validation)
- Secrets configured:
  - `KUBECONFIG` - Base64 encoded kubeconfig (optional)

### For Manual Script
- `kubectl` v1.28.0+
- `helm` v3.13.0+
- `jq`
- `python3`
- Kubernetes cluster access configured

**Install prerequisites:**
```bash
# macOS
brew install kubectl helm jq python3

# Ubuntu/Debian
sudo apt-get install kubectl helm jq python3

# Verify installation
kubectl version --client
helm version
jq --version
python3 --version
```

## What Gets Deployed

### 1. Monitoring Stack
- **Loki** - Log aggregation (10Gi persistent storage)
- **Grafana** - Visualization dashboard (10Gi persistent storage)
- **Promtail** - Log collection agent
- **ConfigMaps** - Dashboard configurations

### 2. Security Services
- **Forensic Response Daemon** - Threat detection and response
- **Backup CronJobs** - Daily automated backups (02:00)
- **QUIC Server** - TLS 1.3 protocol hardening
- **ConfigMaps** - Security scripts and configurations

### 3. Storage Infrastructure
- **IPFS Node** - Distributed backup storage (50Gi)
- **Persistent Volumes** - Data persistence

### 4. Configurations
- Loki configuration (31-day retention)
- QUIC/TLS 1.3 settings
- Grafana dashboards
- Security scripts

## Deployment Flow

```
┌─────────────────────────────────────────────────────────┐
│  1. Validate                                            │
│     ✓ Python scripts                                    │
│     ✓ Bash scripts                                      │
│     ✓ YAML configurations                               │
│     ✓ JSON files                                        │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  2. Build                                               │
│     ✓ Install npm dependencies                          │
│     ✓ Compile smart contracts                           │
│     ✓ Build TypeScript                                  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  3. Deploy Monitoring                                   │
│     ✓ Create ConfigMaps                                 │
│     ✓ Deploy Loki                                       │
│     ✓ Deploy Grafana                                    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  4. Deploy Security Services                            │
│     ✓ Create script ConfigMaps                          │
│     ✓ Deploy forensic response                          │
│     ✓ Deploy backup CronJobs                            │
│     ✓ Deploy QUIC server                                │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  5. Deploy IPFS                                         │
│     ✓ Create IPFS deployment                            │
│     ✓ Create service                                    │
│     ✓ Create persistent volume                          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  6. Verify                                              │
│     ✓ Check deployments                                 │
│     ✓ Check pods                                        │
│     ✓ Check services                                    │
│     ✓ Generate report                                   │
└─────────────────────────────────────────────────────────┘
```

## Accessing Deployed Services

### Grafana Dashboard
```bash
kubectl port-forward -n protocollo-meta-salvage svc/grafana 3000:80
```
- URL: http://localhost:3000
- Username: `admin`
- Password: `admin123`

### Loki Logs
```bash
kubectl port-forward -n protocollo-meta-salvage svc/loki 3100:3100
```
- URL: http://localhost:3100

### IPFS Gateway
```bash
kubectl port-forward -n protocollo-meta-salvage svc/ipfs 8080:8080
```
- URL: http://localhost:8080

### IPFS API
```bash
kubectl port-forward -n protocollo-meta-salvage svc/ipfs 5001:5001
```
- URL: http://localhost:5001

## Verification Commands

```bash
# Check all pods
kubectl get pods -n protocollo-meta-salvage

# Check services
kubectl get svc -n protocollo-meta-salvage

# Check deployments
kubectl get deployments -n protocollo-meta-salvage

# Check CronJobs
kubectl get cronjobs -n protocollo-meta-salvage

# View forensic response logs
kubectl logs -n protocollo-meta-salvage -l component=forensic-response

# View backup job history
kubectl get jobs -n protocollo-meta-salvage

# Check QUIC server status
kubectl get pods -n protocollo-meta-salvage -l component=quic-server
```

## Post-Deployment Configuration

### 1. Import Grafana Dashboards
```bash
# Dashboard is pre-configured in ConfigMap
# Access Grafana and import from Configuration → Data Sources
```

### 2. Configure TLS Certificates
```bash
# Generate certificates
cd protocollo-meta-salvage/scripts
./setup-quic-server.sh

# Create Kubernetes secret
kubectl create secret generic quic-tls-certs \
  --from-file=server.crt=/etc/peacebonds/tls/server.crt \
  --from-file=server.key=/etc/peacebonds/tls/server.key \
  --from-file=ca.crt=/etc/peacebonds/tls/ca.crt \
  --namespace=protocollo-meta-salvage
```

### 3. Set Up GPG Keys for Backups
```bash
# Generate GPG key
gpg --gen-key

# Export public key
gpg --export -a "PeaceBonds Backup" > backup-public.key

# Create Kubernetes secret
kubectl create secret generic backup-gpg-keys \
  --from-file=pubring.gpg=/root/.gnupg/pubring.gpg \
  --from-file=secring.gpg=/root/.gnupg/secring.gpg \
  --namespace=protocollo-meta-salvage
```

### 4. Test Forensic Response
```bash
# Create test log entry
kubectl exec -n protocollo-meta-salvage -it deployment/forensic-response -- \
  sh -c 'echo "[$(date)] ERROR: Failed login from 192.168.1.100" >> /var/log/peacebonds/security.log'

# Check logs
kubectl logs -n protocollo-meta-salvage -l component=forensic-response
```

### 5. Verify Backup Automation
```bash
# Trigger backup job manually
kubectl create job --from=cronjob/peacebonds-backup manual-backup-1 \
  -n protocollo-meta-salvage

# Check job status
kubectl get jobs -n protocollo-meta-salvage

# View backup logs
kubectl logs -n protocollo-meta-salvage job/manual-backup-1
```

## Troubleshooting

### Deployment Fails
```bash
# Check workflow logs
# Go to GitHub Actions → Select failed run → View logs

# For manual script
./autodeploy.sh --dry-run  # Preview changes
```

### Pods Not Starting
```bash
# Describe pod
kubectl describe pod <pod-name> -n protocollo-meta-salvage

# View logs
kubectl logs <pod-name> -n protocollo-meta-salvage

# Check events
kubectl get events -n protocollo-meta-salvage --sort-by='.lastTimestamp'
```

### Storage Issues
```bash
# Check PVCs
kubectl get pvc -n protocollo-meta-salvage

# Describe PVC
kubectl describe pvc <pvc-name> -n protocollo-meta-salvage
```

### Service Not Accessible
```bash
# Check service
kubectl get svc -n protocollo-meta-salvage

# Check endpoints
kubectl get endpoints -n protocollo-meta-salvage

# Verify port-forward
kubectl port-forward -n protocollo-meta-salvage svc/<service-name> <local-port>:<service-port>
```

## Rollback

### Using kubectl
```bash
# Rollback deployment
kubectl rollout undo deployment/<deployment-name> -n protocollo-meta-salvage

# Check rollout status
kubectl rollout status deployment/<deployment-name> -n protocollo-meta-salvage
```

### Complete Uninstall
```bash
# Delete all resources
kubectl delete namespace protocollo-meta-salvage

# Remove Helm releases
helm list -n protocollo-meta-salvage
helm uninstall <release-name> -n protocollo-meta-salvage
```

## Environment Variables

### GitHub Actions
- `NAMESPACE` - Kubernetes namespace (default: protocollo-meta-salvage)
- `KUBECTL_VERSION` - kubectl version (default: v1.28.0)
- `HELM_VERSION` - Helm version (default: v3.13.0)

### Manual Script
- `NAMESPACE` - Kubernetes namespace
- `ENVIRONMENT` - Deployment environment (staging/production)
- `DRY_RUN` - Enable dry-run mode (true/false)

## Security Considerations

1. **Secrets Management**
   - Store sensitive data in Kubernetes Secrets
   - Use sealed-secrets or external secret management
   - Rotate credentials regularly

2. **RBAC**
   - Configure appropriate service accounts
   - Apply least-privilege principle
   - Audit access regularly

3. **Network Policies**
   - Restrict pod-to-pod communication
   - Control ingress/egress traffic
   - Monitor network flows

4. **TLS/SSL**
   - Use valid certificates in production
   - Enable mutual TLS where applicable
   - Rotate certificates before expiry

## Monitoring Deployment

### GitHub Actions
- View workflow runs in Actions tab
- Download deployment reports from artifacts
- Check notification in workflow summary

### Manual Deployment
- Monitor script output for status
- Check generated deployment report
- Verify services are accessible

## Next Steps

1. Review deployed components
2. Configure monitoring alerts
3. Test security features
4. Set up automated backups
5. Configure disaster recovery
6. Document custom configurations
7. Train team on operations

## Support

For issues or questions:
- GitHub Issues: https://github.com/hannesmitterer/Peacebonds/issues
- Documentation: See SECURITY_ENHANCEMENTS.md

---

**Version:** 1.0  
**Last Updated:** January 2026
