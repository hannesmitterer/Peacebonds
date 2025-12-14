# Community IPFS Node Setup Guide

## Join the Euystacio Framework Network

**Difficulty:** Beginner-Friendly  
**Time Required:** 30-60 minutes  
**Cost:** Free (except for hosting if using cloud)

---

## Why Run an IPFS Node?

By running an IPFS node and pinning the Euystacio Framework, you:

✓ **Support the Mission**: Help ensure permanent accessibility  
✓ **Strengthen the Network**: Add redundancy and resilience  
✓ **Earn Recognition**: Become a verified community contributor  
✓ **Gain Voting Rights**: Participate in framework governance  
✓ **Learn Web3**: Hands-on experience with decentralized technology

---

## Prerequisites

### Hardware Requirements

**Minimum**:
- CPU: 2 cores
- RAM: 2 GB
- Storage: 10 GB free space
- Network: Stable internet connection

**Recommended**:
- CPU: 4+ cores
- RAM: 4+ GB
- Storage: 50+ GB SSD
- Network: Unlimited bandwidth

### Software Requirements

- **Operating System**: Linux, macOS, or Windows
- **Terminal Access**: Command line interface
- **Internet Connection**: Static IP helpful but not required

---

## Installation Guide

### Option 1: Linux (Ubuntu/Debian)

#### Step 1: Download IPFS

```bash
# Download IPFS Kubo
wget https://dist.ipfs.tech/kubo/v0.24.0/kubo_v0.24.0_linux-amd64.tar.gz

# Extract
tar -xvzf kubo_v0.24.0_linux-amd64.tar.gz

# Install
cd kubo
sudo bash install.sh

# Verify installation
ipfs --version
```

#### Step 2: Initialize IPFS

```bash
# Initialize your node
ipfs init

# You'll see your Peer ID - save this!
# Example: QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG
```

#### Step 3: Configure for Public Gateway (Optional)

```bash
# Allow external access (if running on server)
ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080

# Increase connection limits
ipfs config --json Swarm.ConnMgr.HighWater 2000
ipfs config --json Swarm.ConnMgr.LowWater 500
```

#### Step 4: Start the Daemon

```bash
# Start IPFS daemon
ipfs daemon

# Or run as background service
nohup ipfs daemon > ipfs.log 2>&1 &
```

#### Step 5: Set Up as System Service

```bash
# Create systemd service
sudo nano /etc/systemd/system/ipfs.service
```

Add this content:

```ini
[Unit]
Description=IPFS Daemon
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
ExecStart=/usr/local/bin/ipfs daemon
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable ipfs
sudo systemctl start ipfs
sudo systemctl status ipfs
```

### Option 2: macOS

#### Using Homebrew

```bash
# Install IPFS
brew install ipfs

# Initialize
ipfs init

# Start daemon
ipfs daemon

# Or use brew services
brew services start ipfs
```

### Option 3: Windows

#### Using Windows Package

1. Download from: https://dist.ipfs.tech/kubo/v0.24.0/kubo_v0.24.0_windows-amd64.zip
2. Extract to `C:\Program Files\ipfs`
3. Add to PATH: System Properties → Environment Variables
4. Open PowerShell as Administrator:

```powershell
# Initialize
ipfs init

# Start daemon
ipfs daemon
```

#### Create Windows Service (Advanced)

