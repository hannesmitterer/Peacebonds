# Blockchain Anchoring Deployment Guide

This guide explains how to deploy the EuystacioDocumentAnchor smart contract and anchor documentation hashes on Ethereum Sepolia.

## Prerequisites

1. **Node.js and npm** installed
2. **Ethereum wallet** with Sepolia testnet ETH
3. **RPC URL** for Sepolia (e.g., from Alchemy or Infura)
4. **Private key** (never commit this!)

## Option 1: Deploy with Hardhat

### Step 1: Install Hardhat

```bash
# Navigate to your repository root
cd /path/to/Peacebonds
npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npx hardhat init
```

Select "Create a TypeScript project" or "Create a JavaScript project"

### Step 2: Configure Hardhat

Edit `hardhat.config.js` or `hardhat.config.ts`:

```javascript
require("@nomicfoundation/hardhat-toolbox");

// Load environment variables
require('dotenv').config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};
```

### Step 3: Create .env file

```bash
cat > .env <<EOF
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key
EOF
```

**⚠️ IMPORTANT**: Never commit `.env` file! It should be in `.gitignore`

### Step 4: Copy Contract

```bash
mkdir -p contracts
cp scripts/EuystacioDocumentAnchor.sol contracts/
```

### Step 5: Create Deployment Script

Create `scripts/deploy.js`:

```javascript
const hre = require("hardhat");

async function main() {
  console.log("Deploying EuystacioDocumentAnchor...");
  
  const EuystacioDocumentAnchor = await hre.ethers.getContractFactory("EuystacioDocumentAnchor");
  const anchor = await EuystacioDocumentAnchor.deploy();
  
  await anchor.waitForDeployment();
  
  const address = await anchor.getAddress();
  
  console.log("EuystacioDocumentAnchor deployed to:", address);
  console.log("Transaction hash:", anchor.deploymentTransaction().hash);
  
  // Save deployment info
  const fs = require('fs');
  const deploymentInfo = {
    network: hre.network.name,
    contractAddress: address,
    deploymentHash: anchor.deploymentTransaction().hash,
    timestamp: new Date().toISOString(),
    deployer: (await hre.ethers.getSigners())[0].address
  };
  
  fs.writeFileSync(
    './scripts/output/deployment.json',
    JSON.stringify(deploymentInfo, null, 2)
  );
  
  console.log("Deployment info saved to scripts/output/deployment.json");
  
  // Wait for block confirmations
  console.log("Waiting for block confirmations...");
  await anchor.deploymentTransaction().wait(5);
  
  // Verify on Etherscan
  if (hre.network.name === "sepolia") {
    console.log("Verifying contract on Etherscan...");
    try {
      await hre.run("verify:verify", {
        address: address,
        constructorArguments: [],
      });
      console.log("Contract verified!");
    } catch (error) {
      console.log("Verification failed:", error.message);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Step 6: Deploy

```bash
npx hardhat run scripts/deploy.js --network sepolia
```

### Step 7: Anchor Document Hash

Create `scripts/anchor-document.js`:

```javascript
const hre = require("hardhat");
const fs = require("fs");
const crypto = require("crypto");

