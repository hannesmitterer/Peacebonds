#!/bin/bash

# IPFS Documentation Deployment Script
# This script uploads the Euystacio Framework documentation to IPFS
# and pins it on multiple services for redundancy

set -e

echo "================================================"
echo "Euystacio Framework - IPFS Deployment Script"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOCS_DIR="./docs"
OUTPUT_FILE="./scripts/output/ipfs-deployment.json"
MANIFEST_FILE="./scripts/output/manifest.json"

# Create output directory
mkdir -p ./scripts/output

# Check if IPFS is installed
if ! command -v ipfs &> /dev/null; then
    echo -e "${RED}ERROR: IPFS is not installed${NC}"
    echo "Please install IPFS from: https://docs.ipfs.tech/install/"
    echo ""
    echo "Quick install (Linux):"
    echo "  wget https://dist.ipfs.tech/kubo/v0.24.0/kubo_v0.24.0_linux-amd64.tar.gz"
    echo "  tar -xvzf kubo_v0.24.0_linux-amd64.tar.gz"
    echo "  cd kubo"
    echo "  sudo bash install.sh"
    exit 1
fi

echo -e "${GREEN}✓ IPFS is installed${NC}"

# Check if IPFS daemon is running
if ! ipfs swarm peers &> /dev/null; then
    echo -e "${YELLOW}! IPFS daemon is not running${NC}"
    echo "Starting IPFS daemon in the background..."
    
    # Initialize IPFS if not already done
    if [ ! -d ~/.ipfs ]; then
        echo "Initializing IPFS..."
        ipfs init
    fi
    
    # Start daemon in background
    ipfs daemon &
    IPFS_PID=$!
    
    # Wait for daemon to be ready
    echo "Waiting for IPFS daemon to be ready..."
    sleep 5
    
    STARTED_DAEMON=true
else
    echo -e "${GREEN}✓ IPFS daemon is running${NC}"
    STARTED_DAEMON=false
fi

echo ""
echo "================================================"
echo "Step 1: Generating Manifest"
echo "================================================"
echo ""

# Generate manifest
cat > "$MANIFEST_FILE" <<EOF
{
  "name": "Euystacio Framework Documentation",
  "version": "1.0.0",
  "date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "description": "Comprehensive documentation for the Euystacio Framework - AI-driven humanitarian aid system",
  "license": "CC BY-SA 4.0",
  "documents": [
    {
      "name": "Executive Master Document",
      "path": "EUYSTACIO_FRAMEWORK_MASTER.md",
      "description": "Main framework overview and vision"
    },
    {
      "name": "Governance Framework",
      "path": "governance/README.md",
      "description": "Decision-making and community participation"
    },
    {
      "name": "System Architecture",
      "path": "architecture/README.md",
      "description": "Technical implementation details"
    },
    {
      "name": "Implementation Roadmap",
      "path": "roadmap/README.md",
      "description": "Timeline and milestones"
    },
    {
      "name": "Distribution Strategy",
      "path": "distribution/README.md",
      "description": "IPFS and blockchain anchoring"
    },
    {
      "name": "Community Engagement",
      "path": "community/README.md",
      "description": "How to participate and contribute"
    }
  ]
}
EOF

echo -e "${GREEN}✓ Manifest generated: $MANIFEST_FILE${NC}"

echo ""
echo "================================================"
echo "Step 2: Calculating Hashes"
echo "================================================"
echo ""

# Calculate hashes for all markdown files
cd "$DOCS_DIR"
echo "Document Hashes:"
find . -type f -name "*.md" -exec sha256sum {} \; | tee ../scripts/output/hashes.txt
cd ..

echo ""
echo "================================================"
echo "Step 3: Uploading to IPFS"
echo "================================================"
echo ""

# Add manifest to docs
cp "$MANIFEST_FILE" "$DOCS_DIR/manifest.json"

# Upload entire docs directory
echo "Uploading documentation to IPFS..."
IPFS_OUTPUT=$(ipfs add -r "$DOCS_DIR" --quieter)

# Get the root CID (last line)
DOCS_CID=$(echo "$IPFS_OUTPUT" | tail -n 1)

echo -e "${GREEN}✓ Documentation uploaded to IPFS${NC}"
echo "  Root CID: $DOCS_CID"

# Also get the master document CID
MASTER_CID=$(ipfs add "$DOCS_DIR/EUYSTACIO_FRAMEWORK_MASTER.md" --quieter | tail -n 1)
echo "  Master Document CID: $MASTER_CID"

echo ""
echo "================================================"
echo "Step 4: Pinning Locally"
echo "================================================"
echo ""

# Pin the content locally
ipfs pin add "$DOCS_CID" --progress
echo -e "${GREEN}✓ Content pinned locally${NC}"

echo ""
echo "================================================"
echo "Step 5: Generating Deployment Report"
echo "================================================"
echo ""

# Generate deployment report
cat > "$OUTPUT_FILE" <<EOF
{
  "deployment": {
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "version": "1.0.0",
    "network": "IPFS"
  },
  "cids": {
    "docs_root": "$DOCS_CID",
    "master_document": "$MASTER_CID"
  },
  "access_urls": {
    "ipfs_io": "https://ipfs.io/ipfs/$DOCS_CID",
    "dweb_link": "https://dweb.link/ipfs/$DOCS_CID",
    "ipfs_protocol": "ipfs://$DOCS_CID"
  },
  "pinning": {
    "local": "pinned",
    "pinata": "pending - manual action required",
    "web3_storage": "pending - manual action required",
    "cluster": "pending - manual action required"
  },
  "next_steps": [
    "Pin on Pinata using: curl -X POST https://api.pinata.cloud/pinning/pinByHash -H 'pinata_api_key: YOUR_KEY' -d '{\"hashToPin\": \"$DOCS_CID\"}'",
    "Pin on Web3.Storage using: w3 put docs/ --name 'Euystacio Framework v1.0.0'",
    "Update README.md with the CID: $DOCS_CID",
    "Update distribution/README.md with deployment details",
    "Deploy blockchain anchor contract with hash"
  ]
}
EOF

echo -e "${GREEN}✓ Deployment report generated: $OUTPUT_FILE${NC}"

echo ""
echo "================================================"
echo "Deployment Summary"
echo "================================================"
echo ""
echo "Root CID: $DOCS_CID"
echo "Master Document CID: $MASTER_CID"
echo ""
echo "Access URLs:"
echo "  https://ipfs.io/ipfs/$DOCS_CID"
echo "  https://dweb.link/ipfs/$DOCS_CID"
echo "  ipfs://$DOCS_CID"
echo ""
echo "Local Status: Pinned"
echo ""
echo "================================================"
echo "Next Steps"
echo "================================================"
echo ""
echo "1. Update README.md with the CID"
echo "2. Pin on Pinata (see output file for command)"
echo "3. Pin on Web3.Storage (see output file for command)"
echo "4. Deploy blockchain anchor contract"
echo "5. Update distribution/README.md with final details"
echo ""
echo "Deployment details saved to: $OUTPUT_FILE"
echo ""

# Cleanup: Stop daemon if we started it
if [ "$STARTED_DAEMON" = true ]; then
    echo "Stopping IPFS daemon..."
    kill $IPFS_PID 2>/dev/null || true
fi

echo -e "${GREEN}✓ IPFS deployment complete!${NC}"
