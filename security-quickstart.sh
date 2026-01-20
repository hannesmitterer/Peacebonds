#!/bin/bash
#
# PeaceBonds Security Features - Quick Start Script
# This script helps you get started with the security features quickly
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   print_error "Please do not run this script as root (sudo will be used when needed)"
   exit 1
fi

print_header "PeaceBonds Security Features - Quick Start"
echo ""
print_info "This script will help you set up the security features."
echo ""

# Check dependencies
print_header "Checking Dependencies"

check_command() {
    if command -v $1 &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

MISSING_DEPS=0

check_command "python3" || MISSING_DEPS=1
check_command "docker" || MISSING_DEPS=1
check_command "docker-compose" || MISSING_DEPS=1
check_command "gpg" || MISSING_DEPS=1
check_command "curl" || MISSING_DEPS=1

if [ $MISSING_DEPS -eq 1 ]; then
    echo ""
    print_error "Some dependencies are missing. Please install them first."
    echo "See docs/SECURITY_DEPLOYMENT.md for installation instructions."
    exit 1
fi

echo ""

# Menu
while true; do
    echo ""
    print_header "What would you like to do?"
    echo ""
    echo "1) Deploy Monitoring Stack (Grafana + Loki + Prometheus)"
    echo "2) Setup Forensic Response System"
    echo "3) Configure Encrypted Backups"
    echo "4) Setup Network Hardening (QUIC + TLS 1.3)"
    echo "5) Run All Security Tests"
    echo "6) View Service Status"
    echo "0) Exit"
    echo ""
    read -p "Enter your choice [0-6]: " choice

    case $choice in
        1)
            print_header "Deploying Monitoring Stack"
            
            # Create required directories
            print_info "Creating directories..."
            sudo mkdir -p /var/lib/grafana /var/lib/prometheus /tmp/loki
            
            # Set permissions
            print_info "Setting permissions..."
            sudo chown -R 472:472 /var/lib/grafana 2>/dev/null || true
            sudo chown -R 65534:65534 /var/lib/prometheus 2>/dev/null || true
            
            # Start monitoring stack
            print_info "Starting monitoring stack..."
            docker-compose -f docker-compose.monitoring.yml up -d
            
            echo ""
            print_success "Monitoring stack deployed!"
            echo ""
            echo "Access points:"
            echo "  - Grafana: http://localhost:3000 (admin / peacebonds_monitoring_admin)"
            echo "  - Prometheus: http://localhost:9090"
            echo "  - Loki: http://localhost:3100"
            echo ""
            print_warning "Remember to change the default Grafana password!"
            ;;
            
        2)
            print_header "Setting up Forensic Response System"
            
            # Create directories
            print_info "Creating directories..."
            sudo mkdir -p /etc/peacebonds /var/log/peacebonds
            
            # Copy configuration
            print_info "Copying configuration..."
            sudo cp security/forensics/forensic-config.json /etc/peacebonds/
            
            # Ask if user wants to edit config
            read -p "Do you want to edit the configuration now? (y/n): " edit_config
            if [ "$edit_config" = "y" ]; then
                sudo ${EDITOR:-nano} /etc/peacebonds/forensic-config.json
            fi
            
            # Create systemd service
            print_info "Creating systemd service..."
            sudo cat > /tmp/peacebonds-forensic-watcher.service << 'EOF'