async function main() {
  // Load deployment info
  const deployment = JSON.parse(
    fs.readFileSync('./scripts/output/deployment.json', 'utf8')
  );
  
  // Load IPFS deployment info
  const ipfsDeployment = JSON.parse(
    fs.readFileSync('./scripts/output/ipfs-deployment.json', 'utf8')
  );
  
  // Get contract instance
  const EuystacioDocumentAnchor = await hre.ethers.getContractFactory("EuystacioDocumentAnchor");
  const anchor = EuystacioDocumentAnchor.attach(deployment.contractAddress);
  
  // Read master document
  const masterDoc = fs.readFileSync('./docs/EUYSTACIO_FRAMEWORK_MASTER.md', 'utf8');
  
  // Calculate hash
  const contentHash = '0x' + crypto.createHash('sha256').update(masterDoc).digest('hex');
  
  console.log("Anchoring document...");
  console.log("Content Hash:", contentHash);
  console.log("IPFS CID:", ipfsDeployment.cids.master_document);
  
  // Anchor the document
  const tx = await anchor.anchorDocument(
    contentHash,
    ipfsDeployment.cids.master_document,
    "1.0.0",
    JSON.stringify({
      name: "Euystacio Framework Executive Master Document",
      description: "Genesis release of the Euystacio Framework documentation",
      date: new Date().toISOString(),
      type: "master-document"
    })
  );
  
  console.log("Transaction submitted:", tx.hash);
  
  const receipt = await tx.wait();
  console.log("Transaction confirmed in block:", receipt.blockNumber);
  
  // Save anchoring info
  const anchorInfo = {
    contentHash: contentHash,
    ipfsCid: ipfsDeployment.cids.master_document,
    transactionHash: tx.hash,
    blockNumber: receipt.blockNumber,
    timestamp: new Date().toISOString(),
    contractAddress: deployment.contractAddress,
    network: hre.network.name
  };
  
  fs.writeFileSync(
    './scripts/output/anchor-info.json',
    JSON.stringify(anchorInfo, null, 2)
  );
  
  console.log("Anchor info saved to scripts/output/anchor-info.json");
  console.log("\nView on Etherscan:");
  console.log(`https://sepolia.etherscan.io/tx/${tx.hash}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Step 8: Anchor the Document

```bash
npx hardhat run scripts/anchor-document.js --network sepolia
```

---

## Option 2: Deploy with Foundry

### Step 1: Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Step 2: Initialize Foundry Project

```bash
forge init --no-git
```

### Step 3: Copy Contract

```bash
cp scripts/EuystacioDocumentAnchor.sol src/
```

### Step 4: Deploy

```bash
# Set environment variables
export SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY"
export PRIVATE_KEY="your_private_key_here"

# Deploy
forge create \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  src/EuystacioDocumentAnchor.sol:EuystacioDocumentAnchor

# Save the contract address from the output
export CONTRACT_ADDRESS="0x..."
```

### Step 5: Verify Contract

```bash
forge verify-contract \
  --chain-id 11155111 \
  --compiler-version v0.8.20 \
  $CONTRACT_ADDRESS \
  src/EuystacioDocumentAnchor.sol:EuystacioDocumentAnchor \
  $ETHERSCAN_API_KEY
```

### Step 6: Anchor Document

```bash
# Calculate document hash
CONTENT_HASH=$(sha256sum docs/EUYSTACIO_FRAMEWORK_MASTER.md | awk '{print "0x" $1}')

# Get IPFS CID from deployment
IPFS_CID=$(cat scripts/output/ipfs-deployment.json | jq -r '.cids.master_document')

# Call anchor function
cast send $CONTRACT_ADDRESS \
  "anchorDocument(bytes32,string,string,string)" \
  $CONTENT_HASH \
  "$IPFS_CID" \
  "1.0.0" \
  '{"name":"Euystacio Framework Executive Master Document"}' \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

---

## Get Sepolia Test ETH

Before deploying, you need Sepolia testnet ETH:

1. **Alchemy Faucet**: https://sepoliafaucet.com/
2. **Infura Faucet**: https://www.infura.io/faucet/sepolia
3. **QuickNode Faucet**: https://faucet.quicknode.com/ethereum/sepolia

---

## Verification

After deployment and anchoring, verify everything:

### 1. Check Contract on Etherscan

```
https://sepolia.etherscan.io/address/[CONTRACT_ADDRESS]
```

### 2. Verify Document Anchoring

Using Hardhat console:

```bash
npx hardhat console --network sepolia
```

```javascript
const anchor = await ethers.getContractAt("EuystacioDocumentAnchor", "CONTRACT_ADDRESS");
const record = await anchor.verifyDocument("CONTENT_HASH");
console.log(record);
```

### 3. Verify Document Integrity

```bash
# Download from IPFS
wget https://ipfs.io/ipfs/[CID]/EUYSTACIO_FRAMEWORK_MASTER.md

# Calculate hash
sha256sum EUYSTACIO_FRAMEWORK_MASTER.md

# Compare with on-chain hash
# They should match!
```

---

## Security Best Practices

1. **Never commit private keys**: Always use `.env` files and `.gitignore`
2. **Use hardware wallets**: For mainnet deployments
3. **Verify contracts**: Always verify on Etherscan
4. **Test thoroughly**: Deploy to testnet first
5. **Audit contracts**: Consider professional audit for mainnet
6. **Use multisig**: For production contract ownership

---

## Troubleshooting

### Issue: "Insufficient funds"
**Solution**: Get more Sepolia ETH from faucets

### Issue: "Nonce too low"
**Solution**: Wait for previous transaction to confirm, or reset account in wallet

### Issue: "Gas estimation failed"
**Solution**: Check contract code for errors, ensure all parameters are valid

### Issue: "Contract verification failed"
**Solution**: Ensure compiler version matches, constructor args are correct

---

## Next Steps After Deployment

1. Update `README.md` with contract address
2. Update `docs/distribution/README.md` with deployment details
3. Create a verification script for community
4. Share the contract address in announcements
5. Consider mainnet deployment for critical documents

---

## Resources

- **Hardhat**: https://hardhat.org/
- **Foundry**: https://getfoundry.sh/
- **Sepolia Testnet**: https://sepolia.dev/
- **Etherscan Sepolia**: https://sepolia.etherscan.io/
- **Alchemy**: https://www.alchemy.com/
- **Infura**: https://www.infura.io/

---

*Last Updated: December 14, 2025*
