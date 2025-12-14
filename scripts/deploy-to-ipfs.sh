#!/bin/bash
# deploy-to-ipfs.sh - Deploy Euystacio Framework to IPFS
# Version: 1.0
# Usage: ./scripts/deploy-to-ipfs.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FRAMEWORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IPFS_DIR="${FRAMEWORK_DIR}/.ipfs-staging"
CID_REGISTRY="${FRAMEWORK_DIR}/docs/ipfs/CID_REGISTRY.md"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Euystacio Framework - IPFS Deployment Script        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if IPFS is installed
echo -e "${YELLOW}[1/7] Checking IPFS installation...${NC}"
if ! command -v ipfs &> /dev/null; then
    echo -e "${RED}✗ IPFS is not installed${NC}"
    echo -e "${YELLOW}Please install IPFS:${NC}"
    echo -e "  wget https://dist.ipfs.tech/kubo/v0.24.0/kubo_v0.24.0_linux-amd64.tar.gz"
    echo -e "  tar -xvzf kubo_v0.24.0_linux-amd64.tar.gz"
    echo -e "  cd kubo && sudo bash install.sh"
    exit 1
fi
echo -e "${GREEN}✓ IPFS is installed: $(ipfs version --number)${NC}"

# Check if IPFS daemon is running
echo -e "${YELLOW}[2/7] Checking IPFS daemon status...${NC}"
if ! ipfs id &> /dev/null; then
    echo -e "${RED}✗ IPFS daemon is not running${NC}"
    echo -e "${YELLOW}Please start the IPFS daemon:${NC}"
    echo -e "  ipfs daemon"
    echo -e "${YELLOW}Or run this script with auto-start (requires manual stop later):${NC}"
    echo -e "  IPFS_AUTO_START=true ./scripts/deploy-to-ipfs.sh"
    
    if [ "$IPFS_AUTO_START" = "true" ]; then
        echo -e "${YELLOW}Starting IPFS daemon in background...${NC}"
        ipfs daemon &
        IPFS_PID=$!
        sleep 5
        echo -e "${GREEN}✓ IPFS daemon started (PID: $IPFS_PID)${NC}"
    else
        exit 1
    fi
else
    echo -e "${GREEN}✓ IPFS daemon is running${NC}"
fi

# Prepare staging directory
echo -e "${YELLOW}[3/7] Preparing content for IPFS...${NC}"
rm -rf "$IPFS_DIR"
mkdir -p "$IPFS_DIR"

# Copy framework files
cp -r "${FRAMEWORK_DIR}/docs" "$IPFS_DIR/"
cp "${FRAMEWORK_DIR}/README.md" "$IPFS_DIR/"
cp "${FRAMEWORK_DIR}/package.json" "$IPFS_DIR/"

# Copy source files (excluding node_modules and git)
if [ -d "${FRAMEWORK_DIR}/contracts" ]; then
    cp -r "${FRAMEWORK_DIR}/contracts" "$IPFS_DIR/"
fi

# Create metadata file
cat > "$IPFS_DIR/METADATA.json" << EOF
{
  "name": "Euystacio Framework",
  "version": "1.2",
  "description": "Ethical Singularity - IPFS Distribution",
  "deploymentDate": "$TIMESTAMP",
  "principle": "Never slavery, only love first",
  "components": [
    "Covenant (Law of Equals)",
    "Technical Architecture",
    "Governance Model",
    "Implementation Roadmap",
    "IPFS Distribution Guide",
    "Community Resources",
    "Smart Contracts",
    "Deployment Scripts"
  ],
  "license": "Open Source - For Humanity",
  "contact": "https://github.com/hannesmitterer/Peacebonds"
}
EOF

echo -e "${GREEN}✓ Content prepared in: $IPFS_DIR${NC}"

# Calculate individual file CIDs
echo -e "${YELLOW}[4/7] Calculating individual file CIDs...${NC}"
declare -A FILE_CIDS

