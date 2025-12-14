#!/bin/bash
# check-gateways.sh - Verify IPFS gateway accessibility
# Version: 1.0
# Usage: ./scripts/check-gateways.sh

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
GATEWAY_LIST="${FRAMEWORK_DIR}/docs/ipfs/GATEWAY_LIST.md"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Euystacio Framework - Gateway Verification          ║${NC}"
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

# Public IPFS gateways
declare -a GATEWAYS=(
    "https://ipfs.io/ipfs/"
    "https://cloudflare-ipfs.com/ipfs/"
    "https://dweb.link/ipfs/"
    "https://gateway.pinata.cloud/ipfs/"
    "https://w3s.link/ipfs/"
    "https://ipfs.filebase.io/ipfs/"
    "https://hardbin.com/ipfs/"
    "https://gateway.ipfs.io/ipfs/"
)

# Function to check gateway
check_gateway() {
    local gateway=$1
    local cid=$2
    local url="${gateway}${cid}"
    
    # Timeout after 10 seconds
    # Use portable time measurement (works on Linux and macOS)
    local start_time=$(date +%s)
    local response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>&1)
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local duration_ms=$((duration * 1000))
    
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓${NC} $(printf '%-40s' "$gateway") ${GREEN}OK${NC} (~${duration_ms}ms)"
        return 0
    elif [ "$response" = "429" ]; then
        echo -e "${YELLOW}⚠${NC} $(printf '%-40s' "$gateway") ${YELLOW}Rate Limited${NC}"
        return 1
    elif [ "$response" = "504" ] || [ "$response" = "502" ]; then
        echo -e "${YELLOW}⚠${NC} $(printf '%-40s' "$gateway") ${YELLOW}Gateway Timeout${NC}"
        return 1
    else
        echo -e "${RED}✗${NC} $(printf '%-40s' "$gateway") ${RED}Failed${NC} (HTTP $response)"
        return 1
    fi
}

# Check all gateways
echo -e "${YELLOW}Checking gateway accessibility...${NC}"
echo -e "${BLUE}(This may take a minute)${NC}"
echo ""

