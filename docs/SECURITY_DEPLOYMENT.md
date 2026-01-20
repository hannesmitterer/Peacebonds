# Security Features Deployment Guide

This guide provides step-by-step instructions for deploying the security and resilience features in production.

## Prerequisites

### System Requirements
- Ubuntu 20.04+ or Debian 11+ (recommended)
- 4GB RAM minimum (8GB recommended)
- 50GB disk space
- Root/sudo access

### Software Dependencies

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install core dependencies
sudo apt-get install -y \
    python3 \
    python3-pip \
    curl \
    wget \
    gnupg \
    tor \
    openvpn \
    jq \
    git

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Python packages
sudo pip3 install prometheus-client aioquic cryptography
```

### Install IPFS

```bash
# Download and install IPFS
wget https://dist.ipfs.tech/kubo/v0.23.0/kubo_v0.23.0_linux-amd64.tar.gz
tar -xvzf kubo_v0.23.0_linux-amd64.tar.gz
cd kubo
sudo bash install.sh

# Initialize IPFS
ipfs init

# Configure IPFS
ipfs config Addresses.API /ip4/127.0.0.1/tcp/5001
ipfs config Addresses.Gateway /ip4/127.0.0.1/tcp/8080

# Start IPFS daemon
ipfs daemon &
```

## Deployment Steps

### 1. Clone Repository

```bash
cd /opt
sudo git clone https://github.com/hannesmitterer/Peacebonds.git
sudo chown -R $USER:$USER Peacebonds
cd Peacebonds
```

### 2. Deploy Monitoring Stack

```bash
# Create required directories
sudo mkdir -p /var/lib/grafana /var/lib/prometheus /tmp/loki

# Set permissions
sudo chown -R 472:472 /var/lib/grafana
sudo chown -R 65534:65534 /var/lib/prometheus

# Start monitoring stack
docker-compose -f docker-compose.monitoring.yml up -d

# Verify services are running
docker-compose -f docker-compose.monitoring.yml ps

# Access Grafana
echo "Grafana: http://localhost:3000"
echo "Username: admin"
echo "Password: peacebonds_monitoring_admin"
```

### 3. Configure Forensic Response System

```bash
# Create configuration directory
sudo mkdir -p /etc/peacebonds /var/log/peacebonds

# Copy configuration
sudo cp security/forensics/forensic-config.json /etc/peacebonds/

# Edit configuration as needed
sudo nano /etc/peacebonds/forensic-config.json

# Create systemd service
sudo cat > /etc/systemd/system/peacebonds-forensic-watcher.service << 'EOF'
[Unit]
Description=PeaceBonds Forensic Log Watcher
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/Peacebonds/security/forensics
ExecStart=/usr/bin/python3 /opt/Peacebonds/security/forensics/log-watcher.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable peacebonds-forensic-watcher
sudo systemctl start peacebonds-forensic-watcher

# Check status
sudo systemctl status peacebonds-forensic-watcher

# View logs
sudo journalctl -u peacebonds-forensic-watcher -f
```

### 4. Setup Secure Firmware Updates

```bash
# Create firmware directory
sudo mkdir -p /var/lib/peacebonds/firmware
sudo mkdir -p /var/backups/peacebonds/firmware

# Setup GPG keyring for trusted keys
sudo mkdir -p /etc/peacebonds
sudo gpg --no-default-keyring --keyring /etc/peacebonds/trusted-keys.gpg --list-keys

# Import trusted public keys (replace with your keys)
# sudo gpg --no-default-keyring --keyring /etc/peacebonds/trusted-keys.gpg --import public-key.asc

# Make script executable
chmod +x security/firmware-updates/firmware-update.sh

# Test with example manifest (update CIDs first)
# sudo security/firmware-updates/firmware-update.sh security/firmware-updates/update-manifest.example.json
```

### 5. Configure Encrypted Backups

```bash
# Generate GPG key for backups
gpg --gen-key
# Note the email address used

# Create backup configuration
sudo cp security/backups/backup-config.json /etc/peacebonds/

# Update GPG recipient in config
sudo nano /etc/peacebonds/backup-config.json
# Set "gpg_recipient" to your GPG key email

# Create backup directories
sudo mkdir -p /var/backups/peacebonds
sudo mkdir -p /var/lib/peacebonds/data

# Test backup
python3 security/backups/ipfs-backup.py backup

