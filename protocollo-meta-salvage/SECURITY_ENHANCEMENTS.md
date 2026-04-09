# Security and Resilience Enhancements

This directory contains advanced security and resilience features for the PeaceBonds decentralized system.

## 🛡️ Features Implemented

### 1. Real-time Monitoring Dashboard (Grafana + Loki)

**Files:**
- `monitoring/grafana-dashboard.json` - Pre-configured Grafana dashboard
- `config/loki-config.yaml` - Loki log aggregation configuration

**Features:**
- Node status visualization
- Latency monitoring (p95 percentile)
- Intrusion detection log aggregation
- Peace Bond status tracking
- Forensic response activity monitoring

**Setup:**
```bash
# Deploy Loki
kubectl apply -f config/loki-config.yaml

# Import Grafana dashboard
curl -X POST http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @monitoring/grafana-dashboard.json
```

---

### 2. Automated Forensic Response System

**Files:**
- `scripts/forensic-response.py` - Python-based log monitoring and response system

**Features:**
- Real-time log analysis for suspicious patterns
- Automatic Tor routing activation on security alerts
- VPN failover for secure communication
- IP quarantine for aggressive attackers
- Loki integration for forensic log storage

**Usage:**
```bash
# Start the forensic response monitor
./scripts/forensic-response.py

# Configure environment variables
export LOG_FILE=/var/log/peacebonds/security.log
export TOR_ENABLED=true
export VPN_ENABLED=true
export ALERT_THRESHOLD=5
export QUARANTINE_THRESHOLD=10
```

**Suspicious Patterns Detected:**
- Failed login attempts
- SQL injection / XSS attempts
- Port scanning
- Brute force attacks
- Malware signatures
- Data exfiltration attempts
- Privilege escalation
- DDoS attacks

---

### 3. Secure Firmware Update Mechanism

**Files:**
- `scripts/firmware-update.sh` - Bash script for secure firmware updates

**Features:**
- SHA256/SHA512 checksum verification
- GPG cryptographic signature validation
- Automatic backup before update
- Rollback capability
- Version management

**Usage:**
```bash
# Import trusted signing key
./scripts/firmware-update.sh import-key /path/to/public-key.asc

# Check for updates
./scripts/firmware-update.sh check

# Install updates
./scripts/firmware-update.sh update

# Rollback if needed
./scripts/firmware-update.sh rollback

# Check current version
./scripts/firmware-update.sh version
```

**Security Guarantees:**
- All firmware packages must be signed with trusted GPG key
- Checksums are verified before installation
- Automatic backup ensures safe rollback
- Complete audit trail in logs

---

### 4. Autonomous Encrypted Distributed Backups

**Files:**
- `scripts/ipfs-backup.sh` - IPFS-based distributed backup system

**Features:**
- IPFS distributed storage
- GnuPG encryption (AES-256)
- Automatic key generation
- IPNS publishing for easy discovery
- Checksum verification
- Metadata tracking
- Automatic cleanup of old backups

**Usage:**
```bash
# Create encrypted backup
./scripts/ipfs-backup.sh create

# List all backups
./scripts/ipfs-backup.sh list

# Restore from IPFS hash
./scripts/ipfs-backup.sh restore QmXxxx... /restore/path

# Verify backup integrity
./scripts/ipfs-backup.sh verify QmXxxx...

# Cleanup old backups (>90 days)
./scripts/ipfs-backup.sh cleanup
```

**Configuration:**
```bash
export BACKUP_SOURCE=/opt/peacebonds/data
export GPG_RECIPIENT=peacebonds@backup
export RETENTION_DAYS=90
export IPFS_API=http://localhost:5001
```

**Security Features:**
- End-to-end encryption with GPG
- Distributed storage prevents single point of failure
- Checksum verification ensures data integrity
- Automatic key management

---

### 5. Communication Protocol Hardening (QUIC + TLS 1.3)

**Files:**
- `config/quic-config.yaml` - QUIC protocol configuration
- `scripts/setup-quic-server.sh` - Automated QUIC server setup

**Features:**
- TLS 1.3 only (older versions disabled)
- Strong cipher suites (AES-256-GCM, ChaCha20-Poly1305)
- HTTP/3 support
- 0-RTT connection establishment
- ECN (Explicit Congestion Notification)
- Mutual TLS authentication
- HSTS enforcement
- DDoS protection
- Rate limiting

**Setup:**
```bash
# Automated installation (requires root)
sudo ./scripts/setup-quic-server.sh

# Start QUIC server
sudo systemctl start peacebonds-quic
sudo systemctl enable peacebonds-quic

# Check status
sudo systemctl status peacebonds-quic
```

**Security Hardening:**
- ✅ SSLv2/SSLv3 disabled
- ✅ TLS 1.0/1.1/1.2 disabled
- ✅ Only TLS 1.3 enabled
- ✅ Perfect Forward Secrecy (PFS)
- ✅ Certificate pinning support
- ✅ OCSP stapling
- ✅ Security headers (HSTS, CSP, etc.)

**Performance Benefits:**
- Reduced latency (0-RTT)
- Better congestion control (CUBIC/BBR)
- Improved loss recovery
- Multiplexed streams without head-of-line blocking

