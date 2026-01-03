# Architecture

## System Overview

PeaceBonds is a decentralized notarization system combining three core technologies:

```
┌─────────────────────────────────────────────────────────────┐
│                      PeaceBonds System                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────┐      ┌────────────┐      ┌──────────────┐  │
│  │    IPFS    │◄────►│   Crypto   │◄────►│  Blockchain  │  │
│  │  Storage   │      │ Signatures │      │   Anchoring  │  │
│  └────────────┘      └────────────┘      └──────────────┘  │
│       │                    │                     │          │
│       │                    │                     │          │
│       └────────────────────┴─────────────────────┘          │
│                            │                                │
│                      ┌─────▼──────┐                         │
│                      │  CLI Tool  │                         │
│                      └────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

## Component Architecture

### 1. Smart Contract Layer

**PeaceBondAnchor.sol**
- ERC-721 compliant NFT contract
- Each NFT represents one PeaceBond
- Stores immutable references to IPFS content

```solidity
struct AnchorData {
    string manifestCID;      // IPFS CID of manifest
    string signatureCID;     // IPFS CID of signatures
    bytes32 manifestHash;    // keccak256(manifestCID)
    bytes32 signatureHash;   // keccak256(signatureCID)
    uint256 timestamp;       // Block timestamp
    address creator;         // Anchor creator
}
```

**Key Functions:**
- `anchor(manifestCID, signatureCID)` → Creates new PeaceBond
- `verify(tokenId, manifestCID, signatureCID)` → Verifies CIDs
- `getAnchor(tokenId)` → Retrieves anchor data

**Events:**
- `PeaceBondAnchored` - Emitted on creation
- `PeaceBondVerified` - Emitted on verification

### 2. IPFS Layer

**Storage Strategy:**

```
Manifest File               Signature File
     │                            │
     ├─► Upload to IPFS          ├─► Upload to IPFS
     │                            │
     ├─► Returns CID             ├─► Returns CID
     │   (QmXXX...)              │   (QmYYY...)
     │                            │
     └───────────┬────────────────┘
                 │
                 ├─► Both CIDs stored on blockchain
                 │
                 └─► Content retrievable via any IPFS gateway
```

**Providers Supported:**
- Local IPFS node
- Infura IPFS API
- Pinata pinning service
- Public IPFS gateways (read-only)

**Content Addressing:**
- Manifest: Original document (markdown, text, JSON)
- Signatures: JSON file with metadata and signatures

### 3. Cryptographic Layer

**Signature Generation Flow:**

```
1. Manifest Content
   │
   ├─► keccak256 hash
   │   │
   │   └─► Message hash
   │
2. For each signer (3+):
   │
   ├─► Sign with secp256k1
   │   │
   │   └─► {v, r, s, signature, signer}
   │
3. Combine all signatures
   │
   └─► JSON signature file
       │
       └─► {version, protocol, messageHash, signatures[], timestamp}
```

**Verification Flow:**

```
1. Retrieve manifest content from IPFS
   │
2. Hash manifest → compute expected hash
   │
3. Retrieve signature file from IPFS
   │
4. Parse signatures
   │
5. For each signature:
   │
   ├─► Recover signer from signature
   │
   ├─► Verify signature is valid
   │
   └─► Collect valid signers
   │
6. Check minimum 3 valid signatures
```

### 4. Blockchain Integration Layer

**Network Support:**
- Ethereum (mainnet/Sepolia)
- Polygon
- Any EVM-compatible chain

**Transaction Flow:**

```
User initiates anchoring
    │
    ├─► CLI prepares transaction
    │   │
    │   ├─► manifestCID
    │   └─► signatureCID
    │
    ├─► Sign transaction with private key
    │
    ├─► Submit to blockchain
    │   │
    │   └─► Contract.anchor(manifestCID, signatureCID)
    │       │
    │       ├─► Validate inputs
    │       ├─► Compute hashes
    │       ├─► Mint ERC-721 token
    │       ├─► Store anchor data
    │       └─► Emit PeaceBondAnchored event
    │
    └─► Return tokenId and transaction hash
```

### 5. CLI Layer

**Command Architecture:**

```
peacebond CLI
    │
    ├─► create
    │   ├─► Read manifest file
    │   ├─► Generate signatures
    │   ├─► Upload to IPFS
    │   └─► Anchor to blockchain
    │
    ├─► verify
    │   ├─► Retrieve anchor data from chain
    │   ├─► Retrieve content from IPFS
    │   ├─► Verify signatures
    │   └─► Return verification report
    │
    └─► get
        └─► Retrieve and display anchor metadata
```

## Data Flow

### Creation Flow

```
1. User creates manifest.md
   │
2. CLI reads file
   │
