# IPFS Distribution and Blockchain Anchoring

## Overview

This document outlines the strategy for distributing the Euystacio Framework documentation via IPFS and anchoring it on the Ethereum blockchain for immutability and verifiability.

---

## IPFS Distribution

### What is IPFS?

The InterPlanetary File System (IPFS) is a peer-to-peer hypermedia protocol designed to make the web faster, safer, and more open. Content is addressed by its cryptographic hash (Content Identifier or CID) rather than location, ensuring:

- **Permanence**: Content cannot be altered without changing its CID
- **Availability**: Content remains accessible as long as nodes pin it
- **Verifiability**: Anyone can verify content integrity using the CID
- **Decentralization**: No single point of failure or control

### Content Distribution Strategy

#### Primary Documents

The following documents are distributed via IPFS:

1. **Executive Master Document** (`EUYSTACIO_FRAMEWORK_MASTER.md`)
2. **Governance Framework** (`governance/README.md`)
3. **System Architecture** (`architecture/README.md`)
4. **Implementation Roadmap** (`roadmap/README.md`)
5. **Distribution Documentation** (`distribution/README.md`)
6. **Community Announcements** (`community/README.md`)

#### Directory Structure

```
/docs
├── EUYSTACIO_FRAMEWORK_MASTER.md
├── governance/
│   └── README.md
├── architecture/
│   └── README.md
├── roadmap/
│   └── README.md
├── distribution/
│   └── README.md
└── community/
    └── README.md
```

### IPFS Deployment Process

#### Step 1: Content Preparation

```bash
# Navigate to your repository root
cd /path/to/Peacebonds

# Navigate to docs directory
cd docs

# Verify content integrity
find . -type f -name "*.md" -exec sha256sum {} \;

# Create manifest file
cat > manifest.json <<EOF
{
  "name": "Euystacio Framework Documentation",
  "version": "1.0.0",
  "date": "2025-12-14",
  "documents": [
    "EUYSTACIO_FRAMEWORK_MASTER.md",
    "governance/README.md",
    "architecture/README.md",
    "roadmap/README.md",
    "distribution/README.md",
    "community/README.md"
  ]
}
EOF
```

#### Step 2: IPFS Upload

```bash
# Install IPFS (if not already installed)
# wget https://dist.ipfs.tech/kubo/v0.24.0/kubo_v0.24.0_linux-amd64.tar.gz
# tar -xvzf kubo_v0.24.0_linux-amd64.tar.gz
# cd kubo
# sudo bash install.sh

# Initialize IPFS node
ipfs init

# Start IPFS daemon (in background)
ipfs daemon &

# Add entire docs directory
ipfs add -r docs/

# Capture the CID of the docs directory
# Example output: QmXxx.../docs
DOCS_CID="<CID_from_previous_command>"

# Add individual master document
ipfs add docs/EUYSTACIO_FRAMEWORK_MASTER.md

# Capture master document CID
MASTER_CID="<CID_from_previous_command>"
```

#### Step 3: Pinning Services

To ensure redundancy and availability, the content is pinned on multiple IPFS pinning services:

##### Pinata

```bash
# Using Pinata API
curl -X POST "https://api.pinata.cloud/pinning/pinByHash" \
  -H "Content-Type: application/json" \
  -H "pinata_api_key: YOUR_API_KEY" \
  -H "pinata_secret_api_key: YOUR_SECRET_KEY" \
  -d '{
    "hashToPin": "'$DOCS_CID'",
    "pinataMetadata": {
      "name": "Euystacio Framework Documentation v1.0.0",
      "keyvalues": {
        "version": "1.0.0",
        "type": "genesis-document",
        "date": "2025-12-14"
      }
    }
  }'
```

##### Web3.Storage

```bash
# Using web3.storage CLI
npm install -g @web3-storage/w3cli

# Authenticate
w3 login your-email@example.com

# Upload directory
w3 put docs/ --name "Euystacio Framework v1.0.0"
```

##### IPFS Cluster

```bash
# Add to private IPFS cluster
ipfs-cluster-ctl pin add $DOCS_CID \
  --name "Euystacio Framework Documentation" \
  --replication-factor-min 3 \
  --replication-factor-max 7
```

### Current Status

| Component | CID | Status | Pinning Services |
|-----------|-----|--------|------------------|
| Full docs directory | `[To be generated]` | Pending | Pinata, Web3.Storage, Private Cluster |
| Master Document | `[To be generated]` | Pending | Pinata, Web3.Storage, Private Cluster |
| Governance | `[To be generated]` | Pending | Pinata, Web3.Storage |
| Architecture | `[To be generated]` | Pending | Pinata, Web3.Storage |
| Roadmap | `[To be generated]` | Pending | Pinata, Web3.Storage |
| Distribution | `[To be generated]` | Pending | Pinata, Web3.Storage |
| Community | `[To be generated]` | Pending | Pinata, Web3.Storage |

### Accessing Content via IPFS

Once deployed, content can be accessed through:

