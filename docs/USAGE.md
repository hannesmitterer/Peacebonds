# Usage Guide

## Prerequisites

1. **Node.js** v18+ installed
2. **IPFS node** running (optional, can use gateways)
3. **Wallet** with testnet/mainnet funds
4. **Contract deployed** on your chosen network

## Installation

```bash
git clone https://github.com/hannesmitterer/Peacebonds.git
cd Peacebonds
npm install
npm run compile
npm run build
```

## Configuration

Create a `.env` file:

```bash
cp .env.example .env
```

Edit `.env` with your settings:

```
# Blockchain Configuration
SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
PRIVATE_KEY=your_private_key_here

# IPFS Configuration
IPFS_API_URL=http://127.0.0.1:5001

# Contract Address (after deployment)
PEACEBOND_CONTRACT_ADDRESS=0x...
```

## Deploying the Contract

### Local Development

```bash
# Start Hardhat node
npx hardhat node

# In another terminal, deploy
node dist/scripts/deploy.js
```

### Testnet (Sepolia)

```bash
# Make sure SEPOLIA_RPC_URL and PRIVATE_KEY are set in .env
npm run compile
node dist/scripts/deploy.js
```

Save the deployed contract address to your `.env` file.

## Creating a PeaceBond

### Step 1: Create Your Manifest

Create a markdown file with your content:

```bash
nano my-manifest.md
```

Example content:
```markdown
# My Declaration

This is my manifesto declaring...

[Your content here]

Date: 2026-01-03
```

### Step 2: Generate PeaceBond

**With specific signers (3+ private keys):**

```bash
node dist/cli/index.js create my-manifest.md \
  --signers "0xabc...,0xdef...,0x123..." \
  --contract YOUR_CONTRACT_ADDRESS \
  --network sepolia
```

**With auto-generated signers (for testing):**

```bash
node dist/cli/index.js create my-manifest.md \
  --contract YOUR_CONTRACT_ADDRESS \
  --network sepolia
```

**Output:**
```
=== Creating PeaceBond ===

Reading manifest from my-manifest.md...
Uploading manifest to IPFS...
Manifest uploaded with CID: QmXXX...

Generating signatures...
Uploading signatures to IPFS...
Signature file uploaded with CID: QmYYY...

Anchoring to blockchain...
Transaction sent: 0x...
Transaction confirmed

✓ PeaceBond Created Successfully!
  Token ID:      1
  Manifest CID:  QmXXX...
  Signature CID: QmYYY...
  TX Hash:       0x...
```

## Verifying a PeaceBond

Verify any PeaceBond by its token ID:

```bash
node dist/cli/index.js verify 1 \
  --contract YOUR_CONTRACT_ADDRESS \
  --network sepolia
```

**Output:**
```
=== Verifying PeaceBond #1 ===

=== Step 1/6: Retrieving anchor data from blockchain ===
✓ Manifest CID: QmXXX...
✓ Signature CID: QmYYY...
✓ Timestamp: 2026-01-03T22:00:00.000Z
✓ Creator: 0x...

=== Step 2/6: Retrieving manifest from IPFS ===
✓ Manifest retrieved (500 bytes)

=== Step 3/6: Hashing manifest content ===
✓ Manifest CID hash: 0x...
✓ On-chain hash:     0x...

=== Step 4/6: Retrieving signature file from IPFS ===
✓ Signature file retrieved

=== Step 5/6: Verifying cryptographic signatures ===
✓ All signatures verified (3 signers)
  Signer 1: 0x...
  Signer 2: 0x...
  Signer 3: 0x...

=== Step 6/6: Verifying on-chain data ===
✓ On-chain verification: PASSED

=== Verification Summary ===
Manifest Verified:    ✓ PASS
Signatures Verified:  ✓ PASS
On-Chain Verified:    ✓ PASS
Overall Result:       ✓ VALID
```

## Getting PeaceBond Details

Retrieve metadata for any PeaceBond:

```bash
node dist/cli/index.js get 1 \
  --contract YOUR_CONTRACT_ADDRESS \
  --network sepolia
```

**Output:**
```
=== PeaceBond #1 Details ===

Manifest CID:   QmXXX...
Signature CID:  QmYYY...
Manifest Hash:  0x...
Signature Hash: 0x...
Timestamp:      2026-01-03T22:00:00.000Z
Creator:        0x...
```

## Advanced Usage

### Using Different IPFS Providers

**Infura:**
```bash
# Set in .env
INFURA_PROJECT_ID=your_project_id
INFURA_PROJECT_SECRET=your_secret

node dist/cli/index.js create manifest.md \
  --contract ADDRESS \
  --network sepolia
```

**Pinata:**
```bash
# Set in .env
PINATA_API_KEY=your_api_key
PINATA_SECRET_KEY=your_secret_key
```

**Custom IPFS node:**
```bash
node dist/cli/index.js create manifest.md \
  --ipfs-url http://your-ipfs-node:5001 \
  --contract ADDRESS \
  --network sepolia
```

### Multi-Signature Workflow

For production use with multiple independent signers:

1. **Party 1** creates manifest and shares it
2. Each party generates their signature:
   ```typescript
   import { generateSignatures } from './src/signature/generate.js';
   const sigs = await generateSignatures(manifestContent, [privateKey]);
   ```
3. Combine signatures into single file
4. Upload to IPFS and anchor

### Programmatic Usage

```typescript
import { uploadManifest, uploadSignature } from './src/ipfs/upload.js';
import { generateSignatures, serializeSignatures } from './src/signature/generate.js';
import { anchorPeaceBond } from './src/blockchain/anchor.js';

// Create PeaceBond programmatically
const manifestContent = "# My Manifest\n...";
const privateKeys = ["0x...", "0x...", "0x..."];

const manifestCID = await uploadManifest(manifestContent);
const signatures = await generateSignatures(manifestContent, privateKeys);
const signatureJSON = serializeSignatures(signatures, manifestCID);
const signatureCID = await uploadSignature(signatureJSON);

const result = await anchorPeaceBond(manifestCID, signatureCID, {
  rpcUrl: "https://ethereum-sepolia-rpc.publicnode.com",
  privateKey: "0x...",
  contractAddress: "0x..."
});

console.log(`PeaceBond #${result.tokenId} created`);
```

## Troubleshooting

### IPFS Connection Issues

If IPFS upload fails:

1. Check if IPFS daemon is running: `ipfs daemon`
2. Use HTTP gateway as fallback
3. Configure Infura or Pinata credentials

### Transaction Failures

- Check wallet has sufficient funds for gas
- Verify RPC URL is correct
- Check contract address is correct
- Ensure private key is valid

### Signature Verification Fails

- Ensure manifest content hasn't been modified
- Check all signers used correct manifest
- Verify at least 3 signatures present

## Next Steps

- See [API.md](API.md) for programmatic API reference
- See [ARCHITECTURE.md](ARCHITECTURE.md) for system design
- See [SPEC.md](../SPEC.md) for protocol specification
