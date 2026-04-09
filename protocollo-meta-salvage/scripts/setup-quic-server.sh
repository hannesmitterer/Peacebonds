#!/bin/bash
#
# QUIC Server Setup and Configuration Script
# Implements TLS 1.3 with hardened security settings
#

set -e

# Configuration
INSTALL_DIR="${INSTALL_DIR:-/opt/peacebonds/quic}"
CONFIG_DIR="${CONFIG_DIR:-/etc/peacebonds}"
TLS_DIR="${TLS_DIR:-${CONFIG_DIR}/tls}"
LOG_DIR="${LOG_DIR:-/var/log/peacebonds}"
QUICHE_VERSION="${QUICHE_VERSION:-0.20.0}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $@"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $@"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $@"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $@"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y \
            build-essential \
            cmake \
            git \
            cargo \
            rustc \
            libssl-dev \
            pkg-config \
            curl
    elif command -v yum &> /dev/null; then
        yum install -y \
            gcc \
            gcc-c++ \
            make \
            cmake \
            git \
            cargo \
            rust \
            openssl-devel \
            curl
    else
        log_error "Unsupported package manager"
        exit 1
    fi
    
    log_success "Dependencies installed"
}

# Install quiche (Cloudflare's QUIC implementation)
install_quiche() {
    log_info "Installing quiche QUIC implementation..."
    
    mkdir -p "${INSTALL_DIR}"
    cd /tmp
    
    # Clone quiche
    if [ ! -d "quiche" ]; then
        git clone --recursive https://github.com/cloudflare/quiche.git
    fi
    
    cd quiche
    git checkout "${QUICHE_VERSION}"
    
    # Build quiche
    cargo build --release --features ffi,pkg-config-meta,qlog
    
    # Install
    cp target/release/libquiche.so /usr/local/lib/ || true
    cp target/release/libquiche.a /usr/local/lib/ || true
    cp quiche/include/quiche.h /usr/local/include/ || true
    ldconfig
    
    # Build HTTP/3 server
    cargo build --release --example http3-server
    cp target/release/examples/http3-server "${INSTALL_DIR}/"
    
    log_success "quiche installed successfully"
}

# Generate TLS certificates
generate_certificates() {
    log_info "Generating TLS certificates..."
    
    mkdir -p "${TLS_DIR}"
    cd "${TLS_DIR}"
    
    # Generate CA key and certificate
    if [ ! -f ca.key ]; then
        log_info "Generating CA certificate..."
        openssl genrsa -out ca.key 4096
        openssl req -new -x509 -days 3650 -key ca.key -out ca.crt \
            -subj "/C=US/ST=State/L=City/O=PeaceBonds/CN=PeaceBonds CA"
    fi
    
    # Generate server key and certificate
    if [ ! -f server.key ]; then
        log_info "Generating server certificate..."
        openssl genrsa -out server.key 4096
        openssl req -new -key server.key -out server.csr \
            -subj "/C=US/ST=State/L=City/O=PeaceBonds/CN=peacebonds.io"
        
        # Create extensions file for TLS 1.3
        cat > server.ext << EOF
subjectAltName = DNS:peacebonds.io,DNS:*.peacebonds.io,IP:127.0.0.1
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
basicConstraints = CA:FALSE
EOF
        
        openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
            -CAcreateserial -out server.crt -days 365 \
            -sha384 -extfile server.ext
        
        rm server.csr server.ext
    fi
    
    # Generate client certificate (for mutual TLS)
    if [ ! -f client.key ]; then
        log_info "Generating client certificate..."
        openssl genrsa -out client.key 4096
        openssl req -new -key client.key -out client.csr \
            -subj "/C=US/ST=State/L=City/O=PeaceBonds/CN=PeaceBonds Client"
        
        cat > client.ext << EOF
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
basicConstraints = CA:FALSE
EOF
        
        openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key \
            -CAcreateserial -out client.crt -days 365 \
            -sha384 -extfile client.ext
        
        rm client.csr client.ext
    fi
    
    # Set permissions
    chmod 600 *.key
    chmod 644 *.crt
    
    log_success "TLS certificates generated"
}

# Create systemd service
create_service() {
    log_info "Creating systemd service..."
    
    cat > /etc/systemd/system/peacebonds-quic.service << EOF
[Unit]
Description=PeaceBonds QUIC Server
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=peacebonds
Group=peacebonds
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/http3-server \\
    --listen 0.0.0.0:443 \\
    --cert ${TLS_DIR}/server.crt \\
    --key ${TLS_DIR}/server.key \\
    --root /var/www/peacebonds \\
    --no-retry

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${LOG_DIR}
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictNamespaces=true
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

# Restart policy
Restart=always
RestartSec=10

# Logging
StandardOutput=append:${LOG_DIR}/quic-server.log
StandardError=append:${LOG_DIR}/quic-server-error.log

[Install]
WantedBy=multi-user.target
EOF
    
    # Create user if doesn't exist
    if ! id -u peacebonds &> /dev/null; then
        useradd -r -s /bin/false -d /nonexistent peacebonds
    fi
    
    # Create web root
    mkdir -p /var/www/peacebonds
    chown -R peacebonds:peacebonds /var/www/peacebonds
    
    systemctl daemon-reload
    
    log_success "Systemd service created"
}

# Configure firewall
configure_firewall() {
    log_info "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow 443/udp comment 'QUIC'
        ufw allow 8443/udp comment 'QUIC Alt'
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=443/udp
        firewall-cmd --permanent --add-port=8443/udp
        firewall-cmd --reload
    fi
    
    log_success "Firewall configured"
}

# Disable insecure protocols
disable_insecure_protocols() {
    log_info "Disabling insecure protocols..."
    
    # Disable SSLv2/SSLv3/TLS1.0/TLS1.1 in system-wide crypto policy
    if [ -f /etc/crypto-policies/config ]; then
        sed -i 's/DEFAULT/FUTURE/' /etc/crypto-policies/config || true
        update-crypto-policies || true
    fi
    
    # Create nginx configuration to disable insecure protocols (if nginx is used as frontend)
    if command -v nginx &> /dev/null; then
        cat > /etc/nginx/conf.d/security-hardening.conf << EOF
# Disable insecure protocols
ssl_protocols TLSv1.3;

# Strong cipher suites for TLS 1.3
ssl_ciphers 'TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256';
ssl_prefer_server_ciphers on;

# HSTS
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

# Other security headers
add_header X-Frame-Options DENY always;
add_header X-Content-Type-Options nosniff always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy no-referrer always;
EOF
    fi
    
    log_success "Insecure protocols disabled"
}

# Main installation
main() {
    log_info "=== PeaceBonds QUIC Server Setup ==="
    
    check_root
    
    # Create directories
    mkdir -p "${INSTALL_DIR}"
    mkdir -p "${CONFIG_DIR}"
    mkdir -p "${TLS_DIR}"
    mkdir -p "${LOG_DIR}"
    
    # Install
    install_dependencies
    install_quiche
    generate_certificates
    create_service
    configure_firewall
    disable_insecure_protocols
    
    log_success "=== Installation Complete ==="
    echo ""
    log_info "To start the QUIC server:"
    log_info "  systemctl start peacebonds-quic"
    log_info "  systemctl enable peacebonds-quic"
    echo ""
    log_info "TLS certificates are located at: ${TLS_DIR}"
    log_info "Server logs are located at: ${LOG_DIR}"
    echo ""
    log_info "Test the server with:"
    log_info "  curl --http3 https://peacebonds.io:443"
}

main "$@"
