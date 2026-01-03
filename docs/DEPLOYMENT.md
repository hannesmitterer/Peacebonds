# Deployment Guide

## Prerequisites

1. Node.js v18+ installed
2. An Ethereum wallet with some test ETH (for Sepolia) or real ETH (for mainnet)
3. (Optional) IPFS node running or Infura/Pinata API credentials

## Step 1: Install Dependencies

```bash
npm install
```

## Step 2: Compile Smart Contract

```bash
npm run compile
```

This will:
- Compile `PeaceBondAnchor.sol`
- Generate artifacts in `artifacts/` directory
- Create TypeChain types

## Step 3: Build TypeScript

```bash
npm run build
```

This will:
- Compile all TypeScript files to JavaScript
- Output to `dist/` directory
- Generate source maps and declarations

## Step 4: Configure Environment

Create `.env` file:

```bash
cp .env.example .env
```

Edit `.env` and add your configuration:

```env
# For Sepolia Testnet
SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
PRIVATE_KEY=your_private_key_here_without_0x_prefix

# For Mainnet (optional)
ETHEREUM_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY

# For Polygon (optional)
POLYGON_RPC_URL=https://polygon-rpc.com

# IPFS Configuration (choose one)
IPFS_API_URL=http://127.0.0.1:5001

# OR use Infura
INFURA_PROJECT_ID=your_project_id
INFURA_PROJECT_SECRET=your_project_secret

# OR use Pinata
PINATA_API_KEY=your_api_key
PINATA_SECRET_KEY=your_secret_key
```

⚠️ **Security Warning**: Never commit your `.env` file! It's already in `.gitignore`.

## Step 5: Deploy Smart Contract

### Option A: Deploy to Sepolia Testnet (Recommended for Testing)

```bash
node dist/scripts/deploy.js
```

The script will:
1. Load contract artifacts
2. Connect to the network specified in `.env`
3. Deploy the contract
4. Output the contract address

**Save the contract address!** You'll need it for all future operations.

Example output:
```
Deploying PeaceBondAnchor contract...
Deploying from address: 0x1234...
✓ PeaceBondAnchor deployed to: 0xABCD...

Save this address to your .env file:
PEACEBOND_CONTRACT_ADDRESS=0xABCD...
```

### Option B: Deploy to Local Hardhat Network (For Development)

Terminal 1 - Start Hardhat node:
```bash
npx hardhat node
```

Terminal 2 - Deploy contract:
```bash
# Update .env to use local network
# SEPOLIA_RPC_URL=http://127.0.0.1:8545
node dist/scripts/deploy.js
```

### Option C: Deploy to Mainnet (Production)

⚠️ **Warning**: This will cost real ETH. Make sure you understand the gas costs.

```bash
# Update .env with mainnet RPC URL and ensure you have enough ETH
node dist/scripts/deploy.js
```

## Step 6: Update .env with Contract Address

Add the deployed contract address to your `.env`:

```env
PEACEBOND_CONTRACT_ADDRESS=0xABCD...
```

## Step 7: Test the Deployment

### Create a Test PeaceBond

```bash
# Create a test manifest
echo "# Test Manifest

This is a test of the PeaceBonds system.

Date: $(date)
" > test-manifest.md

# Create PeaceBond (will auto-generate 3 signers for testing)
node dist/src/cli/index.js create test-manifest.md \
  --contract $PEACEBOND_CONTRACT_ADDRESS \
  --network sepolia
```

### Verify the PeaceBond

```bash
# Use the token ID from the creation output (usually 1 for first PeaceBond)
node dist/src/cli/index.js verify 1 \
  --contract $PEACEBOND_CONTRACT_ADDRESS \
  --network sepolia
```

### Get PeaceBond Details

```bash
node dist/src/cli/index.js get 1 \
  --contract $PEACEBOND_CONTRACT_ADDRESS \
  --network sepolia
```

## Step 8: (Optional) Set Up IPFS

### Option A: Local IPFS Node

```bash
# Install IPFS (if not already installed)
wget https://dist.ipfs.io/go-ipfs/latest/go-ipfs_linux-amd64.tar.gz
tar -xvzf go-ipfs_linux-amd64.tar.gz
cd go-ipfs
sudo bash install.sh

# Initialize and start IPFS
ipfs init
ipfs daemon
```

### Option B: Use Infura IPFS

1. Sign up at https://infura.io/
2. Create a new project
3. Get your Project ID and Project Secret
4. Add to `.env`:
```env
INFURA_PROJECT_ID=your_project_id
INFURA_PROJECT_SECRET=your_project_secret
```

### Option C: Use Pinata

1. Sign up at https://pinata.cloud/
2. Generate API keys
3. Add to `.env`:
```env
PINATA_API_KEY=your_api_key
PINATA_SECRET_KEY=your_secret_key
```

## Troubleshooting

### Contract Deployment Fails

**Error**: "Insufficient funds"
- **Solution**: Add more ETH to your wallet. Check gas prices on https://etherscan.io/gastracker

**Error**: "Nonce too high"
- **Solution**: Reset your wallet's nonce or wait for pending transactions to clear

### IPFS Upload Fails

**Error**: "ECONNREFUSED"
- **Solution**: Make sure IPFS daemon is running: `ipfs daemon`

**Error**: "CORS error"
- **Solution**: Configure IPFS CORS:
```bash
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET"]'
```

### CLI Errors

**Error**: "Cannot find module"
- **Solution**: Run `npm run build` to compile TypeScript

**Error**: "Contract address required"
- **Solution**: Set `PEACEBOND_CONTRACT_ADDRESS` in `.env` or use `--contract` flag

## Production Checklist

Before deploying to production:

- [ ] Test thoroughly on Sepolia testnet
- [ ] Verify contract source code on Etherscan
- [ ] Set up IPFS pinning service (Pinata/Infura)
- [ ] Document contract address publicly
- [ ] Set up monitoring for contract events
- [ ] Create backup of private keys (securely!)
- [ ] Review gas optimization settings
- [ ] Consider multisig for contract ownership

## Verifying Contract on Etherscan

After deployment to mainnet/testnet:

```bash
npx hardhat verify --network sepolia CONTRACT_ADDRESS
```

## Gas Costs (Approximate)

Based on Sepolia testnet:

- Deploy Contract: ~2,500,000 gas (~0.01 ETH on mainnet at 20 gwei)
- Create PeaceBond: ~200,000 gas (~0.004 ETH on mainnet at 20 gwei)
- Verify (read-only): Free (no transaction)
- Get Details (read-only): Free (no transaction)

## Next Steps

1. Read [USAGE.md](USAGE.md) for detailed usage examples
2. Check [API.md](API.md) for programmatic usage
3. See [ARCHITECTURE.md](ARCHITECTURE.md) for system design
4. Create your first real PeaceBond!

## Support

For issues:
- Check existing documentation in `/docs`
- Review SPEC.md for protocol details
- Open an issue on GitHub
