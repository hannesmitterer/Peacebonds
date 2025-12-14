# Scripts Directory

This directory contains scripts and contracts for deploying and managing the Euystacio Framework documentation distribution.

## Contents

### IPFS Deployment

- **`deploy-to-ipfs.sh`**: Bash script to upload documentation to IPFS and pin it
  - Generates manifest
  - Uploads to IPFS
  - Pins content locally
  - Generates deployment report
  - Usage: `./scripts/deploy-to-ipfs.sh`

### Blockchain Anchoring

- **`EuystacioDocumentAnchor.sol`**: Smart contract for anchoring document hashes
  - Stores content hashes with IPFS CIDs
  - Provides verification functions
  - Manages authorized publishers
  - Fully documented and auditable

- **`DEPLOYMENT_GUIDE.md`**: Comprehensive guide for deploying the smart contract
  - Hardhat deployment instructions
  - Foundry deployment instructions
  - Verification procedures
  - Troubleshooting tips

### Output Files

The `output/` subdirectory (created automatically) contains:
- `manifest.json`: Documentation manifest
- `ipfs-deployment.json`: IPFS deployment details
- `deployment.json`: Smart contract deployment info
- `anchor-info.json`: Document anchoring details
- `hashes.txt`: SHA-256 hashes of all documents

**Note**: The `output/` directory is in `.gitignore` and not committed to the repository.

## Quick Start

### 1. Deploy to IPFS

```bash
# Make script executable
chmod +x scripts/deploy-to-ipfs.sh

# Run deployment
./scripts/deploy-to-ipfs.sh
```

This will:
- Upload documentation to IPFS
- Generate CIDs for all content
- Create deployment report
- Provide next steps

### 2. Deploy Smart Contract

Follow the detailed instructions in `DEPLOYMENT_GUIDE.md`:

```bash
# Option A: Using Hardhat
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
# ... follow guide ...

# Option B: Using Foundry
forge create --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY \
  scripts/EuystacioDocumentAnchor.sol:EuystacioDocumentAnchor
```

### 3. Anchor Document Hash

After deploying the contract and uploading to IPFS:

```bash
# Using the deployment scripts provided in DEPLOYMENT_GUIDE.md
npx hardhat run scripts/anchor-document.js --network sepolia
```

## Prerequisites

### For IPFS Deployment
- IPFS (Kubo) installed: https://docs.ipfs.tech/install/
- Bash shell
- `sha256sum` utility (included in most Unix systems)

### For Blockchain Deployment
- Node.js and npm
- Ethereum wallet with Sepolia testnet ETH
- RPC URL (Alchemy, Infura, or other provider)
- Either Hardhat or Foundry

## Security Notes

⚠️ **IMPORTANT**:
- Never commit private keys or `.env` files
- Always use `.gitignore` for sensitive files
- Test on Sepolia before mainnet deployment
- Consider hardware wallets for mainnet
- Get security audits for production contracts

## Workflow Overview

```
1. Documentation Creation
   ↓
2. IPFS Upload (deploy-to-ipfs.sh)
   ↓
3. Get CIDs
   ↓
4. Deploy Smart Contract (DEPLOYMENT_GUIDE.md)
   ↓
5. Anchor Document Hashes
   ↓
6. Update README and docs with CIDs and contract address
   ↓
7. Community verification
```

## Verification

Community members can verify the documentation:

1. **Download from IPFS** using the CID
2. **Calculate hash**: `sha256sum <file>`
3. **Query blockchain** contract with hash
4. **Compare** results

See `docs/distribution/README.md` for detailed verification instructions.

## Support

For issues or questions:
- Open an issue on GitHub
- Check the DEPLOYMENT_GUIDE.md troubleshooting section
- Join our Discord (link in main README)

## License

All scripts and contracts are open source under the same license as the main repository (CC BY-SA 4.0 for documentation, MIT for code).

---

*Part of the Euystacio Framework project*  
*"No ownership, only sharing."*
