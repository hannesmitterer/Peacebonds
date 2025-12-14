# Deployment Instructions

## Euystacio Framework - Quick Deployment Guide

This document provides step-by-step instructions for deploying the Euystacio Framework to IPFS and Ethereum blockchain.

---

## Prerequisites

### Required Software

- **IPFS Kubo** v0.24.0 or later
- **Node.js** v16 or later
- **npm** or **yarn**
- **Git**

### Required Credentials

- **Pinata API Key** (recommended) - Get from https://pinata.cloud
- **Web3.Storage Token** (recommended) - Get from https://web3.storage
- **Ethereum Private Key** (for Sepolia testnet) - Create wallet with test ETH
- **Etherscan API Key** (optional, for verification) - Get from https://etherscan.io

---

## Step 1: Install IPFS

### Linux/macOS

```bash
wget https://dist.ipfs.tech/kubo/v0.24.0/kubo_v0.24.0_linux-amd64.tar.gz
tar -xvzf kubo_v0.24.0_linux-amd64.tar.gz
cd kubo
sudo bash install.sh
ipfs --version
```

### Initialize IPFS

```bash
ipfs init
ipfs daemon &  # Start in background
```

---

## Step 2: Configure Pinning Services (Optional but Recommended)

### Get Pinata Credentials

1. Visit https://app.pinata.cloud
2. Sign up for free account
3. Go to API Keys → Generate New Key
4. Save API Key and Secret Key

### Get Web3.Storage Token

1. Visit https://web3.storage
2. Sign up for free account
3. Go to Account → Create API Token
4. Save token

---

## Step 3: Deploy to IPFS

```bash
cd /path/to/Peacebonds

# Deploy framework to IPFS
./scripts/deploy-to-ipfs.sh

# This will:
# - Prepare content for IPFS
# - Calculate individual file CIDs
# - Add complete framework to IPFS
# - Generate CID registry
# - Pin content locally
```

**Output**: Root CID will be saved to `.ipfs-root-cid`

---

## Step 4: Pin to Multiple Services

```bash
# Set environment variables
export PINATA_API_KEY="your_pinata_api_key"
export PINATA_SECRET_KEY="your_pinata_secret_key"
export WEB3_STORAGE_TOKEN="your_web3_storage_token"

# Pin to services
./scripts/pin-to-services.sh

# This will:
# - Pin to Pinata
# - Pin to Web3.Storage
# - Verify redundancy
```

**Target**: At least 2 pinning services active for redundancy

---

## Step 5: Verify Gateway Accessibility

```bash
# Check public gateway accessibility
./scripts/check-gateways.sh

# This will:
# - Test 8+ public IPFS gateways
# - Measure response times
# - Generate gateway list
# - Report accessibility status
```

**Wait**: Allow 1-2 minutes for content propagation to gateways

---

## Step 6: Configure Ethereum Wallet

### Get Sepolia Test ETH

1. Visit https://sepoliafaucet.com or https://faucet.sepolia.dev
2. Enter your wallet address
3. Receive free test ETH (0.5 ETH should be sufficient)

### Create .env File

```bash
cat > .env << EOF
# Ethereum RPC URLs
SEPOLIA_RPC_URL=https://rpc.sepolia.org
MAINNET_RPC_URL=https://eth.llamarpc.com

# Private key (DO NOT SHARE, DO NOT COMMIT)
PRIVATE_KEY=0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

# Etherscan API key (optional, for verification)
ETHERSCAN_API_KEY=your_etherscan_api_key
EOF

# Verify .env is in .gitignore
grep -q ".env" .gitignore && echo "✓ .env is gitignored" || echo "⚠ Add .env to .gitignore"
```

**SECURITY WARNING**: Never commit `.env` file or share private key

---

## Step 7: Deploy Smart Contract

```bash
# Deploy to Sepolia testnet
./scripts/deploy-blockchain-anchor.sh sepolia

# This will:
# - Install dependencies (Hardhat, etc.)
# - Compile IPFSAnchor.sol
# - Deploy to Sepolia
# - Anchor IPFS root CID
# - Save deployment info
```

**Output**: Contract address will be saved to `.deployment-info.json`

---

## Step 8: Verify Contract (Optional)

