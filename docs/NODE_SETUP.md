# VCD-01 Node Setup Guide

## Introduction

This guide provides detailed instructions for setting up and operating a VCD-01 network node. Nodes are the fundamental building blocks of the distributed ethical finance framework, operating at the Ψ₀.₀₄₃ resonance frequency with 98.4% integrity threshold.

## Prerequisites

### Hardware Requirements

**Minimum Specifications:**
- CPU: 4 cores @ 2.5 GHz or equivalent
- RAM: 16 GB
- Storage: 500 GB SSD (for IPFS pinning)
- Network: 100 Mbps symmetric connection
- Uptime: 98.4% minimum (≈6 days downtime/year maximum)

**Recommended Specifications:**
- CPU: 8+ cores @ 3.0 GHz
- RAM: 32 GB
- Storage: 1 TB NVMe SSD
- Network: 1 Gbps symmetric connection
- Redundant power supply and internet connectivity

### Software Requirements

- **Operating System:** Linux (Ubuntu 22.04 LTS recommended) or Docker
- **Node.js:** v18.x or higher
- **IPFS:** Kubo (go-ipfs) v0.24.0 or higher
- **Ethereum Client:** Geth 1.13.x or compatible
- **Container Runtime:** Docker 24.x (optional but recommended)

### Network Requirements

- **Open Ports:**
  - 4001 (IPFS swarm)
  - 5001 (IPFS API - localhost only)
  - 8080 (IPFS gateway - optional)
  - 30303 (Ethereum P2P)
  - 8545 (Ethereum RPC - localhost only)

- **Firewall Configuration:**
  ```bash
  # Allow IPFS swarm
  ufw allow 4001/tcp
  ufw allow 4001/udp
  
  # Allow Ethereum P2P
  ufw allow 30303/tcp
  ufw allow 30303/udp
  ```

## Installation

### Method 1: Docker Installation (Recommended)

1. **Install Docker and Docker Compose:**
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   sudo usermod -aG docker $USER
   ```

2. **Clone VCD-01 Repository:**
   ```bash
   git clone https://github.com/hannesmitterer/Peacebonds.git
   cd Peacebonds
   ```

3. **Configure Environment:**
   ```bash
   cp .env.example .env
   nano .env
   ```
   
   Set the following variables:
   ```
   NODE_TYPE=validator  # or resource, gateway, oracle
   NODE_ID=your-unique-node-id
   RESONANCE_FREQUENCY=0.043
   INTEGRITY_THRESHOLD=98.4
   IPFS_STORAGE_GB=100
   ETHEREUM_RPC_URL=https://mainnet.infura.io/v3/YOUR-KEY
   WALLET_PRIVATE_KEY=your-private-key
   ```

4. **Start Node:**
   ```bash
   docker-compose up -d
   ```

### Method 2: Manual Installation

1. **Install IPFS:**
   ```bash
   wget https://dist.ipfs.tech/kubo/v0.24.0/kubo_v0.24.0_linux-amd64.tar.gz
   tar -xvzf kubo_v0.24.0_linux-amd64.tar.gz
   cd kubo
   sudo bash install.sh
   ipfs init
   ```

2. **Configure IPFS:**
   ```bash
   ipfs config Addresses.API /ip4/127.0.0.1/tcp/5001
   ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
   ipfs config --json Datastore.StorageMax '"100GB"'
   ```

3. **Install Ethereum Client (Geth):**
   ```bash
   sudo add-apt-repository -y ppa:ethereum/ethereum
   sudo apt-get update
   sudo apt-get install ethereum
   ```

4. **Install VCD-01 Node Software:**
   ```bash
   git clone https://github.com/hannesmitterer/Peacebonds.git
   cd Peacebonds
   npm install
   npm run compile
   npm run build
   ```

5. **Configure Node:**
   ```bash
   cp .env.example .env
   nano .env
   ```
   
   Configure as shown in Docker method above.

6. **Start Services:**
   ```bash
   # Start IPFS daemon
   ipfs daemon &
   
   # Start Geth (if running local node)
   geth --http --http.api eth,net,web3 &
   
   # Start VCD-01 node
   npm start
   ```

## Node Configuration

### Node Types

#### Validator Node

Validates transactions and maintains network consensus.

**Configuration:**
```json
{
  "nodeType": "validator",
  "validatorStake": "32 ETH",
  "votingWeight": "proportional",
  "requiresKYC": false
}
```

**Responsibilities:**
- Verify blockchain transactions
- Participate in consensus
- Validate δ_E calculations
- Sign multi-sig transactions

#### Resource Node

Stores and distributes IPFS content.

**Configuration:**
```json
{
  "nodeType": "resource",
  "storageCapacity": "1TB",
  "pinnedContent": ["vcd01-manifests", "idro-data", "helios-data"],
  "bandwidthLimit": "1Gbps"
}
```

**Responsibilities:**
- Pin critical VCD-01 content
- Serve IPFS gateway requests
- Maintain content integrity
- Report replication status

#### Gateway Node

Interfaces with traditional systems and external networks.

**Configuration:**
```json
{
  "nodeType": "gateway",
  "externalAPIs": ["payment-processors", "banking", "legacy-systems"],
  "complianceLevel": "regulated",
  "jurisdiction": "EU"
}
```

**Responsibilities:**
- Bridge to fiat systems
- Regulatory compliance
- API endpoint provisioning
- External data validation

#### Oracle Node

Provides external data feeds to smart contracts.

**Configuration:**
```json
{
  "nodeType": "oracle",
  "dataSources": ["price-feeds", "weather", "iot-sensors"],
  "updateFrequency": "1min",
  "trustScore": "high"
}
```

**Responsibilities:**
- Feed real-time data to contracts
- Verify data source authenticity
- Maintain data feed uptime
- Cryptographically sign data

### Resonance Synchronization (Ψ₀.₀₄₃)

All nodes must synchronize to the Ψ₀.₀₄₃ resonance frequency for network coherence.

**Configuration File:** `config/resonance.json`
```json
{
  "targetFrequency": 0.043,
  "tolerance": 0.001,
  "syncProtocol": "ntp+blockchain",
  "calibrationInterval": "1h",
  "autoCorrection": true
}
```

**Sync Verification:**
```bash
npm run verify-resonance
```

Expected output:
```
✓ Resonance frequency: 0.0430 Hz (within tolerance)
✓ Network time sync: ±50ms
✓ Byzantine fault tolerance: 98.7%
✓ Node status: SYNCHRONIZED
```

## Network Registration

### Step 1: Generate Node Identity

```bash
npm run node-keygen
```

This generates:
- Node ID (public identifier)
- Ethereum address (for transactions)
- IPFS peer ID
- Multi-signature key share

### Step 2: Register on VCD-01 Network

```bash
npm run node-register \
  --type validator \
  --stake 32 \
  --region europe \
  --contact operator@example.com
