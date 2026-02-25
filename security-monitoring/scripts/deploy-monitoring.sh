#!/bin/bash
# VCD-01 Security Monitoring - Main Deployment Script

set -e

echo "========================================="
echo "VCD-01 Security Monitoring Deployment"
echo "========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}" 
   exit 1
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

echo "Base directory: $BASE_DIR"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

echo "[Step 1/6] Checking prerequisites..."
MISSING_DEPS=()

for cmd in zeek suricata iptables python3 nginx; do
    if ! command_exists $cmd; then
        MISSING_DEPS+=($cmd)
        print_error "Missing: $cmd"
    else
        print_status "Found: $cmd"
    fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo ""
    print_warning "Missing dependencies: ${MISSING_DEPS[*]}"
    echo "Install with:"
    echo "  sudo apt-get install -y ${MISSING_DEPS[*]}"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "[Step 2/6] Creating log directories..."
mkdir -p /var/log/vcd01-security
mkdir -p /var/log/zeek
mkdir -p /var/log/suricata
print_status "Log directories created"

echo ""
echo "[Step 3/6] Deploying Zeek configuration..."
if command_exists zeek; then
    ZEEK_DIR="/opt/zeek/share/zeek/site"
    if [ -d "$ZEEK_DIR" ]; then
        cp "$BASE_DIR/configs/zeek/suspicious-ips.zeek" "$ZEEK_DIR/" 2>/dev/null || print_warning "Could not copy Zeek config"
        echo "@load suspicious-ips" >> "$ZEEK_DIR/local.zeek" 2>/dev/null || print_warning "Could not update local.zeek"
        print_status "Zeek configuration deployed"
    else
        print_warning "Zeek site directory not found: $ZEEK_DIR"
    fi
else
    print_warning "Zeek not installed, skipping configuration"
fi

echo ""
echo "[Step 4/6] Setting up rate limiting..."
if [ -f "$SCRIPT_DIR/setup-rate-limiting.sh" ]; then
    bash "$SCRIPT_DIR/setup-rate-limiting.sh"
else
    print_warning "Rate limiting script not found"
fi

echo ""
echo "[Step 5/6] Deploying honey tokens..."
if [ -f "$SCRIPT_DIR/deploy-honey-tokens.sh" ]; then
    bash "$SCRIPT_DIR/deploy-honey-tokens.sh"
else
    print_warning "Honey token script not found"
fi

echo ""
echo "[Step 6/6] Creating systemd service..."
cat > /etc/systemd/system/vcd01-security.service << 'EOSERVICE'
[Unit]
Description=VCD-01 Security Monitoring Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/vcd01-security/monitor.py
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOSERVICE

systemctl daemon-reload
print_status "Systemd service created"

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "Suspicious IPs being monitored:"
echo "  - 185.191.171.3"
echo "  - 192.0.78.24"
echo "  - 192.0.78.25"
echo "  - 52.230.152.148"
echo "  - 34.223.12.181"
echo "  - 66.249.66.75"
echo ""
echo "Next steps:"
echo "  1. Configure API keys for threat intel:"
echo "     export OTX_API_KEY='your-key'"
echo "     export ABUSEIPDB_API_KEY='your-key'"
echo "  2. Start monitoring services:"
echo "     sudo bash $SCRIPT_DIR/start-services.sh"
echo "  3. View logs:"
echo "     tail -f /var/log/vcd01-security/alerts.log"
echo ""
