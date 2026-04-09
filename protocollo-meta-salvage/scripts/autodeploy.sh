#!/bin/bash
#
# Auto-Deploy Security Enhancements
# Automated deployment script for all security components
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="${NAMESPACE:-protocollo-meta-salvage}"
ENVIRONMENT="${ENVIRONMENT:-staging}"
KUBECTL_VERSION="v1.28.0"
HELM_VERSION="v3.13.0"
DRY_RUN="${DRY_RUN:-false}"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $@"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $@"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $@"
}

log_error() {
    echo -e "${RED}[✗]${NC} $@"
}

log_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  $1${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print banner
print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔════════════════════════════════════════════════════════╗
║                                                        ║
║     PEACEBONDS SECURITY ENHANCEMENTS                   ║
║     Automated Deployment System                        ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    echo "Environment: $ENVIRONMENT"
    echo "Namespace:   $NAMESPACE"
    echo "Dry Run:     $DRY_RUN"
    echo ""
}

# Check prerequisites
check_prerequisites() {
    log_header "Checking Prerequisites"
    
    local missing=()
    
    # Check required commands
    for cmd in kubectl helm jq python3; do
        if ! command -v $cmd &> /dev/null; then
            missing+=("$cmd")
        else
            log_success "$cmd is installed"
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        log_info "Please install them first"
        exit 1
    fi
    
    # Check kubectl connectivity
    if [ "$DRY_RUN" != "true" ]; then
        if ! kubectl cluster-info &> /dev/null; then
            log_error "Cannot connect to Kubernetes cluster"
            log_info "Please configure kubectl first"
            exit 1
        fi
        log_success "Connected to Kubernetes cluster"
    else
        log_warn "Dry run mode - skipping cluster connectivity check"
    fi
    
    log_success "All prerequisites met"
}

# Validate configurations
validate_configs() {
    log_header "Validating Configurations"
    
    cd "$PROJECT_ROOT"
    
    # Validate Python scripts
    log_info "Validating Python scripts..."
    python3 -m py_compile protocollo-meta-salvage/scripts/forensic-response.py
    log_success "Forensic response script validated"
    
    # Validate Bash scripts
    log_info "Validating Bash scripts..."
    bash -n protocollo-meta-salvage/scripts/firmware-update.sh
    bash -n protocollo-meta-salvage/scripts/ipfs-backup.sh
    bash -n protocollo-meta-salvage/scripts/setup-quic-server.sh
    log_success "All Bash scripts validated"
    
    # Validate YAML
    log_info "Validating YAML configurations..."
    python3 -c "import yaml; yaml.safe_load(open('protocollo-meta-salvage/config/loki-config.yaml'))"
    python3 -c "import yaml; yaml.safe_load(open('protocollo-meta-salvage/config/quic-config.yaml'))"
    python3 -c "import yaml; list(yaml.safe_load_all(open('protocollo-meta-salvage/infrastructure/security-enhancements-manifests.yaml')))"
    log_success "All YAML files validated"
    
    # Validate JSON
    log_info "Validating JSON configurations..."
    python3 -c "import json; json.load(open('protocollo-meta-salvage/monitoring/grafana-dashboard.json'))"
    log_success "Grafana dashboard validated"
    
    log_success "All configurations validated"
}

# Create namespace
create_namespace() {
    log_header "Creating Namespace"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warn "Dry run - would create namespace: $NAMESPACE"
        return
    fi
    
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        log_warn "Namespace $NAMESPACE already exists"
    else
        kubectl create namespace $NAMESPACE
        kubectl label namespace $NAMESPACE name=$NAMESPACE environment=$ENVIRONMENT
        log_success "Namespace created: $NAMESPACE"
    fi
}

# Setup Helm repositories
setup_helm_repos() {
    log_header "Setting Up Helm Repositories"
    
    log_info "Adding Helm repositories..."
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    
    log_info "Updating Helm repositories..."
    helm repo update
    
    log_success "Helm repositories configured"
}

# Deploy monitoring stack
deploy_monitoring() {
    log_header "Deploying Monitoring Stack"
    
    cd "$PROJECT_ROOT"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warn "Dry run - would deploy monitoring stack"
        return
    fi
    
    # Create Loki ConfigMap
    log_info "Creating Loki ConfigMap..."
    kubectl create configmap loki-config \
        --from-file=protocollo-meta-salvage/config/loki-config.yaml \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    log_success "Loki ConfigMap created"
    
    # Create Grafana dashboard ConfigMap
    log_info "Creating Grafana dashboard ConfigMap..."
    kubectl create configmap grafana-dashboards \
        --from-file=protocollo-meta-salvage/monitoring/grafana-dashboard.json \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    log_success "Grafana dashboard ConfigMap created"
    
    # Deploy Loki
    log_info "Deploying Loki..."
    helm upgrade --install loki grafana/loki-stack \
        --namespace=$NAMESPACE \
        --set loki.persistence.enabled=true \
        --set loki.persistence.size=10Gi \
        --set promtail.enabled=true \
        --wait --timeout 5m
    log_success "Loki deployed"
    
    # Deploy Grafana
    log_info "Deploying Grafana..."
    helm upgrade --install grafana grafana/grafana \
        --namespace=$NAMESPACE \
        --set persistence.enabled=true \
        --set persistence.size=10Gi \
        --set adminPassword=admin123 \
        --wait --timeout 5m
    log_success "Grafana deployed"
}