# Ensure we have files to process
if [ -d "$IPFS_DIR/docs/framework" ]; then
    for file in "$IPFS_DIR/docs/framework"/*.md; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            cid=$(ipfs add --only-hash -q "$file")
            FILE_CIDS["$filename"]="$cid"
            echo -e "  ${BLUE}$filename${NC} → ${GREEN}$cid${NC}"
        fi
    done
    
    # Verify we found files
    if [ ${#FILE_CIDS[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠ No markdown files found in framework directory${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Framework docs directory not found${NC}"
fi

# Add complete framework to IPFS
echo -e "${YELLOW}[5/7] Adding framework to IPFS...${NC}"
echo -e "${BLUE}This may take a few moments...${NC}"

ROOT_CID=$(ipfs add -r -q "$IPFS_DIR" | tail -n 1)

if [ -z "$ROOT_CID" ]; then
    echo -e "${RED}✗ Failed to add content to IPFS${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Framework added to IPFS${NC}"
echo -e "${GREEN}✓ Root CID: ${ROOT_CID}${NC}"

# Verify content
echo -e "${YELLOW}[6/7] Verifying content...${NC}"
ipfs pin ls "$ROOT_CID" &> /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Content is pinned locally${NC}"
else
    echo -e "${YELLOW}⚠ Pinning content...${NC}"
    ipfs pin add "$ROOT_CID"
    echo -e "${GREEN}✓ Content pinned${NC}"
fi

# Generate CID registry
echo -e "${YELLOW}[7/7] Generating CID registry...${NC}"

cat > "$CID_REGISTRY" << EOF
# IPFS Content Identifier Registry

## Euystacio Framework - CID Catalog

**Generated:** $TIMESTAMP  
**Root CID:** \`$ROOT_CID\`  
**IPFS Version:** $(ipfs version --number)

---

## Quick Access

### Root Directory

\`\`\`
ipfs://$ROOT_CID
\`\`\`

**HTTP Gateways:**
- https://ipfs.io/ipfs/$ROOT_CID
- https://cloudflare-ipfs.com/ipfs/$ROOT_CID
- https://dweb.link/ipfs/$ROOT_CID
- https://gateway.pinata.cloud/ipfs/$ROOT_CID

---

## Individual Documents

### Framework Documentation

| Document | CID | Gateway Link |
|----------|-----|--------------|
EOF

# Only add rows if we have CIDs
if [ ${#FILE_CIDS[@]} -gt 0 ]; then
    for filename in "${!FILE_CIDS[@]}"; do
        cid="${FILE_CIDS[$filename]}"
        echo "| $filename | \`$cid\` | [View](https://ipfs.io/ipfs/$cid) |" >> "$CID_REGISTRY"
    done
else
    echo "| (No individual files) | - | - |" >> "$CID_REGISTRY"
fi

cat >> "$CID_REGISTRY" << EOF

---

## Verification

### Command Line

\`\`\`bash
# Get entire framework (replace <ROOT-CID> with actual CID from blockchain)
ipfs get <ROOT-CID> -o euystacio-framework

# Get specific document (replace <COVENANT-CID> with actual CID)
ipfs cat <COVENANT-CID> > COVENANT.md

# Verify integrity (should match ROOT-CID from above)
ipfs add --only-hash -r euystacio-framework
\`\`\`

### Web Browser

1. Install [IPFS Companion](https://github.com/ipfs/ipfs-companion)
2. Navigate to: \`ipfs://$ROOT_CID\`
3. Or use gateway: https://ipfs.io/ipfs/$ROOT_CID

---

## Pinning Services

### Pinata

\`\`\`bash
curl -X POST "https://api.pinata.cloud/pinning/pinByHash" \\
  -H "pinata_api_key: YOUR_API_KEY" \\
  -H "pinata_secret_api_key: YOUR_SECRET_KEY" \\
  -H "Content-Type: application/json" \\
  -d '{"hashToPin":"$ROOT_CID","pinataMetadata":{"name":"Euystacio Framework v1.2"}}'
\`\`\`

### Web3.Storage

\`\`\`bash
# Using w3cli
w3 put $IPFS_DIR --name "Euystacio Framework"
\`\`\`

---

## Deployment History

| Version | Date | Root CID | Notes |
|---------|------|----------|-------|
| 1.2 | $TIMESTAMP | \`$ROOT_CID\` | Initial IPFS deployment |

---

## Metadata

\`\`\`json
$(cat "$IPFS_DIR/METADATA.json")
\`\`\`

---

## Next Steps

1. **Pin to services**: Run \`./scripts/pin-to-services.sh\`
2. **Anchor on blockchain**: Run \`./scripts/deploy-blockchain-anchor.sh\`
3. **Verify gateways**: Run \`./scripts/check-gateways.sh\`
4. **Share with community**: Announce on social media

---

**Last Updated:** $TIMESTAMP  
**Script Version:** 1.0
EOF

echo -e "${GREEN}✓ CID registry generated: $CID_REGISTRY${NC}"

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Deployment Summary                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Root CID:${NC} $ROOT_CID"
echo ""
echo -e "${YELLOW}Access URLs:${NC}"
echo -e "  • https://ipfs.io/ipfs/$ROOT_CID"
echo -e "  • https://cloudflare-ipfs.com/ipfs/$ROOT_CID"
echo -e "  • ipfs://$ROOT_CID"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Test gateway access (takes ~1 minute for propagation)"
echo -e "  2. Pin to services: ${BLUE}./scripts/pin-to-services.sh${NC}"
echo -e "  3. Anchor on blockchain: ${BLUE}./scripts/deploy-blockchain-anchor.sh${NC}"
echo ""
echo -e "${GREEN}✓ Deployment complete!${NC}"
echo ""

# If we started the daemon, remind to stop it
if [ -n "$IPFS_PID" ]; then
    echo -e "${YELLOW}⚠ Remember to stop the IPFS daemon when done:${NC}"
    echo -e "  kill $IPFS_PID"
    echo ""
fi

# Save CID to file for other scripts
echo "$ROOT_CID" > "${FRAMEWORK_DIR}/.ipfs-root-cid"

exit 0
