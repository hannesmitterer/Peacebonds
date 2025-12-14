# Blockchain Anchoring Guide

## Euystacio Framework - Ethereum Integration

**Version:** 1.0  
**Last Updated:** December 14, 2025  
**Network:** Sepolia Testnet → Mainnet

---

## Overview

This guide explains how the Euystacio Framework uses Ethereum blockchain to anchor IPFS CIDs, creating an immutable, verifiable record of framework content.

---

## Why Blockchain Anchoring?

### Benefits

1. **Immutability**: Once recorded, CIDs cannot be altered
2. **Verifiability**: Anyone can verify content authenticity
3. **Decentralization**: No single point of failure
4. **Transparency**: All changes are publicly auditable
5. **Permanence**: Blockchain survives indefinitely

### Use Cases

- **Verify Document Integrity**: Confirm downloaded content is authentic
- **Track Version History**: See all framework updates over time
- **Prove Existence**: Cryptographic proof content existed at specific time
- **Enable Trust**: Third parties can independently verify

---

## Smart Contract Architecture

### IPFSAnchor.sol

The IPFSAnchor contract provides:

**Core Features**:
- Store IPFS CIDs on-chain
- Maintain version history
- Multi-signature authorization
- Event logging for transparency

**Key Functions**:

```solidity
// Anchor a new CID
function anchorCID(
    string memory cid,
    string memory version,
    string memory description
) external onlyAuthorized

// Get latest CID
function getLatestCID() external view returns (string memory)

// Get CID history
function getCIDRecord(uint256 index) external view returns (CIDRecord memory)

// Verify CID exists
function verifyCID(string memory cid) external view returns (bool)
```

**Security**:
- Owner-based access control
- Authorized updaters only
- Input validation
- Event emission for transparency

---

## Deployment Process

### Prerequisites

```bash
# Install dependencies
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox

# Or using yarn
yarn add --dev hardhat @nomicfoundation/hardhat-toolbox
```

### Configuration

Create `hardhat.config.js`:

```javascript
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.20",
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "https://rpc.sepolia.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
    mainnet: {
      url: process.env.MAINNET_RPC_URL || "https://eth.llamarpc.com",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
```

### Environment Setup

```bash
# Create .env file
cat > .env << EOF
SEPOLIA_RPC_URL=https://rpc.sepolia.org
MAINNET_RPC_URL=https://eth.llamarpc.com
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key
EOF

# DO NOT commit .env file
echo ".env" >> .gitignore
```

### Deploy to Sepolia

```bash
# Compile contract
npx hardhat compile

# Deploy
npx hardhat run scripts/deploy-blockchain-anchor.js --network sepolia

# Verify on Etherscan
npx hardhat verify --network sepolia DEPLOYED_ADDRESS "initialCID" "Initial deployment"
```

---

## Deployed Contracts

### Sepolia Testnet

**Contract Address**: `[To be deployed]`  
**Explorer**: https://sepolia.etherscan.io/address/[ADDRESS]  
**Network ID**: 11155111  
**Chain ID**: 11155111  

**Deployment Info**:
```json
{
  "network": "sepolia",
  "address": "TBD",
  "deployer": "TBD",
  "deployedAt": "TBD",
  "txHash": "TBD",
  "blockNumber": 0
}
```

### Mainnet (Future)

**Contract Address**: `[Migration planned Q3 2026]`  
**Explorer**: https://etherscan.io/address/[ADDRESS]  
**Network ID**: 1  
**Chain ID**: 1  

---

## Using the Contract

### Read Operations (No Gas)

#### Get Latest CID

```javascript
const { ethers } = require("ethers");

const provider = new ethers.JsonRpcProvider("https://rpc.sepolia.org");
const contractAddress = "DEPLOYED_ADDRESS";
const abi = [...]; // IPFSAnchor ABI

const contract = new ethers.Contract(contractAddress, abi, provider);

// Get latest CID
const cid = await contract.getLatestCID();
console.log("Latest CID:", cid);

// Access via IPFS
console.log("URL:", `https://ipfs.io/ipfs/${cid}`);
```

#### Get Version History

```javascript
// Get history count
const count = await contract.getHistoryCount();