Use [NSSM](https://nssm.cc/) to run IPFS as a service:

```powershell
# Download NSSM
# Run: nssm install ipfs

# Set:
# Path: C:\Program Files\ipfs\ipfs.exe
# Arguments: daemon
# Startup: Automatic

# Start service
nssm start ipfs
```

### Option 4: Docker

```bash
# Pull IPFS image
docker pull ipfs/kubo:latest

# Run container
docker run -d \
  --name ipfs-node \
  -v /path/to/ipfs-data:/data/ipfs \
  -p 4001:4001 \
  -p 4001:4001/udp \
  -p 5001:5001 \
  -p 8080:8080 \
  ipfs/kubo:latest

# Check status
docker logs ipfs-node
```

### Option 5: IPFS Desktop

Easiest option for beginners:

1. Download from: https://github.com/ipfs/ipfs-desktop/releases
2. Install and launch
3. IPFS Desktop provides GUI for all operations

---

## Pinning Euystacio Framework

### Get the Root CID

```bash
# The root CID will be published after deployment
# Check: https://github.com/hannesmitterer/Peacebonds/blob/main/docs/ipfs/CID_REGISTRY.md

ROOT_CID="[Will be available after IPFS deployment]"
```

### Pin the Content

```bash
# Pin by CID
ipfs pin add $ROOT_CID

# Verify it's pinned
ipfs pin ls --type=recursive | grep $ROOT_CID

# Check size
ipfs object stat $ROOT_CID
```

### Automatic Pinning on Startup

Create a script to auto-pin:

```bash
# Create pin script
cat > ~/pin-euystacio.sh << 'EOF'
#!/bin/bash
CIDS=(
  "QmRootCID1..."  # Update with actual CIDs
  "QmDocCID1..."
  "QmDocCID2..."
)

for CID in "${CIDS[@]}"; do
  echo "Pinning $CID..."
  ipfs pin add $CID
done

echo "All framework content pinned!"
EOF

chmod +x ~/pin-euystacio.sh

# Add to crontab for automatic execution
crontab -e
# Add: @reboot sleep 60 && /home/username/pin-euystacio.sh
```

---

## Verification

### Check Your Node Status

```bash
# Check IPFS is running
ipfs id

# Check peer connections
ipfs swarm peers | wc -l
# Should show 10+ peers

# Check pinned content
ipfs pin ls --type=recursive

# Check repo stats
ipfs repo stat
```

### Test Framework Access

```bash
# Try accessing Covenant
ipfs cat $ROOT_CID/docs/framework/COVENANT.md

# List framework directory
ipfs ls $ROOT_CID
```

### Verify Public Accessibility

If you're running a public gateway:

```bash
# Get your public IP
curl ifconfig.me

# Test access (replace with your IP)
curl http://YOUR_IP:8080/ipfs/$ROOT_CID
```

---

## Maintenance

### Update IPFS

```bash
# Check current version
ipfs version

# Download latest
wget https://dist.ipfs.tech/kubo/latest/kubo_latest_linux-amd64.tar.gz

# Stop daemon
sudo systemctl stop ipfs  # or: kill $(pgrep ipfs)

# Install update
tar -xvzf kubo_latest_linux-amd64.tar.gz
cd kubo
sudo bash install.sh

# Restart daemon
sudo systemctl start ipfs
```

### Monitor Performance

```bash
# Real-time stats
ipfs stats bw

# Repository size
ipfs repo stat

# Check logs (if using systemd)
sudo journalctl -u ipfs -f
```

### Garbage Collection

IPFS periodically removes unpinned data:

```bash
# Manual garbage collection
ipfs repo gc

# Configure automatic GC
ipfs config --json Datastore.GCPeriod '"1h"'
```

---

## Troubleshooting

### Daemon Won't Start

**Problem**: `ipfs daemon` fails

**Solutions**:
```bash
# Check if already running
pgrep ipfs

# Check port availability
netstat -tulpn | grep 5001

# Reset if corrupted
ipfs repo fsck
```

### Low Peer Count

**Problem**: Less than 10 peers

**Solutions**:
```bash
# Check firewall
sudo ufw allow 4001

# Bootstrap to default peers
ipfs bootstrap add --default

# Manual peer connection
ipfs swarm connect /ip4/104.131.131.82/tcp/4001/p2p/QmaCpDMGvV2...
```

### High Bandwidth Usage

**Problem**: Too much data transfer

**Solutions**:
```bash
# Set bandwidth limits
ipfs config --json Swarm.ConnMgr.GracePeriod '"60s"'
ipfs config --json Swarm.ConnMgr.HighWater 100
ipfs config --json Swarm.ConnMgr.LowWater 50
```

### Content Not Found

**Problem**: Can't retrieve pinned CID

**Solutions**:
```bash
# Re-pin
ipfs pin rm $CID
ipfs pin add $CID

# Find providers
ipfs dht findprovs $CID

# Bootstrap again
ipfs bootstrap add --default
```

---

## Advanced Configuration

### Expose Public Gateway

```bash
# Enable public gateway
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080

# Configure CORS (if needed)
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'

# Set up HTTPS (recommended)
# Use Caddy or Nginx as reverse proxy
```

### Custom Storage Location

```bash
# Set IPFS_PATH
export IPFS_PATH=/mnt/large-disk/ipfs-data
ipfs init

# Make permanent in ~/.bashrc
echo 'export IPFS_PATH=/mnt/large-disk/ipfs-data' >> ~/.bashrc
```

### Performance Tuning

```bash
# Increase cache size
ipfs config --json Datastore.BloomFilterSize 1048576

# Optimize for SSD
ipfs config --json Datastore.StorageMax '"100GB"'

# Connection tuning
ipfs config --json Swarm.ConnMgr.HighWater 2000
ipfs config --json Swarm.ConnMgr.LowWater 500
```

---

## Register Your Node

Once your node is running and pinning the framework:

### Step 1: Get Your Node Info

```bash
# Get Peer ID
ipfs id -f='<id>'

# Get public IP (if applicable)
curl ifconfig.me

# Get uptime stats
uptime
```

### Step 2: Submit to Registry

Visit: https://github.com/hannesmitterer/Peacebonds/issues

Create issue titled: "Register Community Node"

Include:
- Peer ID
- Location (city/country)
- Uptime commitment
- Public gateway URL (if any)

### Step 3: Verification

We'll verify your node is:
- Online and accessible
- Pinning framework content
- Properly configured

### Step 4: Recognition

Once verified, you'll be:
- Listed in community node registry
- Granted governance voting rights
- Eligible for future rewards
- Recognized as contributor

---

## Best Practices

1. **Keep Software Updated**: Update IPFS regularly
2. **Monitor Uptime**: Aim for >99% availability
3. **Secure Your Node**: Use firewall, restrict API access
4. **Backup Config**: Save IPFS config and keys
5. **Join Community**: Participate in discussions
6. **Report Issues**: Help improve the network

---

## Resources

### Official Documentation

- **IPFS Docs**: https://docs.ipfs.tech
- **IPFS Forum**: https://discuss.ipfs.tech
- **GitHub**: https://github.com/ipfs/kubo

### Community

- **Euystacio Forum**: https://forum.euystacio.org (future)
- **Discord**: [To be announced]
- **Telegram**: [To be announced]

### Support

- **Technical Help**: community@euystacio.org (future)
- **GitHub Issues**: https://github.com/hannesmitterer/Peacebonds/issues

---

## Thank You!

By running an IPFS node for the Euystacio Framework, you're directly contributing to:

- **Permanent preservation** of ethical AI principles
- **Censorship resistance** of critical documentation
- **Global accessibility** for all humanity
- **Decentralized governance** of the future

Together, we're building infrastructure for permanent peace and shared prosperity.

**"Never slavery, only love first."**

---

**Guide Version**: 1.0  
**Last Updated**: December 14, 2025  
**Next Update**: As needed
