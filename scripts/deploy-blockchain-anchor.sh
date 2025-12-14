#!/bin/bash
# deploy-blockchain-anchor.sh - Deploy IPFSAnchor contract to Ethereum
# Version: 1.0
# Usage: ./scripts/deploy-blockchain-anchor.sh [network]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FRAMEWORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CID_FILE="${FRAMEWORK_DIR}/.ipfs-root-cid"
NETWORK="${1:-sepolia}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Euystacio Framework - Blockchain Deployment         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if CID file exists
if [ ! -f "$CID_FILE" ]; then
    echo -e "${RED}✗ Root CID not found${NC}"
    echo -e "${YELLOW}Please run IPFS deployment first:${NC}"
    echo -e "  ./scripts/deploy-to-ipfs.sh"
    exit 1
fi

ROOT_CID=$(cat "$CID_FILE")
echo -e "${GREEN}Root CID to anchor:${NC} $ROOT_CID"
echo -e "${YELLOW}Network:${NC} $NETWORK"
echo ""

# Check prerequisites
echo -e "${YELLOW}[1/6] Checking prerequisites...${NC}"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ Node.js is not installed${NC}"
    echo -e "${YELLOW}Please install Node.js from https://nodejs.org${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Node.js: $(node --version)${NC}"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}✗ npm is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ npm: $(npm --version)${NC}"

# Initialize npm project if needed
if [ ! -f "${FRAMEWORK_DIR}/package.json" ]; then
    echo -e "${YELLOW}Initializing npm project...${NC}"
    cd "$FRAMEWORK_DIR"
    npm init -y > /dev/null 2>&1
fi

# Install dependencies
echo -e "${YELLOW}[2/6] Installing dependencies...${NC}"
cd "$FRAMEWORK_DIR"

if [ ! -d "node_modules/hardhat" ]; then
    echo -e "${BLUE}Installing Hardhat and dependencies...${NC}"
    npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox dotenv 2>&1 | grep -v "npm WARN" || true
fi
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Check for .env file
echo -e "${YELLOW}[3/6] Checking environment configuration...${NC}"

if [ ! -f "${FRAMEWORK_DIR}/.env" ]; then
    echo -e "${YELLOW}Creating .env template...${NC}"
    cat > "${FRAMEWORK_DIR}/.env" << EOF
# Ethereum RPC URLs
SEPOLIA_RPC_URL=https://rpc.sepolia.org
MAINNET_RPC_URL=https://eth.llamarpc.com

# Private key for deployment (DO NOT SHARE)
# PRIVATE_KEY=your_private_key_here

# Etherscan API key for verification
# ETHERSCAN_API_KEY=your_etherscan_api_key
EOF
    
    echo -e "${YELLOW}⚠ .env file created${NC}"
    echo -e "${YELLOW}⚠ Please edit .env and add your PRIVATE_KEY${NC}"
    echo -e "${YELLOW}⚠ Then run this script again${NC}"
    exit 1
fi

# Check if private key is set and valid
if ! grep -q "^PRIVATE_KEY=" "${FRAMEWORK_DIR}/.env" || grep -q "PRIVATE_KEY=your_private_key_here" "${FRAMEWORK_DIR}/.env"; then
    echo -e "${RED}✗ PRIVATE_KEY not configured in .env${NC}"
    echo -e "${YELLOW}Please set PRIVATE_KEY in .env file${NC}"
    exit 1
fi

# Extract and validate private key format
PRIVATE_KEY=$(grep "^PRIVATE_KEY=" "${FRAMEWORK_DIR}/.env" | cut -d '=' -f2 | tr -d '"' | tr -d "'")

# WARNING: For production, use hardware wallets or secure key management
echo -e "${YELLOW}⚠ WARNING: Using private key from .env file${NC}"
echo -e "${YELLOW}⚠ For production, consider using hardware wallets (Ledger/Trezor)${NC}"
echo -e "${YELLOW}⚠ or secure key management services${NC}"
echo ""

# Check if it looks like a valid Ethereum private key (64 hex chars, optionally with 0x prefix)
if ! echo "$PRIVATE_KEY" | grep -qE '^(0x)?[0-9a-fA-F]{64}$'; then
    echo -e "${RED}✗ PRIVATE_KEY format appears invalid${NC}"
    echo -e "${YELLOW}Expected: 64 hexadecimal characters (optionally prefixed with 0x)${NC}"
    echo -e "${YELLOW}Example: 0x1234567890abcdef...${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Environment configured${NC}"