3. Generate 3+ signatures
   │   ├─► Signer 1: secp256k1 signature
   │   ├─► Signer 2: secp256k1 signature
   │   └─► Signer 3: secp256k1 signature
   │
4. Upload manifest → IPFS
   │   └─► Returns manifestCID
   │
5. Upload signatures → IPFS
   │   └─► Returns signatureCID
   │
6. Call contract.anchor(manifestCID, signatureCID)
   │   ├─► Computes keccak256(manifestCID)
   │   ├─► Computes keccak256(signatureCID)
   │   ├─► Stores all data on-chain
   │   └─► Mints ERC-721 token
   │
7. Return tokenId to user
```

### Verification Flow (6 Steps per SPEC.md)

```
1. Retrieve anchor data from blockchain
   │   ├─► manifestCID
   │   ├─► signatureCID  
   │   ├─► manifestHash
   │   └─► signatureHash
   │
2. Retrieve manifest from IPFS using manifestCID
   │
3. Hash manifest content
   │   └─► Compare with on-chain hash
   │
4. Retrieve signature file from IPFS using signatureCID
   │
5. Verify all secp256k1 signatures
   │   ├─► For each signature:
   │   │   ├─► Recover signer address
   │   │   └─► Verify against manifest
   │   └─► Check ≥ 3 valid signatures
   │
6. Verify CID hashes match on-chain values
   │   ├─► keccak256(manifestCID) == manifestHash
   │   └─► keccak256(signatureCID) == signatureHash
   │
└─► Return comprehensive verification result
```

## Security Model

### Integrity Guarantees

**IPFS Content Addressing:**
- Content hash = identifier
- Modification changes CID
- Tamper-evident by design

**Cryptographic Hashing:**
- keccak256 used throughout
- Collision-resistant
- Deterministic output

**Blockchain Immutability:**
- Once anchored, cannot be modified
- Permanent public record
- Verifiable by anyone

### Authenticity Guarantees

**Multi-Signature Requirement:**
- Minimum 3 independent signers
- secp256k1 (Ethereum standard)
- Signer addresses recoverable

**Signature Verification:**
- Each signature independently verifiable
- No trust in aggregation
- Signer accountability

### Trust Model

**What PeaceBonds Guarantees:**
- ✅ Document existed at timestamp T
- ✅ Document was signed by addresses A, B, C
- ✅ CIDs and hashes match on-chain data
- ✅ Content retrievable from IPFS

**What PeaceBonds Does NOT Guarantee:**
- ❌ Truth or validity of manifest content
- ❌ Authority or identity of signers
- ❌ Legal enforceability
- ❌ IPFS content availability (depends on pinning)

## Deployment Architecture

### Recommended Setup

```
Production Environment:
    │
    ├─► Smart Contract
    │   └─► Deployed on Ethereum mainnet
    │       (or Polygon for lower costs)
    │
    ├─► IPFS Storage
    │   ├─► Primary: Pinata or Infura (pinning service)
    │   └─► Backup: Local IPFS node
    │
    └─► Application Layer
        ├─► Backend API (optional)
        │   └─► Wraps CLI functionality
        │
        └─► Frontend UI (optional)
            └─► User-friendly interface
```

## Performance Considerations

### Transaction Costs

**Gas Usage (approximate):**
- Deploy contract: ~2.5M gas
- Create PeaceBond: ~200K gas
- Verify: ~50K gas (read-only, can be free)

**Cost Optimization:**
- Use L2 (Polygon, Arbitrum, Optimism)
- Batch operations if creating multiple
- Read operations are free (view functions)

### IPFS Performance

**Upload:**
- Small files (<1MB): Near instant
- Pinning propagation: Seconds to minutes
- Global availability: Depends on pinning

**Retrieval:**
- Pinned content: Fast (< 1 second)
- Unpinned content: Slower (DHT lookup required)
- Use gateways for reliability

## Scalability

**Blockchain:**
- Limited by network throughput
- Consider L2 solutions for high volume
- Each PeaceBond = 1 transaction

**IPFS:**
- Highly scalable for content storage
- Content addressing enables CDN-like distribution
- Pinning services recommended for production

**Verification:**
- Verification is parallelizable
- No blockchain writes needed
- Can verify 1000s/sec

## Future Extensions

### Possible Enhancements

1. **Multi-chain support**
   - Anchor same PeaceBond to multiple chains
   - Cross-chain verification

2. **Enhanced metadata**
   - Rich content types
   - Embedded media
   - Linked documents

3. **DAG structures**
   - Version chains
   - Amendment trails
   - Document relationships

4. **Governance**
   - Signer reputation
   - Revocation mechanisms
   - Dispute resolution

### Not Planned (Per SPEC.md)

- ❌ Token economics
- ❌ DAO governance
- ❌ Content moderation
- ❌ AI consensus mechanisms
