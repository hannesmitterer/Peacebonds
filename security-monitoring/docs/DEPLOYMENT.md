# VCD-01 Security Monitoring - Deployment Guide

## Overview

Complete deployment guide for the VCD-01 real-time security monitoring and active defense system.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet Traffic                          │
└───────────────────────────┬─────────────────────────────────┘
                            │
                ┌───────────▼──────────┐
                │   Firewall/Router     │
                │   (iptables rules)    │
                └───────────┬──────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   ┌────▼────┐         ┌────▼────┐        ┌────▼────┐
   │  Zeek   │         │Suricata │        │  eBPF   │
   │Capture  │         │  IDS    │        │ Filter  │
   └────┬────┘         └────┬────┘        └────┬────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                   ┌────────▼────────┐
                   │  Elasticsearch  │
                   │   (Log Store)   │
                   └────────┬────────┘
                            │
                ┌───────────┼───────────┐
                │           │           │
           ┌────▼────┐ ┌────▼────┐ ┌───▼────┐
           │ Kibana  │ │ Alerts  │ │Threat  │
           │Dashboard│ │ Slack   │ │ Intel  │
           └─────────┘ └─────────┘ └────────┘
```

## Prerequisites

### System Requirements

- **OS**: Ubuntu 22.04 LTS or Debian 11+ (recommended)
- **CPU**: 4+ cores
- **RAM**: 8GB minimum (16GB recommended)
- **Disk**: 100GB+ for log storage
- **Network**: Root access to configure iptables/nftables

### Software Dependencies

```bash
# Update package index
sudo apt-get update

# Install core monitoring tools
sudo apt-get install -y \
    zeek \
    zeek-aux \
    suricata \
    iptables \
    iptables-persistent \
    nftables \
    knockd \
    iproute2 \
    nginx \
    nginx-extras \
    python3 \
    python3-pip \
    curl \
    jq \
    at

# Install Elasticsearch & Kibana (optional but recommended)
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt-get update
sudo apt-get install -y elasticsearch kibana

# Install Python dependencies
sudo pip3 install requests elasticsearch python-dotenv
```

### API Keys (Optional)

For threat intelligence integration:

1. **AlienVault OTX**: https://otx.alienvault.com/
   - Create free account
   - Go to Settings → API Integration
   - Copy API key

2. **AbuseIPDB**: https://www.abuseipdb.com/
   - Create free account
   - Go to Account → API
   - Generate API key

## Deployment Steps

### Step 1: Clone Repository

```bash
cd /opt
git clone https://github.com/hannesmitterer/Peacebonds.git
cd Peacebonds/security-monitoring
```

### Step 2: Configure Environment

```bash
# Create environment file
cat > /etc/vcd01-security.env << EOF
# Threat Intelligence API Keys
OTX_API_KEY=your_otx_api_key_here
ABUSEIPDB_API_KEY=your_abuseipdb_key_here

# Alert Webhooks
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR/WEBHOOK/URL

# Elasticsearch Configuration
ELASTICSEARCH_HOST=localhost
ELASTICSEARCH_PORT=9200
ELASTICSEARCH_USER=elastic
ELASTICSEARCH_PASSWORD=changeme

# Monitoring Configuration
LOG_RETENTION_DAYS=90
RATE_LIMIT_REQUESTS=5
RATE_LIMIT_PERIOD=1
EOF

# Secure the file
chmod 600 /etc/vcd01-security.env
```

### Step 3: Run Main Deployment Script

```bash
cd /opt/Peacebonds/security-monitoring
sudo bash scripts/deploy-monitoring.sh
```

This will:
- ✓ Check prerequisites
- ✓ Create log directories
- ✓ Deploy Zeek configuration
- ✓ Set up iptables rate limiting
- ✓ Deploy honey tokens
- ✓ Create systemd service

### Step 4: Configure Elasticsearch (if installed)

```bash
# Create index template
curl -X PUT "localhost:9200/_index_template/vcd01-security" \
  -H 'Content-Type: application/json' \
  -d @configs/elasticsearch/index-template.json

# Verify template
curl -X GET "localhost:9200/_index_template/vcd01-security?pretty"
```

### Step 5: Start Services

```bash
sudo bash scripts/start-services.sh
```

### Step 6: Verify Deployment

```bash
# Check Zeek status
sudo zeekctl status

# Verify iptables rules
sudo iptables -L SUSPICIOUS_IPS -n -v

# Test honey token
curl http://localhost/api/decoy-test

# Check logs
tail -f /var/log/vcd01-security/alerts.log
```

## Configuration Details

### Suspicious IP List

The following IPs are monitored with enhanced surveillance:

| IP Address | Notes |
|------------|-------|
| 185.191.171.3 | High priority monitoring |
| 192.0.78.24 | Medium priority |
| 192.0.78.25 | Medium priority |
| 52.230.152.148 | AWS IP range |
| 34.223.12.181 | AWS IP range |
| 66.249.66.75 | Google bot (verify) |

To modify the list, edit:
- `configs/zeek/suspicious-ips.zeek`
- `scripts/setup-rate-limiting.sh`
- `scripts/threat-intel-sync.py`

### Rate Limiting Configuration

**Default Settings:**
- Rate: 5 requests/second
- Burst: 10 packets
- Drop duration: 300 seconds (5 minutes)

**Modify in:** `scripts/setup-rate-limiting.sh`

### Honey Token Endpoints

**Auto-generated decoy endpoints:**
- `/api/decoy-{uuid}` (10 random UUIDs)

**Static decoys:**
- `/admin`
- `/.env`
- `/backup.sql`

**Add custom endpoints in:** `scripts/deploy-honey-tokens.sh`

### Port Knocking Sequence

**SSH Access:**
- Knock sequence: 7000 → 8000 → 9000
- Timeout: 5 seconds between knocks
- Access duration: 30 seconds

**Test port knocking:**
```bash
# Send knock sequence
for port in 7000 8000 9000; do
    nc -zv your-server-ip $port
    sleep 1
