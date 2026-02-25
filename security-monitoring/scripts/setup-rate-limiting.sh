#!/bin/bash
# VCD-01 Security Monitoring - Rate Limiting Setup
# Implements iptables rules with hashlimit for suspicious IPs

set -e

echo "==================================="
echo "VCD-01 Rate Limiting Setup"
echo "==================================="

# Suspicious IPs to monitor
SUSPICIOUS_IPS=(
    "185.191.171.3"
    "192.0.78.24"
    "192.0.78.25"
    "52.230.152.148"
    "34.223.12.181"
    "66.249.66.75"
)

# Configuration
RATE_LIMIT="5/sec"
BURST_LIMIT="10"
DROP_DURATION="300"  # 5 minutes in seconds

echo "[1/4] Creating iptables chain for suspicious IPs..."
iptables -N SUSPICIOUS_IPS 2>/dev/null || iptables -F SUSPICIOUS_IPS

echo "[2/4] Configuring rate limiting rules..."
for IP in "${SUSPICIOUS_IPS[@]}"; do
    echo "  - Setting up rate limit for $IP"
    
    # Rate limiting with hashlimit
    iptables -A SUSPICIOUS_IPS -s $IP -m hashlimit \
        --hashlimit-above $RATE_LIMIT \
        --hashlimit-burst $BURST_LIMIT \
        --hashlimit-mode srcip \
        --hashlimit-name suspicious_rate \
        -j LOG --log-prefix "RATE_LIMIT_EXCEEDED: " --log-level 4
    
    iptables -A SUSPICIOUS_IPS -s $IP -m hashlimit \
        --hashlimit-above $RATE_LIMIT \
        --hashlimit-burst $BURST_LIMIT \
        --hashlimit-mode srcip \
        --hashlimit-name suspicious_rate \
        -j DROP
    
    # Log all connections from suspicious IPs
    iptables -A SUSPICIOUS_IPS -s $IP -j LOG \
        --log-prefix "SUSPICIOUS_IP: " --log-level 6
    
    # Accept if under rate limit
    iptables -A SUSPICIOUS_IPS -s $IP -j ACCEPT
done

echo "[3/4] Inserting chain into INPUT..."
# Remove existing rule if present
iptables -D INPUT -j SUSPICIOUS_IPS 2>/dev/null || true
# Insert at beginning of INPUT chain
iptables -I INPUT 1 -j SUSPICIOUS_IPS

echo "[4/4] Saving iptables rules..."
# Save rules (method depends on distribution)
if command -v iptables-save &> /dev/null; then
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || \
    iptables-save > /etc/iptables.rules 2>/dev/null || \
    echo "  Warning: Could not save iptables rules permanently"
fi

echo ""
echo "✓ Rate limiting configured successfully"
echo ""
echo "Configuration:"
echo "  - Rate limit: $RATE_LIMIT"
echo "  - Burst: $BURST_LIMIT packets"
echo "  - Drop duration: $DROP_DURATION seconds"
echo ""
echo "Verify with: sudo iptables -L SUSPICIOUS_IPS -n -v"
echo ""
