#!/bin/bash
# pin-to-services.sh - Pin Euystacio Framework to multiple IPFS services
# Version: 1.0
# Usage: ./scripts/pin-to-services.sh

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

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Euystacio Framework - Multi-Service Pinning         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if CID file exists
if [ ! -f "$CID_FILE" ]; then
    echo -e "${RED}✗ Root CID not found${NC}"
    echo -e "${YELLOW}Please run deployment script first:${NC}"
    echo -e "  ./scripts/deploy-to-ipfs.sh"
    exit 1
fi

ROOT_CID=$(cat "$CID_FILE")
echo -e "${GREEN}Root CID:${NC} $ROOT_CID"
echo ""

# Function to pin to Pinata
pin_to_pinata() {
    echo -e "${YELLOW}[1/3] Pinning to Pinata...${NC}"
    
    if [ -z "$PINATA_API_KEY" ] || [ -z "$PINATA_SECRET_KEY" ]; then
        echo -e "${YELLOW}⚠ Pinata credentials not set${NC}"
        echo -e "${BLUE}Set environment variables:${NC}"
        echo -e "  export PINATA_API_KEY='your_api_key'"
        echo -e "  export PINATA_SECRET_KEY='your_secret_key'"
        echo -e "${YELLOW}Skipping Pinata...${NC}"
        return 1
    fi
    
    response=$(curl -s -X POST "https://api.pinata.cloud/pinning/pinByHash" \
        -H "pinata_api_key: $PINATA_API_KEY" \
        -H "pinata_secret_api_key: $PINATA_SECRET_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"hashToPin\":\"$ROOT_CID\",\"pinataMetadata\":{\"name\":\"Euystacio Framework v1.2\",\"keyvalues\":{\"version\":\"1.2\",\"type\":\"framework\",\"date\":\"$(date -u +%Y-%m-%d)\"}}}")
    
    if echo "$response" | grep -q "error"; then
        echo -e "${RED}✗ Pinata pinning failed${NC}"
        echo -e "${RED}Error: $response${NC}"
        return 1
    else
        echo -e "${GREEN}✓ Successfully pinned to Pinata${NC}"
        echo -e "${BLUE}Dashboard: https://app.pinata.cloud/pinmanager${NC}"
        return 0
    fi
}

# Function to pin to Web3.Storage
pin_to_web3storage() {
    echo -e "${YELLOW}[2/3] Pinning to Web3.Storage...${NC}"
    
    if [ -z "$WEB3_STORAGE_TOKEN" ]; then
        echo -e "${YELLOW}⚠ Web3.Storage token not set${NC}"
        echo -e "${BLUE}Get a token from: https://web3.storage${NC}"
        echo -e "  export WEB3_STORAGE_TOKEN='your_token'"
        echo -e "${YELLOW}Skipping Web3.Storage...${NC}"
        return 1
    fi
    
    # Check if w3cli is installed
    if ! command -v w3 &> /dev/null; then
        echo -e "${YELLOW}Installing w3cli...${NC}"
        npm install -g @web3-storage/w3cli 2>&1 | grep -v "npm WARN" || true
    fi
    
    # Upload via API
    if [ -d "${FRAMEWORK_DIR}/.ipfs-staging" ]; then
        echo -e "${BLUE}Uploading content via Web3.Storage...${NC}"
        
        # Create CAR file from directory
        response=$(curl -s -X POST "https://api.web3.storage/upload" \
            -H "Authorization: Bearer $WEB3_STORAGE_TOKEN" \
            -H "X-NAME: Euystacio Framework v1.2" \
            --data-binary "@${FRAMEWORK_DIR}/.ipfs-staging.car" 2>&1 || echo "error")
        
        if echo "$response" | grep -q "error"; then
            echo -e "${YELLOW}⚠ Web3.Storage API upload failed, trying CLI...${NC}"
            
            # Fallback to CLI upload
            w3 token set "$WEB3_STORAGE_TOKEN" &> /dev/null
            w3_cid=$(w3 put "${FRAMEWORK_DIR}/.ipfs-staging" --name "Euystacio Framework v1.2" 2>&1 | grep -oP 'bafybei[a-z0-9]+' | head -1 || echo "")
            
            if [ -n "$w3_cid" ]; then
                echo -e "${GREEN}✓ Successfully uploaded to Web3.Storage${NC}"
                echo -e "${BLUE}CID: $w3_cid${NC}"
                return 0
            else
                echo -e "${YELLOW}⚠ Web3.Storage upload failed${NC}"
                return 1
            fi
        else
            echo -e "${GREEN}✓ Successfully pinned to Web3.Storage${NC}"
            echo -e "${BLUE}Dashboard: https://console.web3.storage${NC}"
            return 0
        fi
    else
        echo -e "${YELLOW}⚠ Staging directory not found${NC}"
        return 1
    fi
}

