#!/bin/bash
# Protocollo Meta Salvage - Complete Deployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE=${NAMESPACE:-protocollo-meta-salvage}
ENVIRONMENT=${ENVIRONMENT:-production}
PEACE_BOND_ACTIVE=${PEACE_BOND_ACTIVE:-false}
THROUGHPUT_LIMIT=${THROUGHPUT_LIMIT:-10000}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Protocollo Meta Salvage Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Namespace: $NAMESPACE"
echo "Environment: $ENVIRONMENT"
echo "Peace Bond Active: $PEACE_BOND_ACTIVE"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    commands=("kubectl" "helm" "terraform")
    for cmd in "${commands[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            print_error "$cmd is not installed"
            exit 1
        fi
    done
    
    # Check kubectl connectivity
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_status "All prerequisites met"
}

# Function to create namespace
create_namespace() {
    echo ""
    echo "Creating namespace..."
    
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace $NAMESPACE already exists"
    else
        kubectl create namespace $NAMESPACE
        kubectl label namespace $NAMESPACE name=$NAMESPACE
        print_status "Namespace created"
    fi
}

# Function to deploy infrastructure with Terraform
deploy_infrastructure() {
    echo ""
    echo "Deploying infrastructure with Terraform..."
    
    cd infrastructure
    
    terraform init
    print_status "Terraform initialized"
    
    terraform plan \
        -var="namespace=$NAMESPACE" \
        -var="peace_bond_active=$PEACE_BOND_ACTIVE" \
        -var="throughput_limit=$THROUGHPUT_LIMIT" \
        -out=tfplan
    
    terraform apply -auto-approve tfplan
    print_status "Infrastructure deployed"
    
    cd ..
}

# Function to add Helm repositories
add_helm_repos() {
    echo ""
    echo "Adding Helm repositories..."
    
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add elastic https://helm.elastic.co
    helm repo add apache-airflow https://airflow.apache.org
    
    helm repo update
    print_status "Helm repositories added"
}

# Function to display access information
display_access_info() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Deployment Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Access your services:"
    echo ""
    echo "Prometheus:"
    echo "  kubectl port-forward -n $NAMESPACE svc/prometheus-server 9090:80"
    echo "  http://localhost:9090"
    echo ""
    echo "Grafana:"
    echo "  kubectl port-forward -n $NAMESPACE svc/grafana 3000:80"
    echo "  http://localhost:3000"
    echo "  Username: admin"
    echo "  Password: admin123"
    echo ""
}

# Main deployment flow
main() {
    check_prerequisites
    create_namespace
    add_helm_repos
    display_access_info
}

# Run main function
main
