# IPFS Distribution Guide

## Euystacio Framework - Permanent Decentralized Storage

**Version:** 1.0  
**Last Updated:** December 14, 2025  
**Status:** Active

---

## Overview

This guide explains how the Euystacio Framework is distributed via IPFS (InterPlanetary File System), ensuring permanent, censorship-resistant, and globally accessible documentation.

---

## What is IPFS?

IPFS is a peer-to-peer hypermedia protocol designed to make the web faster, safer, and more open. Unlike traditional HTTP, IPFS:

- **Content-Addressed**: Files are identified by cryptographic hashes (CIDs)
- **Decentralized**: No single point of failure
- **Permanent**: Content remains available as long as any node hosts it
- **Verifiable**: Cryptographic integrity guarantees

### Why IPFS for Euystacio?

1. **Censorship Resistance**: No government or corporation can remove our content
2. **Permanence**: Once pinned, content exists indefinitely
3. **Integrity**: CIDs prove content hasn't been tampered with
4. **Accessibility**: Available worldwide through public gateways
5. **Decentralization**: Aligns with our core principles

---

## Framework Content on IPFS

### Documents Distributed

All Euystacio Framework documentation is available on IPFS:

1. **The Covenant** (Law of Equals)
2. **Technical Architecture**
3. **Governance Model**
4. **Implementation Roadmap**
5. **IPFS Distribution Guide** (this document)
6. **Community Guides**
7. **Source Code** (via GitHub → IPFS mirror)
8. **Social Media Announcements**
9. **Verification Scripts**
10. **Smart Contracts**

### Directory Structure

```
euystacio-framework/
├── README.md
├── docs/
│   ├── framework/
│   │   ├── COVENANT.md
│   │   ├── ARCHITECTURE.md
│   │   ├── GOVERNANCE.md
│   │   └── ROADMAP.md
│   ├── ipfs/
│   │   ├── DISTRIBUTION.md (this file)
│   │   ├── CID_REGISTRY.md
│   │   └── GATEWAY_LIST.md
│   ├── blockchain/
│   │   ├── anchor-contract.sol
│   │   ├── deployment-guide.md
│   │   └── verification-script.js
│   ├── community/
│   │   ├── node-setup-guide.md
│   │   ├── pinning-guide.md
│   │   └── verification-guide.md
│   └── announcements/
│       ├── twitter.md
│       ├── reddit.md
│       └── discord.md
├── scripts/
│   ├── deploy-to-ipfs.sh
│   ├── verify-ipfs.sh
│   ├── pin-to-services.sh
│   └── check-gateways.sh
└── contracts/
    ├── IPFSAnchor.sol
    └── migrations/
```

---

## Accessing Framework Content

### Method 1: Public IPFS Gateways

Anyone can access our content through HTTP gateways:

**Primary Gateways**:
```
https://ipfs.io/ipfs/<CID>
https://cloudflare-ipfs.com/ipfs/<CID>
https://dweb.link/ipfs/<CID>
https://gateway.pinata.cloud/ipfs/<CID>
https://w3s.link/ipfs/<CID>
```

**Example**:
```bash
# Replace <CID> with actual Content Identifier
https://ipfs.io/ipfs/QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG
```

### Method 2: Local IPFS Node

For best performance and to support the network:

```bash
# Install IPFS
wget https://dist.ipfs.tech/kubo/v0.24.0/kubo_v0.24.0_linux-amd64.tar.gz
tar -xvzf kubo_v0.24.0_linux-amd64.tar.gz
cd kubo
sudo bash install.sh

# Initialize and start
ipfs init
ipfs daemon

# Access content
ipfs cat <CID> > framework.tar.gz
ipfs get <CID> --output=euystacio-framework/
```

### Method 3: IPFS Desktop

User-friendly GUI application:

1. Download from: https://github.com/ipfs/ipfs-desktop/releases
2. Install and launch
3. Enter CID in search
4. View or download content

### Method 4: Browser Extensions

- **IPFS Companion**: https://github.com/ipfs/ipfs-companion
- **Brave Browser**: Built-in IPFS support

---

## Content Identifiers (CIDs)

### Root CID

The entire framework is accessible via a single root CID:

```
Root CID: [To be generated after deployment]
Version: 1
Format: CIDv1
Hash: SHA-256
Codec: dag-pb
```

### Individual Document CIDs

For direct access to specific documents:

| Document | CID | Size |
|----------|-----|------|
| COVENANT.md | TBD | ~8 KB |
| ARCHITECTURE.md | TBD | ~13 KB |
| GOVERNANCE.md | TBD | ~14 KB |
| ROADMAP.md | TBD | ~16 KB |
| Complete Archive | TBD | ~500 KB |

*Note: CIDs will be generated during deployment and recorded in CID_REGISTRY.md*

---

## Pinning Services

To ensure permanent availability, we use multiple pinning services:

### 1. Pinata

**Provider**: https://pinata.cloud  
**Redundancy**: 6 global locations  
**Status**: Active  