// Get each record
for (let i = 0; i < count; i++) {
  const record = await contract.getCIDRecord(i);
  console.log(`Version ${i}:`, {
    cid: record.cid,
    timestamp: new Date(Number(record.timestamp) * 1000),
    version: record.version,
    description: record.description,
  });
}
```

#### Verify CID

```javascript
const cidToVerify = "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG";
const isValid = await contract.verifyCID(cidToVerify);
console.log("CID is valid:", isValid);
```

### Write Operations (Requires Gas)

#### Anchor New CID

```javascript
const { ethers } = require("ethers");

const provider = new ethers.JsonRpcProvider("https://rpc.sepolia.org");
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const contract = new ethers.Contract(contractAddress, abi, signer);

// Anchor new CID
const tx = await contract.anchorCID(
  "QmNewCID...",
  "1.3",
  "Added new features and documentation"
);

// Wait for confirmation
const receipt = await tx.wait();
console.log("Transaction hash:", receipt.hash);
console.log("Block number:", receipt.blockNumber);
```

#### Authorize Updater

```javascript
const newUpdater = "0x1234...5678";
const tx = await contract.authorizeUpdater(newUpdater);
await tx.wait();
console.log("Updater authorized:", newUpdater);
```

---

## Verification Protocol

### Step 1: Get CID from Blockchain

```bash
# Using cast (Foundry)
cast call DEPLOYED_ADDRESS "getLatestCID()(string)" --rpc-url https://rpc.sepolia.org

