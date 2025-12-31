# Terraform Configuration for Protocollo Meta Salvage
# Dynamic Infrastructure Management and Peace Bonds Enforcement

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  
  backend "s3" {
    bucket = "protocollo-meta-salvage-state"
    key    = "terraform/state"
    region = "eu-central-1"
  }
}

# ============================================
# Provider Configuration
# ============================================

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# ============================================
# Variables
# ============================================

variable "namespace" {
  description = "Kubernetes namespace for Protocollo Meta Salvage"
  type        = string
  default     = "protocollo-meta-salvage"
}

variable "peace_bond_active" {
  description = "Whether Peace Bond restrictions are active"
  type        = bool
  default     = false
}

variable "throughput_limit" {
  description = "Throughput limit for Peace Bond enforcement (requests per second)"
  type        = number
  default     = 10000
}

variable "compute_limit" {
  description = "Compute limit for Peace Bond enforcement (CPU cores)"
  type        = number
  default     = 10
}

variable "memory_limit" {
  description = "Memory limit for Peace Bond enforcement (GB)"
  type        = number
  default     = 20
}

variable "symbiosis_threshold" {
  description = "Symbiosis score threshold for Peace Bond activation"
  type        = number
  default     = 0.7
}

# ============================================
# Namespace
# ============================================

resource "kubernetes_namespace" "protocollo" {
  metadata {
    name = var.namespace
    labels = {
      name        = var.namespace
      managed-by  = "terraform"
      component   = "protocollo-meta-salvage"
    }
  }
}

# ============================================
# Peace Bonds Resource Quotas
# ============================================

resource "kubernetes_resource_quota" "peace_bond_quota" {
  count = var.peace_bond_active ? 1 : 0
  
  metadata {
    name      = "peace-bond-quota"
    namespace = kubernetes_namespace.protocollo.metadata[0].name
  }
  
  spec {
    hard = {
      "requests.cpu"    = "${var.compute_limit}"
      "requests.memory" = "${var.memory_limit}Gi"
      "limits.cpu"      = "${var.compute_limit * 2}"
      "limits.memory"   = "${var.memory_limit * 2}Gi"
      "pods"            = "50"
    }
  }
}

# ============================================
# Peace Bonds Limit Ranges
# ============================================

resource "kubernetes_limit_range" "peace_bond_limits" {
  count = var.peace_bond_active ? 1 : 0
  
  metadata {
    name      = "peace-bond-limits"
    namespace = kubernetes_namespace.protocollo.metadata[0].name
  }
  
  spec {
    limit {
      type = "Container"
      max = {
        cpu    = "2"
        memory = "4Gi"
      }
      min = {
        cpu    = "100m"
        memory = "128Mi"
      }
      default = {
        cpu    = "500m"
        memory = "1Gi"
      }
      default_request = {
        cpu    = "250m"
        memory = "512Mi"
      }
    }
    
    limit {
      type = "Pod"
      max = {
        cpu    = "4"
        memory = "8Gi"
      }
    }
  }
}

# ============================================
# Peace Bonds Network Policies
# ============================================

resource "kubernetes_network_policy" "peace_bond_rate_limiting" {
  count = var.peace_bond_active ? 1 : 0
  
  metadata {
    name      = "peace-bond-rate-limiting"
    namespace = kubernetes_namespace.protocollo.metadata[0].name
  }
  
  spec {
    pod_selector {
      match_labels = {
        component = "caas-provider"
      }
    }
    
    policy_types = ["Ingress", "Egress"]
    
    ingress {
      from {
        pod_selector {
          match_labels = {
            access = "allowed"
          }
        }
      }
      
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }
    
    egress {
      to {
        pod_selector {
          match_labels = {
            component = "monitoring"
          }
        }
      }
      
      ports {
        port     = "9090"
        protocol = "TCP"
      }
    }
  }
}

# ============================================
# ConfigMaps for Peace Bonds Configuration
# ============================================

resource "kubernetes_config_map" "peace_bond_config" {
  metadata {
    name      = "peace-bond-config"
    namespace = kubernetes_namespace.protocollo.metadata[0].name
  }
  
  data = {
    "throughput_limit"      = tostring(var.throughput_limit)
    "symbiosis_threshold"   = tostring(var.symbiosis_threshold)
    "peace_bond_active"     = tostring(var.peace_bond_active)
    "enforcement_mode"      = var.peace_bond_active ? "strict" : "permissive"
    "audit_enabled"         = "true"
    "transparency_required" = "true"
  }
}

