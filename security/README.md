# Security and Resilience Features

This directory contains security and resilience enhancements for the PeaceBonds decentralized operations platform.

## Features

### 1. Real-time Monitoring Dashboard (Grafana + Loki)

**Location:** `monitoring/`

Provides real-time visualization of:
- Node status and health
- Network latency metrics
- Intrusion detection logs
- Peace Bond violations
- Provider symbiosis scores

**Components:**
- **Grafana**: Web-based analytics and visualization
- **Loki**: Log aggregation system
- **Prometheus**: Metrics collection (uses existing protocollo-meta-salvage setup)

**Setup:**
```bash
# Start Loki
loki -config.file=monitoring/loki/loki-config.yaml

# Start Grafana
grafana-server --config=monitoring/grafana/grafana.ini

# Access dashboard at http://localhost:3000
# Default credentials: admin / peacebonds_monitoring_admin
```

### 2. Automated Forensic Response System

**Location:** `security/forensics/`

Monitors logs for suspicious activity and automatically activates Tor/VPN routing when threats are detected.

**Features:**
- Real-time log monitoring
- Pattern-based threat detection
- Automatic Tor activation for high-severity threats
- VPN fallback mechanism
- Configurable response thresholds

**Setup:**
```bash
cd security/forensics

# Configure settings
sudo cp forensic-config.json /etc/peacebonds/forensic-config.json
# Edit /etc/peacebonds/forensic-config.json as needed

# Install and start service
sudo ./install.sh
sudo systemctl start peacebonds-forensic-watcher
sudo systemctl enable peacebonds-forensic-watcher

# View logs
sudo journalctl -u peacebonds-forensic-watcher -f
```

**Configuration:**
Edit `/etc/peacebonds/forensic-config.json` to customize:
- Log files to monitor
- Suspicious activity patterns
- Detection thresholds
- Response actions (Tor/VPN priority)

### 3. Secure Firmware Update System

**Location:** `security/firmware-updates/`

Ensures firmware updates are authentic and untampered using cryptographic verification.

**Features:**
- SHA256 checksum verification
- GPG signature verification
- IPFS-based distribution
- Automatic backup before updates
- Rollback capability

**Setup:**
```bash
cd security/firmware-updates

# Make script executable
chmod +x firmware-update.sh

# Perform update
sudo ./firmware-update.sh update-manifest.json
```

**Update Manifest Format:**
```json
{
  "version": "1.0.0",
  "firmware_cid": "QmExample123FirmwarePackage",
  "checksum_cid": "QmExample123Checksum",
  "signature_cid": "QmExample123Signature",
  "release_date": "2026-01-20",
  "description": "Update description"
}
```

### 4. Distributed Encrypted Backup System

**Location:** `security/backups/`

Automates encrypted backups to IPFS with GnuPG encryption.

**Features:**
- Automatic encryption with GnuPG
- IPFS distributed storage
- Configurable backup paths
- Metadata tracking
- Simple restore process

**Setup:**
```bash
cd security/backups

# Configure settings
sudo cp backup-config.json /etc/peacebonds/backup-config.json

# Generate GPG key if needed
gpg --gen-key
# Note the email address used

# Update config with GPG recipient email
sudo nano /etc/peacebonds/backup-config.json

# Create backup
python3 ipfs-backup.py backup

# Restore backup
python3 ipfs-backup.py restore <CID> /restore/path
```

**Scheduling Backups:**
Add to crontab for daily backups:
```bash
# Daily backup at 2 AM
0 2 * * * /usr/bin/python3 /opt/peacebonds/security/backups/ipfs-backup.py backup >> /var/log/peacebonds/backup-cron.log 2>&1
```

### 5. Communication Protocol Hardening (QUIC + TLS 1.3)

**Location:** `security/network-hardening/`

Implements QUIC protocol with TLS 1.3 and disables unencrypted communications.

**Features:**
- TLS 1.3 only (legacy protocols disabled)
- QUIC protocol support
- Strong cipher suites only
- Mutual TLS authentication (optional)
- Unencrypted communication blocking

**Setup:**
```bash
cd security/network-hardening

# Install dependencies and setup certificates
chmod +x setup-quic.sh
sudo ./setup-quic.sh

# Test TLS 1.3 server
python3 secure-connection.py server

# Test TLS 1.3 client (in another terminal)
python3 secure-connection.py client
```

**Integration:**
Use the `SecureConnectionManager` class in your applications:

```python
from security.network_hardening.secure_connection import (
    SecureConnectionConfig,
    SecureConnectionManager
)

config = SecureConnectionConfig()
manager = SecureConnectionManager(config)

# Wrap server socket
secure_socket = manager.wrap_socket_server(server_socket)

# Wrap client socket
secure_socket = manager.wrap_socket_client(client_socket, 'hostname')

# Verify connection security
if manager.verify_connection_security(secure_socket):
    # Proceed with secure communication
    pass
```

## Integration with Existing Infrastructure

These security features integrate with the existing `protocollo-meta-salvage` infrastructure:

- **Monitoring**: Uses the same Prometheus setup for metrics collection
- **Logging**: Loki aggregates logs from all security components
- **Alerts**: Forensic system can trigger Peace Bond activations
- **Backups**: IPFS integration aligns with existing content-addressed storage

## Security Best Practices

1. **Certificates**: Replace self-signed certificates with proper CA-signed certificates in production
2. **Secrets**: Store GPG keys and TLS private keys securely with proper permissions (600)
3. **Monitoring**: Regularly review security alerts and forensic logs
4. **Updates**: Keep firmware and dependencies up-to-date using the secure update system
5. **Backups**: Test restore procedures regularly
6. **Network**: Never enable `allow_unencrypted` in production

## Dependencies

### Python Packages
```bash
pip3 install prometheus-client aioquic cryptography
```

### System Packages
```bash
# Debian/Ubuntu
sudo apt-get install tor openvpn gnupg curl jq

# Monitoring stack
sudo apt-get install grafana loki
```

### Optional
- IPFS daemon for distributed backup storage
- Docker and Docker Compose for containerized deployment

## Troubleshooting

### Forensic Watcher
- Check logs: `sudo journalctl -u peacebonds-forensic-watcher`
- Verify Tor is installed: `systemctl status tor`
- Check configuration: `/etc/peacebonds/forensic-config.json`

### Firmware Updates
- Verify IPFS connectivity: `curl http://127.0.0.1:5001/api/v0/version`
- Check GPG keyring: `gpg --list-keys`
- Review update logs: `/var/log/peacebonds/firmware-updates.log`

### Backups
- Test GPG encryption: `gpg --list-keys`
- Verify IPFS: `ipfs version`
- Check backup logs: `/var/log/peacebonds/backup.log`

### Network Hardening
- Verify TLS 1.3 support: `openssl version`
- Check certificates: `openssl x509 -in /etc/peacebonds/certs/server.crt -text -noout`
- Test connection: `openssl s_client -connect localhost:8443 -tls1_3`

## License

MIT License - See repository LICENSE file
