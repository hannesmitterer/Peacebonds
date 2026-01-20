#!/bin/bash
#
# QUIC Protocol Setup Script
# Installs and configures QUIC support for PeaceBonds
#

set -e

echo "Setting up QUIC protocol support..."

# Install Python dependencies for QUIC
echo "Installing Python QUIC dependencies..."
pip3 install aioquic cryptography

# Create certificate directory
echo "Creating certificate directory..."
sudo mkdir -p /etc/peacebonds/certs

# Generate self-signed certificates for testing (replace with proper certs in production)
if [ ! -f /etc/peacebonds/certs/server.crt ]; then
    echo "Generating self-signed certificate for testing..."
    openssl req -x509 -newkey rsa:4096 \
        -keyout /etc/peacebonds/certs/server.key \
        -out /etc/peacebonds/certs/server.crt \
        -days 365 -nodes \
        -subj "/CN=peacebonds.local/O=PeaceBonds/C=US"
    
    # Copy as CA cert for testing
    sudo cp /etc/peacebonds/certs/server.crt /etc/peacebonds/certs/ca.crt
    
    echo "Self-signed certificate created (for testing only!)"
    echo "Replace with proper certificates in production"
fi

# Set permissions
sudo chmod 600 /etc/peacebonds/certs/server.key
sudo chmod 644 /etc/peacebonds/certs/server.crt
sudo chmod 644 /etc/peacebonds/certs/ca.crt

echo ""
echo "QUIC setup completed!"
echo ""
echo "Certificate files:"
echo "  - Server cert: /etc/peacebonds/certs/server.crt"
echo "  - Server key: /etc/peacebonds/certs/server.key"
echo "  - CA cert: /etc/peacebonds/certs/ca.crt"
echo ""
echo "Note: Replace self-signed certificates with proper CA-signed certificates for production use"
echo ""