# ============================================
# Secrets for API Access
# ============================================

resource "kubernetes_secret" "api_credentials" {
  metadata {
    name      = "api-credentials"
    namespace = kubernetes_namespace.protocollo.metadata[0].name
  }
  
  type = "Opaque"
  
  data = {
    metrics_api_token      = base64encode("metrics-api-token-placeholder")
    provider_registry_key  = base64encode("provider-registry-key-placeholder")
    audit_service_token    = base64encode("audit-service-token-placeholder")
  }
}

# ============================================
# Kafka Deployment
# ============================================

resource "helm_release" "kafka" {
  name       = "kafka"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kafka"
  namespace  = kubernetes_namespace.protocollo.metadata[0].name
  
  values = [
    file("${path.module}/helm-values/kafka-values.yaml")
  ]
  
  set {
    name  = "replicaCount"
    value = "3"
  }
  
  set {
    name  = "auth.clientProtocol"
    value = "sasl"
  }
}

# ============================================
# Prometheus Deployment
# ============================================

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace.protocollo.metadata[0].name
  
  values = [
    file("${path.module}/helm-values/prometheus-values.yaml")
  ]
}

# ============================================
# Grafana Deployment
# ============================================

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = ""  # Must be provided via environment variable or secure vault
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace.protocollo.metadata[0].name
  
  set_sensitive {
    name  = "adminPassword"
    value = var.grafana_admin_password != "" ? var.grafana_admin_password : random_password.grafana_password.result
  }
}

resource "random_password" "grafana_password" {
  length  = 16
  special = true
}

# ============================================
# Elasticsearch Deployment
# ============================================

resource "helm_release" "elasticsearch" {
  name       = "elasticsearch"
  repository = "https://helm.elastic.co"
  chart      = "elasticsearch"
  namespace  = kubernetes_namespace.protocollo.metadata[0].name
  
  set {
    name  = "replicas"
    value = "3"
  }
}

# ============================================
# OPA Deployment
# ============================================

resource "kubernetes_deployment" "opa" {
  metadata {
    name      = "opa"
    namespace = kubernetes_namespace.protocollo.metadata[0].name
    labels = {
      app = "opa"
    }
  }
  
  spec {
    replicas = 2
    
    selector {
      match_labels = {
        app = "opa"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "opa"
        }
      }
      
      spec {
        container {
          name  = "opa"
          image = "openpolicyagent/opa:latest"
          
          args = [
            "run",
            "--server",
            "--config-file=/config/opa-config.yaml",
          ]
          
          port {
            container_port = 8181
            name           = "http"
          }
          
          volume_mount {
            name       = "opa-config"
            mount_path = "/config"
          }
          
          volume_mount {
            name       = "opa-policies"
            mount_path = "/policies"
          }
          
          liveness_probe {
            http_get {
              path = "/health"
              port = 8181
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
        
        volume {
          name = "opa-config"
          config_map {
            name = "opa-config"
          }
        }
        
        volume {
          name = "opa-policies"
          config_map {
            name = "opa-policies"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "opa" {
  metadata {
    name      = "opa"
    namespace = kubernetes_namespace.protocollo.metadata[0].name
  }
  
  spec {
    selector = {
      app = "opa"
    }
    
    port {
      port        = 8181
      target_port = 8181
      protocol    = "TCP"
    }
    
    type = "ClusterIP"
  }
}

# ============================================
# Outputs
# ============================================

output "namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.protocollo.metadata[0].name
}

output "peace_bond_status" {
  description = "Peace Bond enforcement status"
  value       = var.peace_bond_active ? "ACTIVE" : "INACTIVE"
}

output "resource_limits" {
  description = "Resource limits enforced"
  value = {
    cpu          = var.compute_limit
    memory       = var.memory_limit
    throughput   = var.throughput_limit
  }
}

output "monitoring_endpoints" {
  description = "Monitoring service endpoints"
  value = {
    prometheus = "http://prometheus.${var.namespace}.svc.cluster.local:9090"
    grafana    = "http://grafana.${var.namespace}.svc.cluster.local:3000"
    opa        = "http://opa.${var.namespace}.svc.cluster.local:8181"
  }
}
