# Open Policy Agent (OPA) Policies for Protocollo Meta Salvage
# Peace Bonds Decision Engine and Enforcement Rules

package protocollo.meta_salvage

import future.keywords.if
import future.keywords.in

# Default deny - Peace Bonds require explicit approval
default allow = false

# Default Peace Bond status
default peace_bond_required = false

# Symbiosis Score Thresholds
symbiosis_threshold_warning := 0.7
symbiosis_threshold_critical := 0.5

# Lock-in Risk Thresholds
lock_in_threshold_high := 0.8
lock_in_threshold_critical := 0.9

# Throughput Limits (requests per second)
default_throughput_limit := 10000
restricted_throughput_limit := 5000
critical_throughput_limit := 1000

# ============================================
# Peace Bond Activation Rules
# ============================================

# Activate Peace Bond when symbiosis score is below warning threshold
peace_bond_required if {
    input.metrics.symbiosis_score < symbiosis_threshold_warning
}

# Activate Emergency Peace Bond when symbiosis score is critical
emergency_peace_bond_required if {
    input.metrics.symbiosis_score < symbiosis_threshold_critical
}

# Activate Peace Bond when lock-in risk is high
peace_bond_required if {
    input.metrics.lock_in_risk_score > lock_in_threshold_high
}

# Activate Emergency Peace Bond when lock-in risk is critical
emergency_peace_bond_required if {
    input.metrics.lock_in_risk_score > lock_in_threshold_critical
}

# Activate Peace Bond when anomalies are detected
peace_bond_required if {
    input.metrics.data_flow_anomaly_rate > 0.05
}

# Activate Peace Bond when provider transparency is insufficient
peace_bond_required if {
    input.provider.metadata_completeness < 0.9
}

# ============================================
# Operational Constraints Enforcement
# ============================================

# Determine throughput limit based on risk level
throughput_limit := limit if {
    emergency_peace_bond_required
    limit := critical_throughput_limit
} else := limit if {
    peace_bond_required
    input.metrics.symbiosis_score < 0.6
    limit := restricted_throughput_limit
} else := default_throughput_limit

# Check if current throughput exceeds limit
throughput_violation if {
    input.metrics.current_throughput > throughput_limit
}

# Determine rate limiting action
rate_limiting_action := action if {
    throughput_violation
    action := {
        "apply": true,
        "limit": throughput_limit,
        "provider": input.provider.id,
        "reason": "throughput_exceeded"
    }
} else := {"apply": false}

# ============================================
# Resource Provisioning Constraints
# ============================================

# Maximum resources allowed based on Peace Bond status
max_compute_units := units if {
    emergency_peace_bond_required
    units := 10
} else := units if {
    peace_bond_required
    units := 50
} else := 200

max_storage_gb := storage if {
    emergency_peace_bond_required
    storage := 100
} else := storage if {
    peace_bond_required
    storage := 500
} else := 5000

# Validate resource provisioning request
allow_provisioning if {
    input.request.compute_units <= max_compute_units
    input.request.storage_gb <= max_storage_gb
    not critical_violations_exist
}

# ============================================
# Critical Violations Detection
# ============================================

critical_violations_exist if {
    input.violations[_].severity == "critical"
}

# Specific violation checks
violation_metadata_missing if {
    not input.provider.metadata
    peace_bond_required
}

violation_audit_data_stale if {
    time.now_ns() - input.provider.last_audit_timestamp > 3.6e+12  # 1 hour in nanoseconds
}

violation_compliance_check_failed if {
    input.provider.compliance_status != "compliant"
}

# Aggregate all violations
violations := v if {
    v := [
        {"type": "metadata_missing", "severity": "high"} |
        violation_metadata_missing
        
        {"type": "audit_data_stale", "severity": "medium"} |
        violation_audit_data_stale
        
        {"type": "compliance_failed", "severity": "critical"} |
        violation_compliance_check_failed
    ]
}

# ============================================
# Transparency Requirements
# ============================================

# Required metadata fields from CaaS providers
required_metadata_fields := [
    "provider_id",
    "service_type",
    "data_location",
    "processing_capacity",
    "compliance_certifications",
    "audit_trail_endpoint",
    "last_audit_timestamp"
]

# Check if all required metadata is present
metadata_complete if {
    count(required_metadata_fields) == count([field |
        field := required_metadata_fields[_]
        input.provider.metadata[field]
    ])
}

# Require additional transparency when Peace Bond is active
transparency_requirements := reqs if {
    peace_bond_required
    reqs := {
        "audit_frequency_hours": 1,
        "metadata_refresh_minutes": 15,
        "real_time_monitoring": true,
        "detailed_logs_required": true
    }
} else := {
    "audit_frequency_hours": 24,
    "metadata_refresh_minutes": 60,
    "real_time_monitoring": false,
    "detailed_logs_required": false
}

# ============================================
# Decision Output
# ============================================

# Main decision response
decision := {
    "allow": allow_provisioning,
    "peace_bond_required": peace_bond_required,
    "emergency_peace_bond_required": emergency_peace_bond_required,
    "throughput_limit": throughput_limit,
    "rate_limiting": rate_limiting_action,
    "max_compute_units": max_compute_units,
    "max_storage_gb": max_storage_gb,
    "violations": violations,
    "transparency_requirements": transparency_requirements,
    "metadata_complete": metadata_complete,
    "timestamp": time.now_ns()
}

# ============================================
# Audit Trail Generation
# ============================================

audit_event := event if {
    event := {
        "decision": decision,
        "input": input,
        "policy_version": "1.0",
        "evaluator": "opa",
        "timestamp": time.now_ns()
    }
}