# Function to pin to NFT.Storage
pin_to_nftstorage() {
    echo -e "${YELLOW}[3/3] Pinning to NFT.Storage...${NC}"
    
    if [ -z "$NFT_STORAGE_TOKEN" ]; then
        echo -e "${YELLOW}⚠ NFT.Storage token not set (optional)${NC}"
        echo -e "${BLUE}Get a token from: https://nft.storage${NC}"
        echo -e "  export NFT_STORAGE_TOKEN='your_token'"
        echo -e "${YELLOW}Skipping NFT.Storage...${NC}"
        return 1
    fi
    
    # Pin via API
    response=$(curl -s -X POST "https://api.nft.storage/pins" \
        -H "Authorization: Bearer $NFT_STORAGE_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"cid\":\"$ROOT_CID\",\"name\":\"Euystacio Framework v1.2\"}")
    
    if echo "$response" | grep -q "error"; then
        echo -e "${RED}✗ NFT.Storage pinning failed${NC}"
        echo -e "${RED}Error: $response${NC}"
        return 1
    else
        echo -e "${GREEN}✓ Successfully pinned to NFT.Storage${NC}"
        echo -e "${BLUE}Dashboard: https://nft.storage/files/${NC}"
        return 0
    fi
}

# Execute pinning
PINATA_SUCCESS=0
WEB3_SUCCESS=0
NFT_SUCCESS=0

pin_to_pinata && PINATA_SUCCESS=1 || true
pin_to_web3storage && WEB3_SUCCESS=1 || true
pin_to_nftstorage && NFT_SUCCESS=1 || true

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Pinning Summary                           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

TOTAL_SUCCESS=$((PINATA_SUCCESS + WEB3_SUCCESS + NFT_SUCCESS))

if [ $PINATA_SUCCESS -eq 1 ]; then
    echo -e "${GREEN}✓ Pinata${NC}"
else
    echo -e "${RED}✗ Pinata${NC}"
fi

if [ $WEB3_SUCCESS -eq 1 ]; then
    echo -e "${GREEN}✓ Web3.Storage${NC}"
else
    echo -e "${RED}✗ Web3.Storage${NC}"
fi

if [ $NFT_SUCCESS -eq 1 ]; then
    echo -e "${GREEN}✓ NFT.Storage${NC}"
else
    echo -e "${YELLOW}○ NFT.Storage (optional)${NC}"
fi

echo ""
echo -e "${YELLOW}Services Active:${NC} $TOTAL_SUCCESS / 2 (required)"
echo ""

if [ $TOTAL_SUCCESS -ge 2 ]; then
    echo -e "${GREEN}✓ Sufficient redundancy achieved!${NC}"
    echo ""
    echo -e "${YELLOW}Next Step:${NC}"
    echo -e "  Anchor on blockchain: ${BLUE}./scripts/deploy-blockchain-anchor.sh${NC}"
    echo ""
    exit 0
elif [ $TOTAL_SUCCESS -ge 1 ]; then
    echo -e "${YELLOW}⚠ Only one service active - recommend adding more${NC}"
    echo -e "${YELLOW}Set credentials for additional services and re-run${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ No pinning services configured${NC}"
    echo -e "${YELLOW}Please set at least one service's credentials:${NC}"
    echo ""
    echo -e "${BLUE}Pinata:${NC}"
    echo -e "  export PINATA_API_KEY='your_key'"
    echo -e "  export PINATA_SECRET_KEY='your_secret'"
    echo ""
    echo -e "${BLUE}Web3.Storage:${NC}"
    echo -e "  export WEB3_STORAGE_TOKEN='your_token'"
    echo ""
    exit 1
fi