```

### Step 3: Stake Collateral (Validator Nodes Only)

```bash
npm run stake-deposit \
  --amount 32 \
  --token ETH \
  --lock-period 6months
```

### Step 4: Join Multi-Sig (Governance Participants)

```bash
npm run multisig-join \
  --safe-address 0x... \
  --role LOGOS \
  --threshold 5of9
```

## Monitoring & Maintenance

### Health Checks

**Automated Monitoring:**
```bash
# Enable monitoring service
npm run enable-monitoring

# View real-time stats
npm run node-stats
```

**Dashboard Access:**
```
http://localhost:3000/dashboard
```

**Key Metrics:**
- Uptime percentage (target: 98.4%)
- Resonance coherence (Ψ₀.₀₄₃ ±0.001)
- Byzantine fault tolerance score
- IPFS pin count and integrity
- Ethereum sync status
- δ_E contributions processed

### Alerting Configuration

**Configure alerts in:** `config/alerts.json`
```json
{
  "uptimeThreshold": 98.4,
  "resonanceDeviation": 0.001,
  "diskSpaceWarning": "80%",
  "diskSpaceCritical": "90%",
  "notificationChannels": [
    {
      "type": "email",
      "address": "operator@example.com"
    },
    {
      "type": "webhook",
      "url": "https://alerts.example.com/webhook"
    }
  ]
}
```

### Log Management

**View logs:**
```bash
# All logs
npm run logs

# Specific service
npm run logs --service ipfs
npm run logs --service ethereum
npm run logs --service vcd01
```

**Log locations:**
- IPFS: `~/.ipfs/logs/`
- Ethereum: `~/.ethereum/logs/`
- VCD-01: `./logs/vcd01.log`

### Backup Procedures

**Backup node configuration:**
```bash
npm run backup-config --output /backup/vcd01-config-$(date +%Y%m%d).tar.gz
```

**Backup includes:**
- Node identity keys
- Configuration files
- IPFS repository metadata
- Smart contract addresses
- Governance voting history

**Recovery:**
```bash
npm run restore-config --input /backup/vcd01-config-20260119.tar.gz
```

## Security Best Practices

### Key Management

1. **Generate keys offline:**
   ```bash
   npm run keygen-offline --output ./secure-keys/
   ```

2. **Store private keys securely:**
   - Use hardware wallet (Ledger/Trezor) for validator keys
   - Encrypt key files with strong passphrase
   - Store backup in geographically separate location
   - Never commit keys to version control

3. **Rotate keys periodically:**
   ```bash
   npm run key-rotation --schedule quarterly
   ```

### Firewall Configuration

```bash
# Default deny
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (change port from default 22)
ufw allow 2222/tcp

# Allow VCD-01 required ports
ufw allow 4001/tcp  # IPFS
ufw allow 4001/udp
ufw allow 30303/tcp # Ethereum
ufw allow 30303/udp