[Unit]
Description=PeaceBonds Forensic Log Watcher
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$(pwd)/security/forensics
ExecStart=/usr/bin/python3 $(pwd)/security/forensics/log-watcher.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
            
            sudo cp /tmp/peacebonds-forensic-watcher.service /etc/systemd/system/
            
            # Enable and start service
            print_info "Enabling service..."
            sudo systemctl daemon-reload
            sudo systemctl enable peacebonds-forensic-watcher
            sudo systemctl start peacebonds-forensic-watcher
            
            echo ""
            print_success "Forensic Response System configured!"
            echo ""
            echo "View logs with:"
            echo "  sudo journalctl -u peacebonds-forensic-watcher -f"
            ;;
            
        3)
            print_header "Configuring Encrypted Backups"
            
            # Check if GPG key exists
            if ! gpg --list-keys | grep -q "@"; then
                print_warning "No GPG key found. You need to generate one first."
                read -p "Generate GPG key now? (y/n): " gen_key
                if [ "$gen_key" = "y" ]; then
                    gpg --gen-key
                fi
            fi
            
            # Get GPG key email
            print_info "Available GPG keys:"
            gpg --list-keys | grep -E "uid|@" || true
            echo ""
            read -p "Enter the email address of the GPG key to use: " gpg_email
            
            # Create backup configuration
            print_info "Creating backup configuration..."
            sudo mkdir -p /etc/peacebonds
            sudo cp security/backups/backup-config.json /etc/peacebonds/
            
            # Update GPG recipient
            print_info "Updating configuration..."
            sudo sed -i "s/peacebonds@example.com/$gpg_email/g" /etc/peacebonds/backup-config.json
            
            # Create backup directories
            sudo mkdir -p /var/backups/peacebonds
            sudo mkdir -p /var/lib/peacebonds/data
            
            # Test backup
            read -p "Run test backup now? (y/n): " test_backup
            if [ "$test_backup" = "y" ]; then
                print_info "Running test backup..."
                python3 security/backups/ipfs-backup.py backup
            fi
            
            # Setup cron
            read -p "Setup daily automated backups? (y/n): " setup_cron
            if [ "$setup_cron" = "y" ]; then
                (crontab -l 2>/dev/null; echo "0 2 * * * /usr/bin/python3 $(pwd)/security/backups/ipfs-backup.py backup >> /var/log/peacebonds/backup-cron.log 2>&1") | crontab -
                print_success "Daily backup scheduled for 2 AM"
            fi
            
            echo ""
            print_success "Encrypted Backups configured!"
            ;;
            
        4)
            print_header "Setting up Network Hardening"
            
            cd security/network-hardening
            
            # Run setup script
            print_info "Running QUIC setup script..."
            sudo ./setup-quic.sh
            
            cd ../..
            
            echo ""
            print_success "Network Hardening configured!"
            echo ""
            print_warning "Self-signed certificates were created for testing."
            print_warning "Replace with proper CA-signed certificates for production!"
            ;;
            
        5)
            print_header "Running Security Tests"
            
            print_info "Testing monitoring stack..."
            curl -s http://localhost:9090/api/v1/targets > /dev/null && print_success "Prometheus is running" || print_error "Prometheus is not accessible"
            curl -s http://localhost:3100/ready > /dev/null && print_success "Loki is running" || print_error "Loki is not accessible"
            curl -s http://localhost:3000/api/health > /dev/null && print_success "Grafana is running" || print_error "Grafana is not accessible"
            
            print_info "Checking forensic watcher..."
            sudo systemctl is-active --quiet peacebonds-forensic-watcher && print_success "Forensic watcher is running" || print_warning "Forensic watcher is not running"
            
            print_info "Checking IPFS..."
            ipfs id > /dev/null 2>&1 && print_success "IPFS is running" || print_warning "IPFS is not running"
            
            print_info "Checking GPG..."
            gpg --list-keys > /dev/null 2>&1 && print_success "GPG is configured" || print_warning "No GPG keys found"
            
            echo ""
            print_success "Tests completed!"
            ;;
            
        6)
            print_header "Service Status"
            
            echo ""
            print_info "Docker Services:"
            docker-compose -f docker-compose.monitoring.yml ps
            
            echo ""
            print_info "Forensic Watcher:"
            sudo systemctl status peacebonds-forensic-watcher --no-pager || true
            
            echo ""
            print_info "IPFS:"
            ipfs id 2>&1 | head -5 || print_warning "IPFS not running"
            ;;
            
        0)
            print_info "Exiting..."
            exit 0
            ;;
            
        *)
            print_error "Invalid choice. Please enter a number between 0 and 6."
            ;;
    esac
done
