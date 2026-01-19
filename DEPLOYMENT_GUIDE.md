# Deployment Guide - Sepolia Testnet

This guide explains how to deploy the PeaceBondAnchor contract to the Sepolia testnet and mint the first PeaceBond.

## Prerequisites

1. **Node.js and npm** installed
2. **MetaMask or similar wallet** with Sepolia testnet ETH
3. **Alchemy API key** (free tier available at [alchemy.com](https://www.alchemy.com))
4. **IPFS access** for uploading manifest and signature files

## Step 1: Environment Setup

1. Copy the example environment file:
```bash
cp .env.example .env
```

2. Edit `.env` and fill in your credentials:
```bash
# Required for Sepolia deployment
ALCHEMY_API_KEY=your_alchemy_api_key_here
PRIVATE_KEY=your_wallet_private_key_here

# Optional - other configurations
SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
```

**Security Note:** Never commit your `.env` file or share your private keys!

## Step 2: Install Dependencies

```bash
npm install
```

## Step 3: Compile Contracts

```bash
npm run compile
```

This compiles the PeaceBondAnchor.sol contract with:
- Solidity version: 0.8.24
- Optimizer: Enabled with 200 runs
- viaIR: Enabled for better gas optimization

## Step 4: Deploy to Sepolia

Run the deployment script:

```bash
npm run deploy:sepolia
```

**Expected Output:**
```
Deploying PeaceBondAnchor contract to Sepolia...

Initiating deployment...

✓ Deployment successful!
─────────────────────────────────────────────────────
Contract Address: 0x...
Treasury Wallet: 0x5d61a4B25034393A37ef9307C8Ba3aE99e49944b
Network: Sepolia
Etherscan: https://sepolia.etherscan.io/address/0x...
─────────────────────────────────────────────────────

✓ Deployment info saved to: deployed_addresses.json
```

The script will:
- Deploy the PeaceBondAnchor contract
- Log the contract address and Etherscan verification link
- Configure the treasury wallet address
- Save all deployment info to `deployed_addresses.json`

## Step 5: Verify Contract on Etherscan (Optional)

You can verify the contract source code on Etherscan:

```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS>
```

## Step 6: Prepare IPFS Content

Before minting a PeaceBond, you need to upload your content to IPFS:

1. **Upload Manifest**: Upload your manifest document (e.g., manifesto.md) to IPFS
   - Get the CID (e.g., `QmYourManifestCID...`)

2. **Upload Signatures**: Upload the signature file to IPFS
   - Get the CID (e.g., `QmYourSignatureCID...`)

### Using Pinata (Recommended)
```bash
# Install Pinata SDK
npm install @pinata/sdk

# Upload files using their web interface or API
```

### Using Local IPFS Node
```bash
# Start IPFS daemon
ipfs daemon

# Add files
ipfs add manifest.md
ipfs add signatures.json
```

## Step 7: Update Minting Script

Edit `scripts/mint_pb001.js` and replace the placeholder CIDs:

```javascript
// Replace these with your actual IPFS CIDs
const manifestCID = 'QmYourManifestCIDHere123456789';
const signatureCID = 'QmYourSignatureCIDHere123456789';
```

## Step 8: Mint PeaceBond #001

Run the minting script:

```bash
npm run mint:pb001
```

**Expected Output:**
```
Minting PeaceBond #001...

Contract Address: 0x...
Network: Sepolia

⚠️  Note: Using placeholder CIDs. Replace with actual IPFS CIDs before production use.
Manifest CID: QmYour...
Signature CID: QmYour...

Invoking anchor() function...
Transaction submitted: 0x...
Waiting for confirmation...

✓ PeaceBond #001 successfully anchored!
─────────────────────────────────────────────────────
Token ID: 1
Transaction Hash: 0x...
Block Number: 12345678
Etherscan: https://sepolia.etherscan.io/tx/0x...
─────────────────────────────────────────────────────

PeaceBond #001 Details:
- Manifest: ipfs://QmYour...
- Signature: ipfs://QmYour...
- Status: Notarized on Sepolia blockchain

✓ PeaceBond info saved to deployed_addresses.json
```

## Step 9: Verify Your PeaceBond

You can verify your PeaceBond in several ways:

1. **On Etherscan**: Visit the transaction URL to see the on-chain record
2. **Via IPFS**: Retrieve the manifest and signatures using the CIDs
3. **Using the Contract**: Call `getAnchor(1)` to retrieve all data

### Using Hardhat Console

```bash
npx hardhat console --network sepolia
```

```javascript
const PeaceBondAnchor = await ethers.getContractFactory('PeaceBondAnchor');
const contract = PeaceBondAnchor.attach('YOUR_CONTRACT_ADDRESS');

// Get anchor data
const anchor = await contract.getAnchor(1);
console.log(anchor);

// Verify CIDs
const isValid = await contract.verify(1, 'YOUR_MANIFEST_CID', 'YOUR_SIGNATURE_CID');
console.log('Valid:', isValid);
```

## Deployment Information File

The `deployed_addresses.json` file stores all deployment and minting information:

```json
{
  "PeaceBondAnchor": {
    "network": "sepolia",
    "contractAddress": "0x...",
    "treasuryWallet": "0x5d61a4B25034393A37ef9307C8Ba3aE99e49944b",
    "deployedAt": "2026-01-19T...",
    "etherscanUrl": "https://sepolia.etherscan.io/address/0x..."
  },
  "firstPeaceBond": {
    "tokenId": "1",
    "manifestCID": "Qm...",
    "signatureCID": "Qm...",
    "transactionHash": "0x...",
    "blockNumber": 12345678,
    "mintedAt": "2026-01-19T..."
  }
}
```

This file can be used for frontend integration and automation.

## Troubleshooting

### Error: Insufficient funds
- Ensure your wallet has enough Sepolia ETH
- Get free Sepolia ETH from faucets:
  - https://sepoliafaucet.com/
  - https://www.alchemy.com/faucets/ethereum-sepolia

### Error: Invalid API key
- Verify your Alchemy API key is correct
- Ensure you've created a Sepolia app in your Alchemy dashboard

### Error: Private key error
- Make sure your private key is in the correct format:
  - 64 hexadecimal characters (without 0x prefix), OR
  - 66 characters total (with 0x prefix)
  - Example: `0x1234567890abcdef...` (66 chars) or `1234567890abcdef...` (64 chars)
- Never share your private key

### Error: Contract not found
- Ensure you've run the deployment script first
- Check that `deployed_addresses.json` exists and contains the contract address

## Security Considerations

1. **Private Keys**: Never commit `.env` files or expose private keys
2. **Gas Prices**: Monitor gas prices before deploying
3. **Contract Verification**: Always verify contracts on Etherscan
4. **IPFS Pinning**: Ensure your IPFS content is pinned and available
5. **Testnet First**: Always test on Sepolia before mainnet deployment

## Next Steps

After successful deployment:

1. Verify the contract on Etherscan
2. Integrate the contract address into your frontend
3. Create additional PeaceBonds using the `anchor()` function
4. Share the Etherscan links for transparency

## Support

For issues or questions:
- Check the main [README.md](../README.md)
- Review the [SECURITY_ANALYSIS.md](../SECURITY_ANALYSIS.md)
- Visit the [SPEC.md](../SPEC.md) for protocol details

---

**Important**: This is a testnet deployment guide. For mainnet deployment:
- Use `mainnet` network configuration
- Ensure thorough testing
- Consider professional security audits
- Have sufficient ETH for gas fees