# Create Hardhat config if needed
if [ ! -f "${FRAMEWORK_DIR}/hardhat.config.js" ]; then
    echo -e "${YELLOW}Creating Hardhat configuration...${NC}"
    cat > "${FRAMEWORK_DIR}/hardhat.config.js" << 'EOF'
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "https://rpc.sepolia.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11155111
    },
    mainnet: {
      url: process.env.MAINNET_RPC_URL || "https://eth.llamarpc.com",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 1
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};
EOF
    echo -e "${GREEN}✓ Hardhat config created${NC}"
fi

# Compile contract
echo -e "${YELLOW}[4/6] Compiling smart contract...${NC}"
npx hardhat compile 2>&1 | grep -v "Warning" || true
echo -e "${GREEN}✓ Contract compiled${NC}"

# Create deployment script
echo -e "${YELLOW}[5/6] Creating deployment script...${NC}"

mkdir -p "${FRAMEWORK_DIR}/scripts/hardhat"

cat > "${FRAMEWORK_DIR}/scripts/hardhat/deploy.js" << EOF
const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const rootCID = fs.readFileSync(
    path.join(__dirname, "../../.ipfs-root-cid"),
    "utf8"
  ).trim();

  console.log("Deploying IPFSAnchor contract...");
  console.log("Root CID:", rootCID);
  console.log("Network:", hre.network.name);

  const IPFSAnchor = await hre.ethers.getContractFactory("IPFSAnchor");
  const anchor = await IPFSAnchor.deploy(
    rootCID,
    "Initial deployment of Euystacio Framework v1.2"
  );

  await anchor.waitForDeployment();
  const address = await anchor.getAddress();

  console.log("IPFSAnchor deployed to:", address);

  // Save deployment info
  const deploymentInfo = {
    network: hre.network.name,
    address: address,
    deployer: (await hre.ethers.getSigners())[0].address,
    deployedAt: new Date().toISOString(),
    rootCID: rootCID,
    txHash: anchor.deploymentTransaction().hash,
    blockNumber: anchor.deploymentTransaction().blockNumber
  };

  fs.writeFileSync(
    path.join(__dirname, "../../.deployment-info.json"),
    JSON.stringify(deploymentInfo, null, 2)
  );

  console.log("Deployment info saved to .deployment-info.json");

  // Wait for confirmations
  console.log("Waiting for confirmations...");
  await anchor.deploymentTransaction().wait(5);

  console.log("Deployment complete!");
  console.log("Contract address:", address);
  console.log("Etherscan:", \`https://\${hre.network.name}.etherscan.io/address/\${address}\`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
EOF

echo -e "${GREEN}✓ Deployment script created${NC}"

# Deploy contract
echo -e "${YELLOW}[6/6] Deploying to ${NETWORK}...${NC}"
echo -e "${BLUE}This will cost gas. Make sure you have enough ETH.${NC}"
echo ""

npx hardhat run scripts/hardhat/deploy.js --network "$NETWORK"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Deployment successful!${NC}"
    
    # Read deployment info
    if [ -f "${FRAMEWORK_DIR}/.deployment-info.json" ]; then
        ADDRESS=$(cat "${FRAMEWORK_DIR}/.deployment-info.json" | grep -oP '"address": "\K[^"]+')
        TXHASH=$(cat "${FRAMEWORK_DIR}/.deployment-info.json" | grep -oP '"txHash": "\K[^"]+')
        
        echo ""
        echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║              Deployment Summary                        ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GREEN}Contract Address:${NC} $ADDRESS"
        echo -e "${GREEN}Transaction Hash:${NC} $TXHASH"
        echo -e "${GREEN}Network:${NC} $NETWORK"
        echo ""
        echo -e "${YELLOW}Explorer URLs:${NC}"
        echo -e "  https://${NETWORK}.etherscan.io/address/$ADDRESS"
        echo -e "  https://${NETWORK}.etherscan.io/tx/$TXHASH"
        echo ""
        echo -e "${YELLOW}Next Steps:${NC}"
        echo -e "  1. Verify contract on Etherscan (if API key configured)"
        echo -e "     ${BLUE}npx hardhat verify --network $NETWORK $ADDRESS \"$ROOT_CID\" \"Initial deployment of Euystacio Framework v1.2\"${NC}"
        echo -e "  2. Test contract functions"
        echo -e "     ${BLUE}./scripts/verify-blockchain-anchor.sh${NC}"
        echo -e "  3. Update documentation with contract address"
        echo ""
    fi
else
    echo -e "${RED}✗ Deployment failed${NC}"
    exit 1
fi

exit 0
