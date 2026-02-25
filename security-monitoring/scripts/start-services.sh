#!/bin/bash
# VCD-01 Security Monitoring - Start Services

set -e

echo "========================================="
echo "Starting VCD-01 Security Services"
echo "========================================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root" 
   exit 1
fi

# Start Zeek
if command -v zeekctl &> /dev/null; then
    echo "[1/4] Starting Zeek..."
    zeekctl deploy 2>/dev/null || zeekctl start 2>/dev/null || echo "  Warning: Could not start Zeek"
    zeekctl status
else
    echo "[1/4] Zeek not installed, skipping..."
fi

echo ""
# Start Suricata  
if command -v suricata &> /dev/null; then
    echo "[2/4] Starting Suricata..."
    systemctl start suricata 2>/dev/null || echo "  Warning: Could not start Suricata"
    systemctl status suricata --no-pager | head -3
else
    echo "[2/4] Suricata not installed, skipping..."
fi

echo ""
# Start Nginx (for honey tokens)
if command -v nginx &> /dev/null; then
    echo "[3/4] Starting Nginx..."
    systemctl start nginx 2>/dev/null || echo "  Warning: Could not start Nginx"
    nginx -t 2>&1 | grep successful && echo "  ✓ Nginx configuration OK"
else
    echo "[3/4] Nginx not installed, skipping..."
fi

echo ""
# Verify iptables rules
echo "[4/4] Verifying iptables rules..."
if iptables -L SUSPICIOUS_IPS -n &>/dev/null; then
    echo "  ✓ SUSPICIOUS_IPS chain exists"
    RULE_COUNT=$(iptables -L SUSPICIOUS_IPS -n | grep -c "^LOG\|^DROP" || echo "0")
    echo "  ✓ $RULE_COUNT active rules"
else
    echo "  ✗ SUSPICIOUS_IPS chain not found"
    echo "  Run: sudo bash scripts/setup-rate-limiting.sh"
fi

echo ""
echo "========================================="
echo "Service Status Summary"
echo "========================================="
echo ""

# Check service status
services=("zeek" "suricata" "nginx")
for service in "${services[@]}"; do
    if systemctl is-active --quiet $service 2>/dev/null; then
        echo "✓ $service: running"
    else
        echo "✗ $service: not running"
    fi
done

echo ""
echo "Log files:"
echo "  - Zeek: /var/log/zeek/"
echo "  - Suricata: /var/log/suricata/"
echo "  - Honey tokens: /var/log/vcd01-security/honey-tokens.log"
echo "  - Security alerts: /var/log/vcd01-security/alerts.log"
echo ""
echo "Monitor with:"
echo "  tail -f /var/log/vcd01-security/alerts.log"
echo ""