done

# SSH should now be accessible
ssh user@your-server-ip
```

## Monitoring & Alerts

### Elasticsearch Queries

```bash
# View recent suspicious IP activity
curl -X GET "localhost:9200/vcd01-security-*/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "term": { "suspicious": true }
    },
    "sort": [
      { "@timestamp": "desc" }
    ],
    "size": 10
  }'

# Count events by IP
curl -X GET "localhost:9200/vcd01-security-*/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
    "aggs": {
      "by_ip": {
        "terms": { "field": "source_ip" }
      }
    }
  }'
```

### Kibana Dashboards

1. **Access Kibana**: http://localhost:5601
2. **Import dashboards**: Management → Saved Objects → Import
3. **View security events**: Discover → vcd01-security-*

### Threat Intelligence Sync

```bash
# Manual sync
cd /opt/Peacebonds/security-monitoring
source /etc/vcd01-security.env
python3 scripts/threat-intel-sync.py

# Automated sync (cron)
echo "0 */6 * * * root cd /opt/Peacebonds/security-monitoring && source /etc/vcd01-security.env && python3 scripts/threat-intel-sync.py" | sudo tee /etc/cron.d/vcd01-threat-intel
```

## Maintenance

### Log Rotation

```bash
# Configure logrotate
cat > /etc/logrotate.d/vcd01-security << EOF
/var/log/vcd01-security/*.log {
    daily
    rotate 90
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
    sharedscripts
    postrotate
        systemctl reload zeek 2>/dev/null || true
    endscript
}
EOF
```

### Updating Rules

```bash
# Update Zeek rules
cd /opt/Peacebonds/security-monitoring
git pull
sudo cp configs/zeek/suspicious-ips.zeek /opt/zeek/share/zeek/site/
sudo zeekctl deploy

# Update iptables rules
sudo bash scripts/setup-rate-limiting.sh

# Restart services
sudo bash scripts/start-services.sh
```

### Performance Tuning

**For high-traffic environments:**

```bash
# Increase Zeek worker threads
sudo zeekctl config workers 4

# Optimize iptables hashlimit
# Edit scripts/setup-rate-limiting.sh and increase:
# - RATE_LIMIT to 10/sec
# - BURST_LIMIT to 20

# Increase Elasticsearch heap size
sudo sed -i 's/-Xms1g/-Xms4g/' /etc/elasticsearch/jvm.options
sudo sed -i 's/-Xmx1g/-Xmx4g/' /etc/elasticsearch/jvm.options
sudo systemctl restart elasticsearch
```

## Troubleshooting

### Zeek Not Capturing Traffic

```bash
# Check interface
sudo zeekctl status

# Verify network interface
ip addr show

# Update Zeek network config
sudo zeekctl config interface eth0
sudo zeekctl deploy
```

### Iptables Rules Not Working

```bash
# List all rules
sudo iptables -L -n -v

# Check if chain exists
sudo iptables -L SUSPICIOUS_IPS -n -v

# Rebuild rules
sudo bash scripts/setup-rate-limiting.sh

# Make persistent
sudo iptables-save > /etc/iptables/rules.v4
```

### Elasticsearch Connection Failed

```bash
# Check service status
sudo systemctl status elasticsearch

# Verify port
sudo netstat -tlnp | grep 9200

# Check logs
sudo tail -f /var/log/elasticsearch/elasticsearch.log

# Test connection
curl -X GET "localhost:9200/?pretty"
```

### Honey Tokens Not Triggering

```bash
# Check Nginx logs
sudo tail -f /var/log/nginx/honey-tokens.log

# Verify monitoring script
sudo bash -x /opt/vcd01-honey/monitor-logs.sh

# Test alert manually
sudo /opt/vcd01-honey/alert.sh 1.2.3.4 /api/test
```

## Security Considerations

### Data Privacy

- **Payload Capture**: Only first 10KB from suspicious IPs
- **PII Handling**: No user credentials or personal data logged
- **GDPR Compliance**: Enable data retention limits

### Performance Impact

- **CPU Usage**: ~5-10% with Zeek + Suricata
- **Memory**: ~2-4GB for monitoring stack
- **Disk I/O**: ~100MB/hour for logs (varies by traffic)

### False Positives

Some IPs may be legitimate:
- `66.249.66.75`: Google bot (verify and whitelist if needed)
- AWS IPs: May be legitimate services

To whitelist an IP:
```bash
# Remove from suspicious list
sudo iptables -D SUSPICIOUS_IPS -s <IP> -j DROP
# Add whitelist rule
sudo iptables -I INPUT -s <IP> -j ACCEPT
```

## Integration with VCD-01

This security monitoring system integrates with:
- Node monitoring (`scripts/monitoring/node-monitor.js`)
- Peace Contribution Engine
- Governance framework alerts
- QRS security protocol

## Support

- **Documentation**: `/docs/SECURITY.md`
- **Issues**: https://github.com/hannesmitterer/Peacebonds/issues
- **Security**: security@vcd01.network
- **Operations**: ops@vcd01.network

---

**Version**: 1.0  
**Last Updated**: 2026-02-25  
**Maintained By**: VCD-01 Security Team