# Enable firewall
ufw enable
```

### System Hardening

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install fail2ban
sudo apt-get install fail2ban -y

# Disable root login
sudo nano /etc/ssh/sshd_config
# Set: PermitRootLogin no

# Enable automatic security updates
sudo apt-get install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

### Monitoring Security Events

```bash
# Enable security audit logging
npm run enable-security-audit

# View security log
tail -f ./logs/security-audit.log
```

## Troubleshooting

### Common Issues

#### Node Not Synchronizing

**Symptoms:** Resonance frequency out of tolerance, peer count low

**Solutions:**
```bash
# Check NTP sync
timedatectl status

# Restart sync service
npm run restart-sync

# Check peers
ipfs swarm peers | wc -l
```

#### Low Uptime

**Symptoms:** Uptime below 98.4% threshold

**Solutions:**
- Review system logs for crashes
- Check internet connectivity stability
- Verify sufficient resources (CPU, RAM, disk)
- Enable automatic restart on failure

```bash
# Configure systemd auto-restart
sudo nano /etc/systemd/system/vcd01-node.service
```

Add:
```
[Service]
Restart=always
RestartSec=10
```

#### IPFS Pin Failures

**Symptoms:** Content not pinning, low peer count

**Solutions:**
```bash
# Check IPFS status
ipfs id
ipfs repo stat

# Reconnect to bootstrap nodes
ipfs bootstrap add /dnsaddr/bootstrap.vcd01.network

# Force garbage collection if disk full
ipfs repo gc
```

#### Byzantine Fault Detected

**Symptoms:** BFT score below threshold, network warnings

**Solutions:**
```bash
# Run integrity check
npm run integrity-check

# Verify blockchain sync
npm run verify-sync

# Check for conflicting transactions
npm run check-conflicts

# Report to network
npm run report-incident --type byzantine-fault
```

### Getting Help

**Community Support:**
- Discord: https://discord.gg/vcd01
- Forum: https://forum.vcd01.network
- GitHub Issues: https://github.com/hannesmitterer/Peacebonds/issues

**Documentation:**
- Technical Docs: `/docs/`
- API Reference: `/docs/API.md`
- Architecture: `/docs/ARCHITECTURE.md`

**Emergency Contacts:**
- Security Incidents: security@vcd01.network
- Network Issues: ops@vcd01.network

## Performance Optimization

### IPFS Optimization

```bash
# Increase connection limits
ipfs config --json Swarm.ConnMgr.HighWater 900
ipfs config --json Swarm.ConnMgr.LowWater 600

# Enable experimental features
ipfs config --json Experimental.AcceleratedDHTClient true
```

### Ethereum Optimization

```bash
# Configure cache size
geth --cache 4096

# Use fast sync
geth --syncmode snap
```

### System Optimization

```bash
# Increase file descriptor limits
echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf

# Optimize network stack
sudo sysctl -w net.core.rmem_max=134217728
sudo sysctl -w net.core.wmem_max=134217728
```

## Upgrading

### Update VCD-01 Software

```bash
# Pull latest version
git pull origin main

# Install dependencies
npm install

# Rebuild
npm run compile
npm run build

# Restart node
npm run restart
```

### Update IPFS

```bash
ipfs-update install latest
ipfs-update revert # if issues occur
```

### Update Ethereum Client

```bash
sudo apt-get update
sudo apt-get install ethereum
```

## Decommissioning

### Graceful Shutdown

```bash
# Announce shutdown to network
npm run node-shutdown --notice 7days

# Stop accepting new tasks
npm run maintenance-mode

# Complete pending operations
npm run drain-queue

# Final shutdown
npm run stop
```

### Unstake and Withdraw

```bash
# Initiate unstaking (validator nodes)
npm run unstake-request

# Wait for unstaking period (typically 7 days)

# Withdraw stake
npm run withdraw-stake
```

### Data Cleanup

```bash
# Archive logs
npm run archive-logs --output /backup/

# Remove node data (irreversible!)
npm run purge-data --confirm
```

---

## Appendix A: Hardware Vendors

**Recommended Pre-Configured Nodes:**
- DAppNode: https://dappnode.io
- Avado: https://ava.do
- NUC Setups: Custom Intel NUC configurations

## Appendix B: Cloud Deployment

**Supported Cloud Providers:**
- AWS (t3.xlarge or larger)
- Google Cloud (n2-standard-4 or larger)
- DigitalOcean (8GB Droplet or larger)
- Hetzner (CX41 or larger)

**Example Terraform Configuration:** See `/deployment/terraform/`

## Appendix C: Monitoring Stack

**Recommended Tools:**
- Prometheus: Metrics collection
- Grafana: Visualization
- Alertmanager: Alert routing
- Loki: Log aggregation

**Setup Guide:** See `/docs/MONITORING.md`

---

**Document Version:** 1.0  
**Last Updated:** January 2026  
**Maintained By:** VCD-01 Technical Working Group
