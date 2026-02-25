#!/bin/bash
# VCD-01 Security Monitoring - Deploy Honey Tokens
# Creates decoy endpoints and files to detect intrusion attempts

set -e

echo "==================================="
echo "VCD-01 Honey Token Deployment"
echo "==================================="

HONEY_DIR="/opt/vcd01-honey"
NGINX_CONF="/etc/nginx/conf.d/honey-tokens.conf"
ALERT_SCRIPT="/opt/vcd01-honey/alert.sh"

echo "[1/5] Creating honey token directory..."
mkdir -p $HONEY_DIR/{api,files,logs}

echo "[2/5] Generating decoy endpoints..."
# Generate random UUIDs for decoy endpoints
for i in {1..10}; do
    UUID=$(cat /proc/sys/kernel/random/uuid)
    ENDPOINT="/api/decoy-$UUID"
    
    # Create decoy file
    cat > "$HONEY_DIR/api/decoy-$UUID.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>API Endpoint</title>
</head>
<body>
    <h1>API Response</h1>
    <p>Endpoint: $ENDPOINT</p>
    <p>Status: Active</p>
</body>
</html>
EOF
    
    echo "  - Created decoy: $ENDPOINT"
done

echo "[3/5] Creating alert script..."
cat > $ALERT_SCRIPT << 'EOSCRIPT'
#!/bin/bash
# Alert script for honey token triggers

IP=$1
ENDPOINT=$2
TIMESTAMP=$(date -Iseconds)

# Log the access
echo "[$TIMESTAMP] HONEY_TOKEN_TRIGGERED: IP=$IP Endpoint=$ENDPOINT" >> /var/log/vcd01-security/honey-tokens.log

# Send alert (configure webhook URL)
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
if [ -n "$WEBHOOK_URL" ]; then
    curl -X POST "$WEBHOOK_URL" \
        -H 'Content-Type: application/json' \
        -d "{
            \"text\": \"🚨 Honey Token Triggered\",
            \"attachments\": [{
                \"color\": \"danger\",
                \"fields\": [
                    {\"title\": \"IP Address\", \"value\": \"$IP\", \"short\": true},
                    {\"title\": \"Endpoint\", \"value\": \"$ENDPOINT\", \"short\": true},
                    {\"title\": \"Timestamp\", \"value\": \"$TIMESTAMP\", \"short\": false}
                ]
            }]
        }" 2>/dev/null
fi

# Block the IP for 24 hours
iptables -I INPUT 1 -s $IP -j DROP
echo "  Blocked IP: $IP for 24h"

# Schedule unblock (requires at cron)
echo "iptables -D INPUT -s $IP -j DROP" | at now + 24 hours 2>/dev/null || true
EOSCRIPT

chmod +x $ALERT_SCRIPT

echo "[4/5] Creating Nginx configuration..."
cat > $NGINX_CONF << 'EONFCONF'
# VCD-01 Honey Token Configuration

# Log format for honey tokens
log_format honey_token '$remote_addr - [$time_local] "$request" '
                       '$status $body_bytes_sent "$http_referer" '
                       '"$http_user_agent" HONEY_TOKEN_TRIGGERED';

# Honey token locations
location ~ ^/api/decoy- {
    access_log /var/log/nginx/honey-tokens.log honey_token;
    
    # Execute alert script using Lua (requires lua-nginx-module)
    # Or use log parsing with fail2ban/custom script
    
    root /opt/vcd01-honey;
    try_files $uri $uri.html =404;
    
    # Add header to identify honey token response
    add_header X-Honey-Token "true" always;
}

# Additional decoy endpoints
location /admin {
    access_log /var/log/nginx/honey-tokens.log honey_token;
    return 403 "Forbidden";
}

location /.env {
    access_log /var/log/nginx/honey-tokens.log honey_token;
    return 404;
}

location /backup.sql {
    access_log /var/log/nginx/honey-tokens.log honey_token;
    return 404;
}
EONFCONF

echo "[5/5] Setting up log monitoring..."
cat > /etc/cron.d/honey-token-monitor << 'EOCRON'
# Monitor honey token access logs
* * * * * root /opt/vcd01-honey/monitor-logs.sh
EOCRON

# Create log monitoring script
cat > /opt/vcd01-honey/monitor-logs.sh << 'EOMONITOR'
#!/bin/bash
# Monitor honey token logs and trigger alerts

LOG_FILE="/var/log/nginx/honey-tokens.log"
PROCESSED_FILE="/var/log/vcd01-security/honey-processed.log"

if [ ! -f "$LOG_FILE" ]; then
    exit 0
fi

# Get new lines since last check
if [ -f "$PROCESSED_FILE" ]; then
    LAST_LINE=$(wc -l < "$PROCESSED_FILE")
else
    LAST_LINE=0
fi

# Process new log entries
tail -n +$((LAST_LINE + 1)) "$LOG_FILE" | while read line; do
    # Extract IP address
    IP=$(echo "$line" | awk '{print $1}')
    # Extract endpoint
    ENDPOINT=$(echo "$line" | grep -oP '"\K[^"]*' | head -1)
    
    if [ -n "$IP" ] && [ -n "$ENDPOINT" ]; then
        /opt/vcd01-honey/alert.sh "$IP" "$ENDPOINT"
    fi
done

# Update processed count
wc -l < "$LOG_FILE" > "$PROCESSED_FILE"
EOMONITOR

chmod +x /opt/vcd01-honey/monitor-logs.sh

echo ""
echo "✓ Honey tokens deployed successfully"
echo ""
echo "Configuration:"
echo "  - Honey directory: $HONEY_DIR"
echo "  - Nginx config: $NGINX_CONF"
echo "  - Alert script: $ALERT_SCRIPT"
echo ""
echo "Next steps:"
echo "  1. Reload Nginx: sudo nginx -s reload"
echo "  2. Set SLACK_WEBHOOK_URL environment variable for alerts"
echo "  3. Test with: curl http://localhost/api/decoy-test"
echo ""