```bash
# Get contract address from deployment info
CONTRACT_ADDRESS=$(cat .deployment-info.json | grep -oP '"address": "\K[^"]+')
ROOT_CID=$(cat .ipfs-root-cid)

# Verify on Etherscan
npx hardhat verify --network sepolia $CONTRACT_ADDRESS "$ROOT_CID" "Initial deployment of Euystacio Framework v1.2"
```

---

## Step 9: Update Documentation

### Update CID_REGISTRY.md

The file `docs/ipfs/CID_REGISTRY.md` is auto-generated. Commit it:

```bash
git add docs/ipfs/CID_REGISTRY.md
git commit -m "Update CID registry with deployment info"
```

### Update README.md

Replace placeholders in README.md:

```bash
# Replace [To be published] with actual CID
sed -i "s/\[To be published after deployment\]/$ROOT_CID/g" README.md

# Replace [To be deployed] with contract address
sed -i "s/\[To be deployed\]/$CONTRACT_ADDRESS/g" README.md

git add README.md
git commit -m "Update README with deployment information"
git push
```

---

## Step 10: Announce to Community

### Prepare Announcements

1. **Twitter**: Use template in `docs/announcements/TWITTER.md`
   - Replace `[CID]` with actual root CID
   - Replace `[ADDRESS]` with contract address
   - Post thread

2. **Reddit**: Use templates in `docs/announcements/REDDIT.md`
   - Post to r/ethereum, r/ipfs, r/CryptoCurrency
   - Include actual links and CIDs

3. **Discord** (if you have a server): Use `docs/announcements/DISCORD.md`
   - Update templates with real values
   - Post announcements

---

## Verification Checklist

Before announcing publicly, verify:

- [ ] IPFS root CID is accessible via at least 3 gateways
- [ ] Content is pinned to at least 2 services (Pinata, Web3.Storage)
- [ ] Smart contract is deployed and verified on Sepolia Etherscan
- [ ] Contract stores correct root CID
- [ ] All documentation links work
- [ ] .env file is NOT committed to git
- [ ] CID_REGISTRY.md is generated and committed

---

## Monitoring

### Check IPFS Status

```bash
# Local node status
ipfs id

# Check pinned content
ipfs pin ls --type=recursive | grep $(cat .ipfs-root-cid)

# Repository stats
ipfs repo stat
```

### Check Blockchain Status

```bash
# Using cast (Foundry)
cast call $CONTRACT_ADDRESS "getLatestCID()(string)" --rpc-url https://rpc.sepolia.org

# Or visit Etherscan
# https://sepolia.etherscan.io/address/[CONTRACT_ADDRESS]
```

---

## Troubleshooting

### IPFS Issues

**Problem**: IPFS daemon won't start
```bash
# Check if already running
pgrep ipfs
# Kill if needed
pkill ipfs
# Restart
ipfs daemon
```

**Problem**: Content not accessible via gateways
```bash
# Wait 5-10 minutes for propagation
# Re-pin if needed
ipfs pin add $(cat .ipfs-root-cid)
# Try different gateways
```

### Blockchain Issues

**Problem**: Transaction fails
```bash
# Check you have enough Sepolia ETH
# Check gas prices aren't too low
# Verify private key is correct format
```

**Problem**: Contract verification fails
```bash
# Ensure constructor arguments match deployment
# Check Etherscan API key is valid
# Try verifying via Etherscan UI
```

---

## Support

- **GitHub Issues**: https://github.com/hannesmitterer/Peacebonds/issues
- **Documentation**: All guides in `docs/` directory
- **Community** (future): Discord, Forum, etc.

---

## Next Steps After Deployment

1. **Monitor**: Track gateway accessibility and contract events
2. **Engage**: Respond to community questions
3. **Improve**: Gather feedback and iterate
4. **Scale**: Plan for mainnet migration (Q3 2026)
5. **Grow**: Recruit node operators and contributors

---

**Congratulations!**

You've successfully deployed the Euystacio Framework to permanent, decentralized infrastructure!

**"Never slavery, only love first."**

---

**Document Version**: 1.0  
**Last Updated**: December 14, 2025  
**For**: Euystacio Framework v1.2