**API Configuration**:
```bash
export PINATA_API_KEY="your_api_key"
export PINATA_SECRET_KEY="your_secret_key"

# Pin content
curl -X POST "https://api.pinata.cloud/pinning/pinByHash" \
  -H "pinata_api_key: $PINATA_API_KEY" \
  -H "pinata_secret_api_key: $PINATA_SECRET_KEY" \
  -H "Content-Type: application/json" \
  -d '{"hashToPin":"<CID>","pinataMetadata":{"name":"Euystacio Framework"}}'
```

### 2. Web3.Storage

**Provider**: https://web3.storage  
**Redundancy**: Filecoin integration  
**Status**: Active  

**API Configuration**:
```bash
export WEB3_STORAGE_TOKEN="your_token"

# Pin via CLI
npm install -g @web3-storage/w3cli
w3 put euystacio-framework/
```

### 3. NFT.Storage

**Provider**: https://nft.storage  
**Redundancy**: Filecoin + IPFS  
**Status**: Backup  

### 4. Temporal.cloud

**Provider**: https://temporal.cloud  
**Redundancy**: Enterprise IPFS  
**Status**: Planned  

### 5. Community Nodes

**Provider**: Decentralized community  
**Count**: Target 100+ nodes  
**Status**: Growing  

---

## Verification Protocol

### Step 1: Retrieve CID

From blockchain anchor (see blockchain documentation):

```javascript
// Ethereum contract call
const rootCID = await anchorContract.getLatestCID();
console.log("Root CID:", rootCID);
```

### Step 2: Download Content

```bash
# Via gateway
curl https://ipfs.io/ipfs/$CID -o framework.tar.gz

# Or via local node
ipfs get $CID
```

### Step 3: Verify Hash

```bash
# Calculate hash of downloaded content
ipfs add framework.tar.gz --only-hash

# Compare with blockchain CID
# They should match exactly
```

### Step 4: Verify Signatures

```bash
# Check GPG signature (if provided)
gpg --verify framework.tar.gz.sig framework.tar.gz

# Verify against known public keys
```

### Automated Verification Script

```bash
#!/bin/bash
# verify-framework.sh

BLOCKCHAIN_CID=$(curl -s https://api.euystacio.org/v1/latest-cid)
DOWNLOADED_CID=$(ipfs add framework/ --only-hash --recursive | tail -1 | awk '{print $2}')

if [ "$BLOCKCHAIN_CID" == "$DOWNLOADED_CID" ]; then
    echo "✓ Verification successful"
    echo "✓ Content is authentic and unmodified"
    exit 0
else
    echo "✗ Verification failed"
    echo "✗ CID mismatch detected"
    exit 1
fi
```

---

## Gateway Health Monitoring

### Automated Gateway Checks

We continuously monitor gateway availability:

```bash
#!/bin/bash
# check-gateways.sh

CID="QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG"

GATEWAYS=(
    "https://ipfs.io/ipfs/"
    "https://cloudflare-ipfs.com/ipfs/"
    "https://dweb.link/ipfs/"
    "https://gateway.pinata.cloud/ipfs/"
)

for gateway in "${GATEWAYS[@]}"; do
    response=$(curl -s -o /dev/null -w "%{http_code}" "${gateway}${CID}")
    if [ $response -eq 200 ]; then
        echo "✓ $gateway - OK"
    else
        echo "✗ $gateway - FAILED ($response)"
    fi
done
```

### Gateway Performance Metrics

Updated daily at: https://euystacio.org/gateway-status (future)

Metrics tracked:
- Response time (ms)
- Availability (%)
- Geographic location
- Bandwidth capacity
- IPFS version

---

## Community Participation

### How to Help

1. **Run an IPFS Node**
   - Download and install IPFS
   - Pin framework content
   - Keep node online 24/7

2. **Pin to Your Account**
   - Create free Pinata/Web3.Storage account
   - Pin our root CID
   - Ensure redundancy

3. **Share Gateway Links**
   - Post on social media
   - Include in documentation
   - Educate others

4. **Report Issues**
   - Gateway downtime
   - Content unavailability
   - Verification failures

### Community Node Registry

Register your node at: https://euystacio.org/node-registry (future)

**Benefits**:
- Public recognition
- Voting power in governance
- Priority support
- Future token rewards (if approved)

---

## Updating Content

### Immutability vs. Updates

IPFS content is **immutable** - each version has a unique CID. Updates create new CIDs.

### Update Process

1. **Make Changes**: Edit documentation
2. **Generate New CID**: `ipfs add --recursive framework/`
3. **Update Blockchain**: Store new CID in anchor contract
4. **Notify Community**: Announce via social channels
5. **Maintain History**: Keep old CIDs accessible

### Version Control

```
Version 1.0 → CID: Qm...ABC
Version 1.1 → CID: Qm...DEF
Version 2.0 → CID: Qm...GHI
```

All versions remain permanently accessible.

### IPNS (Mutable Pointers)

For convenience, we publish IPNS names that point to latest version:

```bash
# Resolve latest version
ipfs name resolve /ipns/euystacio.eth
# Returns: /ipfs/Qm...latest
```

---

## Performance Optimization