# Using Etherscan
# Navigate to Read Contract tab
# Call getLatestCID function
```

### Step 2: Download from IPFS

```bash
# Get CID from blockchain
CID=$(cast call DEPLOYED_ADDRESS "getLatestCID()(string)" --rpc-url https://rpc.sepolia.org)

# Download content
ipfs get $CID -o framework/
```

### Step 3: Verify Hash

```bash
# Calculate hash of downloaded content
LOCAL_CID=$(ipfs add -r framework/ --only-hash | tail -1 | awk '{print $2}')

# Compare with blockchain
if [ "$LOCAL_CID" == "$CID" ]; then
  echo "✓ Verification successful"
else
  echo "✗ Verification failed"
fi
```

### Automated Verification Script

```bash
#!/bin/bash
# verify-blockchain-anchor.sh

RPC_URL="https://rpc.sepolia.org"
CONTRACT="DEPLOYED_ADDRESS"

# Get CID from blockchain
BLOCKCHAIN_CID=$(cast call $CONTRACT "getLatestCID()(string)" --rpc-url $RPC_URL)

# Download from IPFS
ipfs get $BLOCKCHAIN_CID -o /tmp/framework-verify

# Calculate local hash
LOCAL_CID=$(ipfs add -r /tmp/framework-verify --only-hash | tail -1 | awk '{print $2}')

# Compare
if [ "$BLOCKCHAIN_CID" == "$LOCAL_CID" ]; then
  echo "✓ Content verified successfully"
  echo "✓ Blockchain anchor is valid"
  echo "✓ Content has not been tampered with"
  exit 0
else
  echo "✗ Verification failed"
  echo "Blockchain CID: $BLOCKCHAIN_CID"
  echo "Local CID: $LOCAL_CID"
  exit 1
fi
```

---

## Event Monitoring

### Listen for CID Updates

```javascript
// Watch for new anchors
contract.on("CIDAnchored", (cid, timestamp, updatedBy, version, description) => {
  console.log("New CID anchored:", {
    cid,
    timestamp: new Date(Number(timestamp) * 1000),
    updatedBy,
    version,
    description,
  });
});

// Or query historical events
const filter = contract.filters.CIDAnchored();
const events = await contract.queryFilter(filter, 0, "latest");

events.forEach((event) => {
  console.log(event.args);
});
```

---

## Gas Costs

### Estimated Costs (Sepolia Testnet)

| Operation | Gas Units | Cost (ETH @ 20 gwei) |
|-----------|-----------|---------------------|
| Deploy Contract | ~1,500,000 | 0.03 ETH |
| Anchor CID | ~150,000 | 0.003 ETH |
| Authorize Updater | ~50,000 | 0.001 ETH |

### Mainnet Considerations

- Monitor gas prices: https://etherscan.io/gastracker
- Use EIP-1559 for better estimates
- Consider Layer 2 for lower costs (future)

---

## Security Best Practices

### Key Management

1. **Use Hardware Wallets**: Ledger or Trezor for production
2. **Multi-Sig**: Gnosis Safe for critical operations
3. **Key Rotation**: Regular private key updates
4. **Backup**: Secure, encrypted backups

### Contract Security

1. **Audits**: Professional security audits before mainnet
2. **Testing**: Comprehensive test coverage
3. **Timelock**: Delayed execution for critical changes
4. **Monitoring**: Real-time alert systems

### Operational Security

1. **Separate Accounts**: Different keys for different purposes
2. **Rate Limiting**: Prevent rapid unauthorized updates
3. **Access Control**: Minimal necessary permissions
4. **Incident Response**: Plan for security events

---

## Migration to Mainnet

### Timeline

**Target Date**: Q3 2026  
**Prerequisites**: 
- 6+ months Sepolia operation
- Security audit completed
- Community approval via governance
- Sufficient funding secured

### Migration Process

1. **Audit & Review** (4 weeks)
   - Professional security audit
   - Community review period
   - Bug bounty program
   - Final testing

2. **Deployment** (1 week)
   - Deploy to mainnet
   - Verify contract on Etherscan
   - Test all functions
   - Initialize with current CID

3. **Transition** (2 weeks)
   - Run both contracts in parallel
   - Sync data from Sepolia
   - Community verification
   - Switch primary reference

4. **Deprecation** (4 weeks)
   - Mark Sepolia as legacy
   - Update all documentation
   - Notify community
   - Maintain for historical reference

### Cost Estimate

- Deployment: ~0.3 ETH
- Initial operations: ~0.1 ETH
- Reserve fund: 1 ETH
- **Total**: ~1.5 ETH (~$5,000 at current prices)

---

## Troubleshooting

### Transaction Failed

**Problem**: Transaction reverted

**Solutions**:
1. Check you're authorized updater
2. Verify CID format is valid
3. Ensure sufficient gas limit
4. Check network congestion

### CID Not Found

**Problem**: Contract returns empty string

**Solutions**:
1. Verify contract address is correct
2. Check you're on correct network
3. Confirm contract was initialized
4. Review deployment logs

### Verification Failed

**Problem**: Downloaded content doesn't match CID

**Solutions**:
1. Re-download from different gateway
2. Verify blockchain CID is correct
3. Check for IPFS propagation delays
4. Report if persistent

---

## API Integration

### JavaScript/TypeScript

```typescript
import { ethers } from "ethers";

class EuystacioAnchor {
  private contract: ethers.Contract;

  constructor(contractAddress: string, providerUrl: string) {
    const provider = new ethers.JsonRpcProvider(providerUrl);
    const abi = [...]; // Load ABI
    this.contract = new ethers.Contract(contractAddress, abi, provider);
  }

  async getLatestCID(): Promise<string> {
    return await this.contract.getLatestCID();
  }

  async getHistory(): Promise<CIDRecord[]> {
    const count = await this.contract.getHistoryCount();
    const history = [];
    for (let i = 0; i < count; i++) {
      history.push(await this.contract.getCIDRecord(i));
    }
    return history;
  }

  async verifyCID(cid: string): Promise<boolean> {
    return await this.contract.verifyCID(cid);
  }
}
```

### Python

```python
from web3 import Web3

class EuystacioAnchor:
    def __init__(self, contract_address, rpc_url):
        self.w3 = Web3(Web3.HTTPProvider(rpc_url))
        self.contract = self.w3.eth.contract(
            address=contract_address,
            abi=[...]  # Load ABI
        )
    
    def get_latest_cid(self):
        return self.contract.functions.getLatestCID().call()
    
    def get_history(self):
        count = self.contract.functions.getHistoryCount().call()
        return [
            self.contract.functions.getCIDRecord(i).call()
            for i in range(count)
        ]
    
    def verify_cid(self, cid):
        return self.contract.functions.verifyCID(cid).call()
```

---

## Resources

### Documentation

- **Ethereum**: https://ethereum.org/en/developers/docs/
- **Hardhat**: https://hardhat.org/docs
- **Ethers.js**: https://docs.ethers.org/

### Explorers

- **Sepolia**: https://sepolia.etherscan.io
- **Mainnet**: https://etherscan.io

### Tools

- **Remix**: https://remix.ethereum.org
- **Foundry**: https://book.getfoundry.sh
- **Tenderly**: https://tenderly.co

---

## Support

- **Technical Issues**: blockchain@euystacio.org (future)
- **GitHub Issues**: https://github.com/hannesmitterer/Peacebonds/issues
- **Community Forum**: https://forum.euystacio.org (future)

---

**Contract Version**: 1.0  
**Last Updated**: December 14, 2025  
**Next Review**: March 2026