**IPFS Gateways**:
- `https://ipfs.io/ipfs/<CID>`
- `https://gateway.pinata.cloud/ipfs/<CID>`
- `https://dweb.link/ipfs/<CID>`
- `https://<CID>.ipfs.w3s.link`

**Local IPFS Node**:
```bash
ipfs cat <CID>
```

**IPFS Desktop/Browser Extension**:
- `ipfs://<CID>` (with IPFS Companion browser extension)

---

## Blockchain Anchoring

### Purpose

Anchoring the document hash on the blockchain provides:
- **Immutability**: Proof that content existed at a specific time
- **Verifiability**: Anyone can verify content hasn't been altered
- **Timestamping**: Cryptographic proof of publication date
- **Trust**: Decentralized, censorship-resistant record

### Ethereum Sepolia Testnet

We use Ethereum Sepolia testnet for the initial anchoring:

**Why Sepolia?**
- Stable, long-term testnet maintained by Ethereum Foundation
- Free test ETH available from faucets
- Compatible with mainnet tooling
- Suitable for proof-of-concept and development

**Future Mainnet Deployment**: Critical documents will be anchored on Ethereum mainnet for maximum security and permanence.

### Anchoring Process

#### Step 1: Calculate Document Hash

```bash
# Calculate SHA-256 hash of master document
sha256sum docs/EUYSTACIO_FRAMEWORK_MASTER.md

# Example output:
# a1b2c3d4... docs/EUYSTACIO_FRAMEWORK_MASTER.md
MASTER_HASH="0xa1b2c3d4..."

# Calculate hash of entire docs directory (using CID)
# The IPFS CID itself is a hash, but we create a composite hash
cat > hash-input.txt <<EOF
IPFS_CID: $DOCS_CID
MASTER_CID: $MASTER_CID
VERSION: 1.0.0
DATE: 2025-12-14T00:00:00Z
EOF

COMPOSITE_HASH=$(sha256sum hash-input.txt | awk '{print $1}')
echo "Composite Hash: 0x$COMPOSITE_HASH"
```

#### Step 2: Deploy Anchoring Smart Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EuystacioDocumentAnchor
 * @notice Anchors Euystacio Framework documentation hashes on-chain
 * @dev Provides immutable proof of existence and integrity
 */
contract EuystacioDocumentAnchor {
    struct DocumentRecord {
        bytes32 contentHash;
        string ipfsCid;
        string version;
        uint256 timestamp;
        address publisher;
        string metadata;
    }
    
    mapping(bytes32 => DocumentRecord) public documents;
    bytes32[] public documentHashes;
    
    event DocumentAnchored(
        bytes32 indexed contentHash,
        string ipfsCid,
        string version,
        uint256 timestamp,
        address indexed publisher
    );
    
    /**
     * @notice Anchor a document hash on the blockchain
     * @param _contentHash SHA-256 hash of document content
     * @param _ipfsCid IPFS Content Identifier
     * @param _version Document version
     * @param _metadata Additional metadata (JSON string)
     */
    function anchorDocument(
        bytes32 _contentHash,
        string memory _ipfsCid,
        string memory _version,
        string memory _metadata
    ) public {
        require(
            documents[_contentHash].timestamp == 0,
            "Document already anchored"
        );
        
        documents[_contentHash] = DocumentRecord({
            contentHash: _contentHash,
            ipfsCid: _ipfsCid,
            version: _version,
            timestamp: block.timestamp,
            publisher: msg.sender,
            metadata: _metadata
        });
        
        documentHashes.push(_contentHash);
        
        emit DocumentAnchored(
            _contentHash,
            _ipfsCid,
            _version,
            block.timestamp,
            msg.sender
        );
    }
    
    /**
     * @notice Verify a document exists and retrieve its record
     * @param _contentHash SHA-256 hash to verify
     * @return Record of the anchored document
     */
    function verifyDocument(bytes32 _contentHash)
        public
        view
        returns (DocumentRecord memory)
    {
        require(
            documents[_contentHash].timestamp != 0,
            "Document not found"
        );
        return documents[_contentHash];
    }
    
    /**
     * @notice Get total number of anchored documents
     */
    function getDocumentCount() public view returns (uint256) {
        return documentHashes.length;
    }
}
```

#### Step 3: Deploy Contract to Sepolia

```bash
# Using Hardhat
npx hardhat run scripts/deploy-anchor.js --network sepolia

# Or using Foundry
forge create --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  src/EuystacioDocumentAnchor.sol:EuystacioDocumentAnchor

# Capture contract address
CONTRACT_ADDRESS="0x..."
```

#### Step 4: Anchor Document Hash

```javascript
// Using ethers.js
const { ethers } = require("ethers");