# Setup daily automated backups
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/bin/python3 /opt/Peacebonds/security/backups/ipfs-backup.py backup >> /var/log/peacebonds/backup-cron.log 2>&1") | crontab -
```

### 6. Configure Network Hardening

```bash
# Run QUIC setup script
cd security/network-hardening
sudo ./setup-quic.sh

# Verify certificates were created
ls -l /etc/peacebonds/certs/

# For production: Replace self-signed certificates with CA-signed certificates
# sudo cp /path/to/your/server.crt /etc/peacebonds/certs/
# sudo cp /path/to/your/server.key /etc/peacebonds/certs/
# sudo cp /path/to/your/ca.crt /etc/peacebonds/certs/

# Set proper permissions
sudo chmod 600 /etc/peacebonds/certs/server.key
sudo chmod 644 /etc/peacebonds/certs/server.crt
sudo chmod 644 /etc/peacebonds/certs/ca.crt
```

## Production Configuration

### Security Hardening

```bash
# 1. Secure file permissions
sudo chown -R root:root /etc/peacebonds
sudo chmod 700 /etc/peacebonds
sudo chmod 600 /etc/peacebonds/*.json
sudo chmod 600 /etc/peacebonds/certs/*.key
sudo chmod 644 /etc/peacebonds/certs/*.crt

# 2. Configure firewall
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 9090/tcp  # Prometheus
sudo ufw allow 8443/tcp  # TLS server
sudo ufw allow 4433/tcp  # QUIC
sudo ufw enable

# 3. Setup log rotation
sudo cat > /etc/logrotate.d/peacebonds << 'EOF'
/var/log/peacebonds/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
}
EOF
```

### Replace Default Passwords

```bash
# 1. Change Grafana admin password
# Login to Grafana at http://localhost:3000
# Go to: User > Change Password

# 2. Update configuration files
sudo nano /opt/Peacebonds/monitoring/grafana/grafana.ini
# Change admin_password and secret_key
```

### Configure TLS Certificates (Production)

```bash
# Option 1: Use Let's Encrypt
sudo apt-get install certbot
sudo certbot certonly --standalone -d your-domain.com

# Copy certificates
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /etc/peacebonds/certs/server.crt
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem /etc/peacebonds/certs/server.key

# Option 2: Use your own CA-signed certificates
# Copy your certificates to /etc/peacebonds/certs/
```

## Verification and Testing

### 1. Verify Monitoring Stack

```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check Loki
curl http://localhost:3100/ready

# Check Grafana
curl http://localhost:3000/api/health
```

### 2. Test Forensic Response

```bash
# Trigger a test alert by creating suspicious log entries
echo "Failed password for testuser from 192.168.1.100" | sudo tee -a /var/log/peacebonds/app.log

# Check if alert was detected
sudo journalctl -u peacebonds-forensic-watcher -n 50
```

### 3. Test Backup and Restore

```bash
# Create test data
sudo mkdir -p /var/lib/peacebonds/data
echo "Test data" | sudo tee /var/lib/peacebonds/data/test.txt

# Create backup
python3 security/backups/ipfs-backup.py backup

# Note the CID from output, then test restore
python3 security/backups/ipfs-backup.py restore <CID> /tmp/restore-test

# Verify restored data
cat /tmp/restore-test/var/lib/peacebonds/data/test.txt
```

### 4. Test Network Hardening

```bash
# Start TLS 1.3 server (in one terminal)
cd security/network-hardening
python3 secure-connection.py server

# Test connection (in another terminal)
python3 secure-connection.py client

# Verify TLS 1.3 is used
openssl s_client -connect localhost:8443 -tls1_3
```

## Monitoring and Maintenance

### View Service Logs

```bash
# Forensic watcher
sudo journalctl -u peacebonds-forensic-watcher -f

# Docker containers
docker-compose -f docker-compose.monitoring.yml logs -f

# Backup logs
tail -f /var/log/peacebonds/backup.log
```

### Health Checks

```bash
# Check all services
systemctl status peacebonds-forensic-watcher
docker-compose -f docker-compose.monitoring.yml ps
ipfs id

# Check disk space
df -h /var/lib/grafana /var/lib/prometheus /var/backups/peacebonds
```

## Troubleshooting

See [security/README.md](../security/README.md) for detailed troubleshooting information.

## Security Notes

1. **Never commit secrets** to version control
2. **Change all default passwords** in production
3. **Use proper TLS certificates** from a trusted CA
4. **Regularly update** dependencies and system packages
5. **Monitor logs** for suspicious activity
6. **Test backups** regularly
7. **Keep GPG keys secure** with proper permissions (600)
8. **Enable firewall** and restrict access to necessary ports only