### Best Practices

1. **Use Local Nodes**
   - Fastest access
   - Supports network
   - Full control

2. **Choose Nearest Gateway**
   - Cloudflare for global CDN
   - Regional gateways for specific areas
   - Private gateways for enterprise

3. **Cache Aggressively**
   - Content is immutable
   - Safe to cache indefinitely
   - Reduces load on network

4. **Pin Frequently Accessed Content**
   - Keeps it readily available
   - Improves network performance
   - Supports content creators

### CDN Integration

For maximum performance, we integrate with:

- **Cloudflare**: Global CDN with IPFS gateway
- **Fleek**: Automated IPFS deployment
- **Pinata Dedicated Gateway**: Custom domain support

---

## Security Considerations

### Threats

1. **Gateway Compromise**: Malicious gateway serves fake content
2. **CID Spoofing**: Attacker claims false CID
3. **Pinning Service Failure**: Content becomes unavailable
4. **Network Partition**: IPFS network splits

### Mitigations

1. **Always Verify CIDs**: Check against blockchain anchor
2. **Use Multiple Gateways**: Cross-reference content
3. **Multiple Pinning Services**: Redundancy prevents loss
4. **Community Distribution**: Decentralized hosting
5. **Cryptographic Signatures**: GPG-signed releases

### Trust Model

```
Blockchain (Highest Trust)
    ↓
Multiple Pinning Services (High Trust)
    ↓
Community Nodes (Medium Trust)
    ↓
Public Gateways (Low Trust - Always Verify)
```

---

## Troubleshooting

### Content Not Loading

**Problem**: Gateway returns 404 or timeout

**Solutions**:
1. Try different gateway
2. Wait for content propagation (up to 10 minutes)
3. Request from local node: `ipfs get <CID>`
4. Check gateway status page
5. Report to community

### CID Mismatch

**Problem**: Downloaded content has different CID

**Solutions**:
1. Re-download from different source
2. Verify blockchain CID is correct
3. Check for network issues
4. Report potential attack

### Slow Download

**Problem**: Content loads very slowly

**Solutions**:
1. Switch to nearest gateway
2. Use local IPFS node
3. Enable DHT for better routing
4. Increase bandwidth allocation

---

## API Integration

### Programmatic Access

```javascript
// JavaScript example using ipfs-http-client
const { create } = require('ipfs-http-client');
const ipfs = create({ url: 'https://ipfs.io' });

async function getFramework(cid) {
    const chunks = [];
    for await (const chunk of ipfs.cat(cid)) {
        chunks.push(chunk);
    }
    return Buffer.concat(chunks).toString();
}

// Usage
const covenant = await getFramework('Qm...covenant-cid');
console.log(covenant);
```

```python
# Python example using ipfshttpclient
import ipfshttpclient

client = ipfshttpclient.connect('/ip4/127.0.0.1/tcp/5001')
content = client.cat('Qm...framework-cid')
print(content.decode('utf-8'))
```

---

## Monitoring & Analytics

### Metrics We Track

1. **Access Statistics**
   - Downloads per day
   - Geographic distribution
   - Gateway usage
   - Peak times

2. **Network Health**
   - Active nodes
   - Pinning coverage
   - Replication factor
   - Average availability

3. **Performance**
   - Time to first byte
   - Download completion rate
   - Gateway response times
   - Error rates

**Dashboard**: https://euystacio.org/ipfs-stats (future)

---

## Future Enhancements

### Planned Improvements

1. **Filecoin Integration**
   - Long-term storage deals
   - Cryptographic proof of storage
   - Economic incentives

2. **ENS Integration**
   - Human-readable names
   - euystacio.eth → IPFS content
   - Automatic resolution

3. **Custom Gateway**
   - docs.euystacio.org
   - Faster performance
   - Custom branding

4. **Mobile Optimization**
   - Compressed versions
   - Progressive loading
   - Offline support

---

## Resources

### Official Links

- **IPFS Documentation**: https://docs.ipfs.tech
- **IPFS Desktop**: https://github.com/ipfs/ipfs-desktop
- **IPFS Companion**: https://github.com/ipfs/ipfs-companion
- **Pinata**: https://pinata.cloud
- **Web3.Storage**: https://web3.storage

### Community

- **IPFS Forum**: https://discuss.ipfs.tech
- **Discord**: https://discord.gg/ipfs
- **Reddit**: r/ipfs

### Support

- **Technical Issues**: ipfs@euystacio.org (future)
- **Community Forum**: https://forum.euystacio.org (future)
- **GitHub Issues**: https://github.com/hannesmitterer/Peacebonds/issues

---

## Conclusion

IPFS distribution ensures the Euystacio Framework remains permanently accessible, verifiable, and censorship-resistant. By combining IPFS with blockchain anchoring, we create an immutable record of our commitment to love, freedom, and shared prosperity.

**Join us in building the permanent web.**

---

**Root CID**: [To be generated]  
**Blockchain Anchor**: [To be deployed]  
**Version**: 1.0  
**Last Updated**: December 14, 2025  
**Next Update**: As needed (new CID will be generated)