const provider = new ethers.JsonRpcProvider(SEPOLIA_RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

const contract = new ethers.Contract(
  CONTRACT_ADDRESS,
  contractABI,
  wallet
);

const tx = await contract.anchorDocument(
  COMPOSITE_HASH,
  DOCS_CID,
  "1.0.0",
  JSON.stringify({
    name: "Euystacio Framework Documentation",
    date: "2025-12-14",
    masterCid: MASTER_CID,
    components: [
      "governance", "architecture", "roadmap", 
      "distribution", "community"
    ]
  })
);

await tx.wait();
console.log("Transaction hash:", tx.hash);
```

### Current Status

| Item | Value | Status |
|------|-------|--------|
| Network | Ethereum Sepolia | Ready |
| Contract Address | `[To be deployed]` | Pending deployment |
| Transaction Hash | `[To be generated]` | Pending deployment |
| Block Number | `[To be recorded]` | Pending deployment |
| Timestamp | `[To be recorded]` | Pending deployment |
| Gas Used | `[To be recorded]` | Pending deployment |

---

## Verification Process

### For Users

Anyone can verify the authenticity and integrity of the documentation:

#### Step 1: Download from IPFS

```bash
# Using IPFS CLI
ipfs get <DOCS_CID>

# Or via HTTP gateway
wget https://ipfs.io/ipfs/<DOCS_CID>/EUYSTACIO_FRAMEWORK_MASTER.md
```

#### Step 2: Calculate Hash

```bash
# Calculate SHA-256 hash
sha256sum EUYSTACIO_FRAMEWORK_MASTER.md

# Should match the hash in the blockchain record
```

#### Step 3: Verify on Blockchain

```bash
# Using ethers.js
const record = await contract.verifyDocument(DOCUMENT_HASH);
console.log("IPFS CID:", record.ipfsCid);
console.log("Version:", record.version);
console.log("Timestamp:", new Date(record.timestamp * 1000));
console.log("Publisher:", record.publisher);
```

#### Step 4: Compare Results

- Document hash matches blockchain record ✓
- IPFS CID matches blockchain record ✓
- Timestamp is reasonable and within expected range ✓
- Content is intact and readable ✓

### Automated Verification

We provide a verification script:

```javascript
// verify-document.js
async function verifyEuystacioDocument(cid) {
  // 1. Fetch from IPFS
  const content = await fetchFromIPFS(cid);
  
  // 2. Calculate hash
  const hash = sha256(content);
  
  // 3. Query blockchain
  const record = await contract.verifyDocument(hash);
  
  // 4. Verify
  if (record.ipfsCid === cid && record.contentHash === hash) {
    console.log("✓ Document verified successfully");
    console.log("✓ Published:", new Date(record.timestamp * 1000));
    console.log("✓ Version:", record.version);
    return true;
  } else {
    console.log("✗ Verification failed");
    return false;
  }
}
```

---

## Redundancy and Availability

### Multi-Service Pinning

| Service | Type | Redundancy | SLA |
|---------|------|------------|-----|
| Pinata | Commercial | High (multi-region) | 99.9% |
| Web3.Storage | Commercial | High (Filecoin-backed) | 99.5% |
| Private Cluster | Self-hosted | Medium (3-7 nodes) | 99% |
| Public IPFS | Community | Variable | Best effort |

### Monitoring

Automated checks every 6 hours:
- Availability from each gateway
- Response time metrics
- Content integrity verification
- Pin status on each service

Alerts triggered if:
- Any gateway unreachable for 24+ hours
- Content hash mismatch detected
- Pin removed from any service
- Response time > 5 seconds (95th percentile)

---

## Future Enhancements

### Planned Improvements

1. **Arweave Permanent Storage**
   - Upload to Arweave for truly permanent storage
   - One-time payment for perpetual hosting
   - Target: Phase 2

2. **Mainnet Anchoring**
   - Deploy to Ethereum mainnet for critical documents
   - Higher security and permanence
   - Target: Phase 2 completion

3. **IPNS for Updates**
   - Use IPNS for mutable pointers to latest versions
   - Maintain version history on IPFS
   - Target: Phase 1 completion

4. **Decentralized Mirrors**
   - Community-run IPFS nodes
   - Geographic distribution
   - Incentivization for pinning
   - Target: Phase 3

5. **ENS Integration**
   - Register euystacio.eth domain
   - Point to IPFS content via contenthash
   - Human-readable access
   - Target: Phase 2

---

## Resources

### IPFS Tools
- IPFS Desktop: https://docs.ipfs.tech/install/ipfs-desktop/
- IPFS Companion: https://docs.ipfs.tech/install/ipfs-companion/
- Pinata: https://www.pinata.cloud/
- Web3.Storage: https://web3.storage/

### Blockchain Tools
- Sepolia Faucet: https://sepoliafaucet.com/
- Etherscan Sepolia: https://sepolia.etherscan.io/
- Hardhat: https://hardhat.org/
- Foundry: https://getfoundry.sh/

### Documentation
- IPFS Docs: https://docs.ipfs.tech/
- Ethereum Docs: https://ethereum.org/developers/
- Solidity Docs: https://docs.soliditylang.org/

---

*Last Updated: December 14, 2025*  
*Version: 1.0.0*
