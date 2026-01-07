# Quick Reference

## Installation & Setup

```bash
npm install
npm run compile
npm run build
cp .env.example .env
# Edit .env with your settings
```

## Deploy Contract

```bash
node dist/scripts/deploy.js
# Save the contract address to .env
```

## CLI Commands

### Create PeaceBond
```bash
node dist/src/cli/index.js create <manifest-file> \
  --contract <ADDRESS> \
  --network <sepolia|polygon|hardhat>
```

### Verify PeaceBond
```bash
node dist/src/cli/index.js verify <TOKEN_ID> \
  --contract <ADDRESS> \
  --network <sepolia|polygon|hardhat>
```

### Get Details
```bash
node dist/src/cli/index.js get <TOKEN_ID> \
  --contract <ADDRESS> \
  --network <sepolia|polygon|hardhat>
```

## Environment Variables

```env
SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
PRIVATE_KEY=your_private_key
PEACEBOND_CONTRACT_ADDRESS=deployed_contract_address
IPFS_API_URL=http://127.0.0.1:5001
```

## Programmatic Usage

```typescript
import { uploadManifest, uploadSignature } from './src/ipfs/upload.js';
import { generateSignatures, serializeSignatures } from './src/signature/generate.js';
import { anchorPeaceBond } from './src/blockchain/anchor.js';
import { verifyPeaceBond } from './src/blockchain/verify.js';

// Create
const manifestCID = await uploadManifest(content);
const sigs = await generateSignatures(content, [key1, key2, key3]);
const sigJSON = serializeSignatures(sigs, manifestCID);
const signatureCID = await uploadSignature(sigJSON);
const result = await anchorPeaceBond(manifestCID, signatureCID, config);

// Verify
const verification = await verifyPeaceBond(tokenId, contractAddress, config);
```

## Smart Contract Functions

```solidity
// Create
uint256 tokenId = contract.anchor(manifestCID, signatureCID);

// Verify
bool isValid = contract.verify(tokenId, manifestCID, signatureCID);

// Get Details
(string memory manifestCID,
 string memory signatureCID,
 bytes32 manifestHash,
 bytes32 signatureHash,
 uint256 timestamp,
 address creator) = contract.getAnchor(tokenId);
```

## File Locations

- Smart Contract: `contracts/PeaceBondAnchor.sol`
- CLI: `src/cli/index.ts`
- Signature Utils: `src/signature/`
- IPFS Utils: `src/ipfs/`
- Blockchain Utils: `src/blockchain/`
- Build Output: `dist/`
- Examples: `examples/manifests/`

## Documentation

- **SPEC.md** - Protocol specification
- **docs/README.md** - Overview
- **docs/USAGE.md** - Usage guide
- **docs/API.md** - API reference
- **docs/ARCHITECTURE.md** - System design
- **docs/DEPLOYMENT.md** - Deployment guide

## Common Issues

**"Module not found"**
→ Run `npm run build`

**"Contract not found"**
→ Set `PEACEBOND_CONTRACT_ADDRESS` in `.env`

**"IPFS connection failed"**
→ Start IPFS: `ipfs daemon`

**"Insufficient funds"**
→ Add ETH to wallet for gas

## Networks

- **Hardhat**: http://127.0.0.1:8545 (local)
- **Sepolia**: https://ethereum-sepolia-rpc.publicnode.com (testnet)
- **Polygon**: https://polygon-rpc.com (mainnet)

## Verification Steps (6-Step Procedure)

1. ✓ Retrieve anchor data from blockchain
2. ✓ Retrieve manifest from IPFS
3. ✓ Hash manifest content
4. ✓ Retrieve signatures from IPFS
5. ✓ Verify all signatures (min 3)
6. ✓ Verify CID hashes match on-chain

## Gas Costs (Approximate)

- Deploy: ~2.5M gas
- Create: ~200K gas
- Verify: Free (read-only)
- Get: Free (read-only)

## License

MIT