WORKING_GATEWAYS=0
TOTAL_GATEWAYS=${#GATEWAYS[@]}

for gateway in "${GATEWAYS[@]}"; do
    if check_gateway "$gateway" "$ROOT_CID"; then
        ((WORKING_GATEWAYS++))
    fi
done

# Generate gateway list document
echo ""
echo -e "${YELLOW}Generating gateway list...${NC}"

cat > "$GATEWAY_LIST" << EOF
# IPFS Gateway List

## Euystacio Framework - Gateway Status

**Last Checked:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")  
**Root CID:** \`$ROOT_CID\`  
**Working Gateways:** $WORKING_GATEWAYS / $TOTAL_GATEWAYS

---

## Verified Gateways

The following gateways have been verified to serve the Euystacio Framework:

EOF

# Re-check and document working gateways
for gateway in "${GATEWAYS[@]}"; do
    url="${gateway}${ROOT_CID}"
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>&1)
    
    if [ "$response" = "200" ]; then
        gateway_name=$(echo "$gateway" | sed 's|https://||' | sed 's|/ipfs/||')
        echo "### ✓ $gateway_name" >> "$GATEWAY_LIST"
        echo "" >> "$GATEWAY_LIST"
        echo "**Status:** Active  " >> "$GATEWAY_LIST"
        echo "**URL:** [$url]($url)" >> "$GATEWAY_LIST"
        echo "" >> "$GATEWAY_LIST"
        echo '```' >> "$GATEWAY_LIST"
        echo "curl $url" >> "$GATEWAY_LIST"
        echo '```' >> "$GATEWAY_LIST"
        echo "" >> "$GATEWAY_LIST"
    fi
done

cat >> "$GATEWAY_LIST" << EOF

---

## Usage Examples

### Command Line

\`\`\`bash
# Download entire framework
curl https://ipfs.io/ipfs/$ROOT_CID -o framework.tar.gz

# View specific file
curl https://cloudflare-ipfs.com/ipfs/$ROOT_CID/docs/framework/COVENANT.md

# Use wget
wget https://dweb.link/ipfs/$ROOT_CID
\`\`\`

### Browser

Simply click any of the verified gateway URLs above, or:

1. Install [IPFS Companion](https://github.com/ipfs/ipfs-companion)
2. Navigate to: \`ipfs://$ROOT_CID\`

### JavaScript

\`\`\`javascript
const cid = '$ROOT_CID';
const gateway = 'https://ipfs.io/ipfs/';

fetch(gateway + cid)
  .then(response => response.text())
  .then(data => console.log(data));
\`\`\`

### Python

\`\`\`python
import requests

cid = '$ROOT_CID'
gateway = 'https://ipfs.io/ipfs/'

response = requests.get(gateway + cid)
print(response.text)
\`\`\`

---

## Gateway Selection Tips

1. **Use Cloudflare** for best global performance (CDN)
2. **Use ipfs.io** for official IPFS foundation gateway
3. **Use dweb.link** for web3-native browsing
4. **Use Pinata/W3S** if you're using their pinning services

---

## Troubleshooting

### Gateway Not Loading

**Problem:** Gateway returns 404 or timeout

**Solutions:**
1. Wait 1-2 minutes for content propagation
2. Try a different gateway from the list above
3. Verify CID is correct: \`$ROOT_CID\`
4. Check if gateway is temporarily down

### Slow Loading

**Problem:** Content loads very slowly

**Solutions:**
1. Try Cloudflare gateway (has CDN)
2. Use a gateway closer to your region
3. Download via local IPFS node
4. Check your internet connection

### Verification Failed

**Problem:** Content hash doesn't match

**Solutions:**
1. Re-download from official source
2. Verify blockchain anchor CID
3. Report issue if persists

---

## Add Your Gateway

Running a public IPFS gateway? Pin our content and contact us:

- **GitHub:** https://github.com/hannesmitterer/Peacebonds/issues
- **Email:** ipfs@euystacio.org (future)

We'll add verified community gateways to this list.

---

## Monitoring

We continuously monitor gateway health. Status dashboard (future):

- **Dashboard:** https://euystacio.org/gateway-status
- **RSS Feed:** https://euystacio.org/gateway-status.rss
- **API:** https://api.euystacio.org/v1/gateways

---

**Last Updated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")  
**Script Version:** 1.0  
**Next Check:** Automated daily
EOF

echo -e "${GREEN}✓ Gateway list generated: $GATEWAY_LIST${NC}"

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Verification Summary                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

PERCENTAGE=$((WORKING_GATEWAYS * 100 / TOTAL_GATEWAYS))

echo -e "${YELLOW}Working Gateways:${NC} $WORKING_GATEWAYS / $TOTAL_GATEWAYS ($PERCENTAGE%)"
echo ""

if [ $WORKING_GATEWAYS -ge 5 ]; then
    echo -e "${GREEN}✓ Excellent gateway coverage!${NC}"
    echo -e "${GREEN}✓ Content is highly accessible${NC}"
    STATUS="excellent"
elif [ $WORKING_GATEWAYS -ge 3 ]; then
    echo -e "${GREEN}✓ Good gateway coverage${NC}"
    echo -e "${YELLOW}⚠ Some gateways may be slow or unreachable${NC}"
    STATUS="good"
elif [ $WORKING_GATEWAYS -ge 1 ]; then
    echo -e "${YELLOW}⚠ Limited gateway coverage${NC}"
    echo -e "${YELLOW}⚠ Wait a few minutes and re-check${NC}"
    STATUS="limited"
else
    echo -e "${RED}✗ No gateways accessible${NC}"
    echo -e "${RED}✗ Content may not be propagated yet${NC}"
    echo -e "${YELLOW}Wait 5-10 minutes and try again${NC}"
    STATUS="none"
fi

echo ""
echo -e "${YELLOW}Primary Access URL:${NC}"
echo -e "  ${BLUE}https://ipfs.io/ipfs/$ROOT_CID${NC}"
echo ""

if [ "$STATUS" = "excellent" ] || [ "$STATUS" = "good" ]; then
    echo -e "${YELLOW}Next Step:${NC}"
    echo -e "  Anchor on blockchain: ${BLUE}./scripts/deploy-blockchain-anchor.sh${NC}"
    echo ""
fi

exit 0