# Deploy security services
deploy_security_services() {
    log_header "Deploying Security Services"
    
    cd "$PROJECT_ROOT"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warn "Dry run - would deploy security services"
        return
    fi
    
    # Create script ConfigMaps
    log_info "Creating script ConfigMaps..."
    
    kubectl create configmap forensic-scripts \
        --from-file=forensic-response.py=protocollo-meta-salvage/scripts/forensic-response.py \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create configmap backup-scripts \
        --from-file=ipfs-backup.sh=protocollo-meta-salvage/scripts/ipfs-backup.sh \
        --from-file=firmware-update.sh=protocollo-meta-salvage/scripts/firmware-update.sh \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create configmap quic-config \
        --from-file=quic-config.yaml=protocollo-meta-salvage/config/quic-config.yaml \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Script ConfigMaps created"
    
    # Deploy security enhancements
    log_info "Deploying security enhancements..."
    kubectl apply -f protocollo-meta-salvage/infrastructure/security-enhancements-manifests.yaml \
        --namespace=$NAMESPACE
    log_success "Security services deployed"
}

# Deploy IPFS node
deploy_ipfs() {
    log_header "Deploying IPFS Node"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warn "Dry run - would deploy IPFS node"
        return
    fi
    
    log_info "Deploying IPFS..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ipfs
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ipfs
  template:
    metadata:
      labels:
        app: ipfs
    spec:
      containers:
      - name: ipfs
        image: ipfs/kubo:latest
        ports:
        - containerPort: 5001
          name: api
        - containerPort: 8080
          name: gateway
        volumeMounts:
        - name: ipfs-data
          mountPath: /data/ipfs
      volumes:
      - name: ipfs-data
        persistentVolumeClaim:
          claimName: ipfs-data
---
apiVersion: v1
kind: Service
metadata:
  name: ipfs
  namespace: $NAMESPACE
spec:
  selector:
    app: ipfs
  ports:
  - name: api
    port: 5001
    targetPort: 5001
  - name: gateway
    port: 8080
    targetPort: 8080
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ipfs-data
  namespace: $NAMESPACE
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
EOF
    
    log_success "IPFS node deployed"
}

# Verify deployment
verify_deployment() {
    log_header "Verifying Deployment"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warn "Dry run - skipping verification"
        return
    fi
    
    log_info "Checking deployments..."
    kubectl get deployments -n $NAMESPACE
    
    log_info "Checking pods..."
    kubectl get pods -n $NAMESPACE
    
    log_info "Checking services..."
    kubectl get svc -n $NAMESPACE
    
    log_info "Checking CronJobs..."
    kubectl get cronjobs -n $NAMESPACE || true
    
    log_success "Deployment verification complete"
}

# Display access information
display_access_info() {
    log_header "Access Information"
    
    cat << EOF

${GREEN}╔════════════════════════════════════════════════════════╗
║  Deployment Complete!                                  ║
╚════════════════════════════════════════════════════════╝${NC}

${CYAN}Access Your Services:${NC}

${YELLOW}Grafana Dashboard:${NC}
  kubectl port-forward -n $NAMESPACE svc/grafana 3000:80
  URL: http://localhost:3000
  Username: admin
  Password: admin123

${YELLOW}Loki Logs:${NC}
  kubectl port-forward -n $NAMESPACE svc/loki 3100:3100
  URL: http://localhost:3100

${YELLOW}IPFS Gateway:${NC}
  kubectl port-forward -n $NAMESPACE svc/ipfs 8080:8080
  URL: http://localhost:8080

${YELLOW}IPFS API:${NC}
  kubectl port-forward -n $NAMESPACE svc/ipfs 5001:5001
  URL: http://localhost:5001

${CYAN}Useful Commands:${NC}

  # View all pods
  kubectl get pods -n $NAMESPACE

  # View forensic response logs
  kubectl logs -n $NAMESPACE -l component=forensic-response

  # View backup CronJob status
  kubectl get cronjobs -n $NAMESPACE

  # Check QUIC server
  kubectl get pods -n $NAMESPACE -l component=quic-server

${CYAN}Next Steps:${NC}

  1. Import Grafana dashboards from ConfigMap
  2. Configure TLS certificates for QUIC server
  3. Set up GPG keys for backup encryption
  4. Test forensic response system
  5. Verify automated backups

${GREEN}════════════════════════════════════════════════════════${NC}

EOF
}

# Main deployment flow
main() {
    print_banner
    
    check_prerequisites
    validate_configs
    create_namespace
    setup_helm_repos
    deploy_monitoring
    deploy_security_services
    deploy_ipfs
    verify_deployment
    display_access_info
    
    log_success "Deployment completed successfully!"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --namespace NAME      Set namespace (default: protocollo-meta-salvage)"
            echo "  --environment ENV     Set environment (default: staging)"
            echo "  --dry-run            Simulate deployment without making changes"
            echo "  --help               Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main
