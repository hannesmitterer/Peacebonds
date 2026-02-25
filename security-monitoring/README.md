# VCD-01 Security Monitoring & Active Defense System

## Overview

This directory contains the deployment and configuration for real-time network surveillance and active defense mechanisms to protect the VCD-01 infrastructure against threats.

## Suspicious IP List

The following IPs are monitored with enhanced surveillance:
- `185.191.171.3`
- `192.0.78.24`
- `192.0.78.25`
- `52.230.152.148`
- `34.223.12.181`
- `66.249.66.75`

## Components

### 1. Network Monitoring (`configs/`)
- **Zeek Configuration**: Real-time packet capture and analysis
- **Suricata Rules**: Intrusion detection signatures
- **eBPF Scripts**: Low-level packet filtering
- **Elasticsearch Integration**: Log aggregation and search

### 2. Active Defense (`scripts/`)
- **Rate Limiting**: iptables/nftables rules with hashlimit
- **Honey Tokens**: Decoy endpoints and files
- **Port Knocking**: Dynamic access control
- **Traffic Shaping**: Bandwidth throttling for suspicious IPs

### 3. Countermeasures
- **TLS Fingerprinting**: Client certificate verification
- **Deception Canvas**: Fake services (SSH, HTTP)
- **Threat Intel Integration**: OTX, AbuseIPDB feeds
- **Automated Alerts**: Slack/Discord webhooks

## Quick Start

### Prerequisites

```bash
# Install required packages (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y \
    zeek \
    suricata \
    iptables \
    nftables \
    knockd \
    iproute2 \
    elasticsearch \
    kibana \
    python3-pip

# Install Python dependencies
pip3 install requests elasticsearch python-dotenv
```

### Deployment

```bash
# 1. Deploy monitoring configuration
cd security-monitoring
sudo bash scripts/deploy-monitoring.sh

# 2. Configure rate limiting
sudo bash scripts/setup-rate-limiting.sh

# 3. Deploy honey tokens
sudo bash scripts/deploy-honey-tokens.sh

# 4. Start monitoring services
sudo bash scripts/start-services.sh
```

### Verification

```bash
# Check Zeek is capturing traffic
sudo zeekctl status

# Verify iptables rules
sudo iptables -L -n -v | grep -A5 "suspicious-ips"

# Check Elasticsearch connectivity
curl -X GET "localhost:9200/_cluster/health?pretty"

# View recent alerts
tail -f /var/log/vcd01-security/alerts.log
```

## Directory Structure

```
security-monitoring/
├── README.md                          # This file
├── configs/
│   ├── zeek/
│   │   ├── local.zeek                # Zeek configuration
│   │   └── suspicious-ips.zeek       # IP monitoring rules
│   ├── suricata/
│   │   ├── suricata.yaml            # Suricata config
│   │   └── custom.rules             # Custom detection rules
│   ├── iptables/
│   │   ├── rate-limit.rules         # Rate limiting rules
│   │   └── suspicious-ips.rules     # IP-specific rules
│   ├── knockd/
│   │   └── knockd.conf              # Port knocking config
│   ├── nginx/
│   │   ├── honey-tokens.conf        # Honey token endpoints
│   │   └── tls-fingerprint.conf     # TLS verification
│   └── elasticsearch/
│       └── index-template.json      # ES index template
├── scripts/
│   ├── deploy-monitoring.sh         # Main deployment script
│   ├── setup-rate-limiting.sh       # Rate limit configuration
│   ├── deploy-honey-tokens.sh       # Honey token deployment
│   ├── setup-port-knocking.sh       # Port knocking setup
│   ├── threat-intel-sync.py         # Threat intel integration
│   ├── ebpf-capture.py              # eBPF packet capture
│   └── start-services.sh            # Service startup
├── logs/
│   └── .gitkeep                     # Log directory placeholder
└── docs/
    ├── DEPLOYMENT.md                # Detailed deployment guide
    ├── OPERATIONS.md                # Operations manual
    └── TROUBLESHOOTING.md           # Common issues
```

## Monitoring Workflow

1. **Ingest**: Capture packets with Zeek, label those from suspicious IPs
2. **Enrich**: Add threat-intel data (ASN, reputation)
3. **Detect**: Suricata/Zeek rules for attack patterns (SQLi, LFI, credential stuffing)
4. **Respond**: Automate actions (rate-limit, honey-token trigger, port-knocking)
5. **Retain**: Archive logs for 90 days in S3 with encryption

## Security Considerations

- **Data Retention**: Logs are retained for 90 days in Elasticsearch, then archived to S3
- **Privacy**: Only metadata and packet headers are logged, not payload content (except for suspicious IPs)
- **Performance**: eBPF and Zeek are optimized for high-throughput, low-latency monitoring
- **Compliance**: System adheres to VCD-01 security framework and Lex Amoris principles

## Integration with VCD-01

This security monitoring system integrates with:
- **Node Monitoring** (`scripts/monitoring/node-monitor.js`): Network health metrics
- **Peace Contribution Engine**: Security event logging
- **Governance Framework**: Alert escalation procedures
- **QRS Protocol**: Multi-layer security enforcement

## Threat Response Levels

| Level | Trigger | Action | Response Time |
|-------|---------|--------|---------------|
| L1 - Info | First packet from suspicious IP | Log to Elasticsearch | Immediate |
| L2 - Warning | >5 requests/second | Rate limit (5 min drop) | <1 second |
| L3 - Alert | Honey token access | Block + Alert operators | <5 seconds |
| L4 - Critical | Pattern match (SQLi, LFI) | Full block + Investigation | <30 seconds |

## Support

- **Documentation**: `/docs/SECURITY.md`
- **Operations**: `security-monitoring/docs/OPERATIONS.md`
- **Incidents**: security@vcd01.network
- **GitHub Issues**: https://github.com/hannesmitterer/Peacebonds/issues

---

**Last Updated**: 2026-02-25  
**Version**: 1.0  
**Maintained By**: VCD-01 Security Team