---

## 🔐 Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                           │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. Monitoring & Detection (Grafana + Loki)                 │
│     ↓                                                         │
│  2. Forensic Response (Tor/VPN Activation)                  │
│     ↓                                                         │
│  3. Secure Communications (QUIC + TLS 1.3)                  │
│     ↓                                                         │
│  4. Data Protection (Encrypted Backups)                     │
│     ↓                                                         │
│  5. System Integrity (Signed Firmware Updates)              │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Integration with Existing Infrastructure

### Kubernetes Deployment

Add to `infrastructure/kubernetes-manifests.yaml`:

```yaml
# Forensic Response CronJob
apiVersion: batch/v1
kind: CronJob
metadata:
  name: forensic-monitor
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: forensic-response
            image: peacebonds/forensic-response:latest
            env:
            - name: LOG_FILE
              value: /var/log/peacebonds/security.log
            volumeMounts:
            - name: logs
              mountPath: /var/log/peacebonds
```

### Prometheus Metrics

Add to `config/prometheus-config.yaml`:

```yaml
scrape_configs:
  - job_name: 'quic-server'
    static_configs:
      - targets:
          - localhost:9090
    metrics_path: /metrics
```

---

## 🧪 Testing

### Test Forensic Response
```bash
# Simulate suspicious activity
echo "[$(date)] ERROR: Failed login from 192.168.1.100" >> /var/log/peacebonds/security.log
echo "[$(date)] WARNING: SQL injection attempt detected" >> /var/log/peacebonds/security.log
```

### Test Firmware Update
```bash
# Create test manifest
cat > /tmp/manifest.json << EOF
{
  "version": "1.1.0",
  "download_url": "https://example.com/firmware.tar.gz",
  "checksum": { "sha256": "abc123..." },
  "signature_url": "https://example.com/firmware.tar.gz.sig"
}
EOF
```

### Test IPFS Backup
```bash
# Ensure IPFS daemon is running
ipfs daemon &

# Create test backup
./scripts/ipfs-backup.sh create
```

### Test QUIC Server
```bash
# Install curl with HTTP/3 support
curl --http3 https://localhost:443
```

---

## 📈 Monitoring & Metrics

### Key Metrics Available

**Forensic Response:**
- `intrusion_attempts_total` - Total intrusion attempts detected
- `tor_activations_total` - Times Tor routing was activated
- `vpn_activations_total` - Times VPN routing was activated
- `quarantined_ips_total` - Number of IPs quarantined

**Firmware Updates:**
- `firmware_updates_total` - Total updates performed
- `firmware_update_failures_total` - Failed updates
- `firmware_rollbacks_total` - Rollback operations

**Backups:**
- `backup_operations_total` - Total backup operations
- `backup_size_bytes` - Backup sizes
- `backup_duration_seconds` - Time to complete backup

**QUIC Server:**
- `quic_connections_total` - Total QUIC connections
- `quic_handshake_duration_milliseconds` - Handshake latency
- `quic_bytes_sent_total` - Total bytes sent
- `quic_packets_lost_total` - Packet loss rate

---

## 🔧 Configuration Files Summary

| File | Purpose |
|------|---------|
| `monitoring/grafana-dashboard.json` | Pre-configured security dashboard |
| `config/loki-config.yaml` | Log aggregation configuration |
| `config/quic-config.yaml` | QUIC protocol settings |
| `scripts/forensic-response.py` | Automated threat response |
| `scripts/firmware-update.sh` | Secure update mechanism |
| `scripts/ipfs-backup.sh` | Distributed backup system |
| `scripts/setup-quic-server.sh` | QUIC server installer |

---

## 🚀 Quick Start

```bash
# 1. Deploy monitoring
kubectl apply -f config/loki-config.yaml
curl -X POST http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @monitoring/grafana-dashboard.json

# 2. Start forensic response
./scripts/forensic-response.py &

# 3. Setup QUIC server
sudo ./scripts/setup-quic-server.sh
sudo systemctl start peacebonds-quic

# 4. Create encrypted backup
./scripts/ipfs-backup.sh create

# 5. Check for firmware updates
./scripts/firmware-update.sh check
```

---

## 📚 Additional Resources

- [QUIC Protocol Specification](https://www.rfc-editor.org/rfc/rfc9000.html)
- [TLS 1.3 Specification](https://www.rfc-editor.org/rfc/rfc8446.html)
- [IPFS Documentation](https://docs.ipfs.io/)
- [GnuPG Manual](https://www.gnupg.org/documentation/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)

---

## 🔒 Security Considerations

1. **Key Management**: Store GPG keys securely, rotate regularly
2. **Access Control**: Use RBAC for Kubernetes resources
3. **Network Segmentation**: Isolate critical components
4. **Audit Logging**: Enable comprehensive logging
5. **Incident Response**: Test forensic response regularly
6. **Backup Verification**: Regularly test restore procedures
7. **Certificate Rotation**: Automate TLS certificate renewal
8. **Rate Limiting**: Protect against DDoS attacks

---

## 📝 License

Part of the PeaceBonds ecosystem - MIT License
