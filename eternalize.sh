#!/bin/bash

################################################################################
# Eternalize Framework Script
# 
# This script automates the workflow for eternalizing frameworks using IPFS
# and Pinata in the Peacebonds repository.
#
# Prerequisites:
#   - Export PINATA_JWT environment variable before running
#   - Ensure docs/ directory exists in repository root
#
# Usage:
#   export PINATA_JWT="your_pinata_jwt_token"
#   ./eternalize.sh
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if PINATA_JWT is set
check_pinata_jwt() {
    log_info "Checking for PINATA_JWT environment variable..."
    if [ -z "$PINATA_JWT" ]; then
        log_error "PINATA_JWT environment variable is not set!"
        log_info "Please export your Pinata JWT token:"
        echo "  export PINATA_JWT=\"your_pinata_jwt_token\""
        exit 1
    fi
    log_success "PINATA_JWT found"
}

# Check if docs directory exists
check_docs_directory() {
    log_info "Checking for docs/ directory..."
    if [ ! -d "docs" ]; then
        log_error "docs/ directory not found!"
        log_info "Please create a docs/ directory and add your documentation files."
        exit 1
    fi
    log_success "docs/ directory found"
}

# Check if IPFS is installed, if not, install it
install_ipfs() {
    log_info "Checking if IPFS is installed..."
    
    if command -v ipfs &> /dev/null; then
        log_success "IPFS is already installed ($(ipfs --version))"
        return 0
    fi
    
    log_warning "IPFS not found. Installing IPFS CLI..."
    
    # Detect OS and architecture
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    # Map architecture names
    case "$ARCH" in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="arm"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    # Determine platform
    case "$OS" in
        linux)
            PLATFORM="linux"
            ;;
        darwin)
            PLATFORM="darwin"
            ;;
        *)
            log_error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
    
    # Download and install IPFS
    IPFS_VERSION="v0.24.0"
    IPFS_DIST="kubo_${IPFS_VERSION}_${PLATFORM}-${ARCH}"
    DOWNLOAD_URL="https://dist.ipfs.tech/kubo/${IPFS_VERSION}/${IPFS_DIST}.tar.gz"
    
    log_info "Downloading IPFS from $DOWNLOAD_URL..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR" || exit 1
    
    # Download IPFS
    if ! curl -L -o ipfs.tar.gz "$DOWNLOAD_URL"; then
        log_error "Failed to download IPFS"
        cd - > /dev/null
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Extract archive
    log_info "Extracting IPFS..."
    tar -xzf ipfs.tar.gz
    
    # Install IPFS
    log_info "Installing IPFS..."
    cd kubo || exit 1
    
    # Try to install to /usr/local/bin, fallback to user directory
    if sudo bash install.sh 2>/dev/null; then
        log_success "IPFS installed to /usr/local/bin"
    else
        log_warning "Could not install to /usr/local/bin, installing to ~/.local/bin"
        mkdir -p "$HOME/.local/bin"
        cp ipfs "$HOME/.local/bin/"
        
        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            export PATH="$HOME/.local/bin:$PATH"
            log_info "Added ~/.local/bin to PATH for this session"
            log_warning "Add 'export PATH=\"\$HOME/.local/bin:\$PATH\"' to your ~/.bashrc or ~/.zshrc"
        fi
    fi
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    # Verify installation
    if command -v ipfs &> /dev/null; then
        log_success "IPFS installed successfully ($(ipfs --version))"
    else
        log_error "IPFS installation failed"
        exit 1
    fi
}

# Initialize IPFS repository
initialize_ipfs() {
    log_info "Checking IPFS initialization..."
    
    if [ -d "$HOME/.ipfs" ]; then
        log_success "IPFS repository already initialized"
    else
        log_info "Initializing IPFS repository..."
        if ipfs init; then
            log_success "IPFS repository initialized"
        else
            log_error "Failed to initialize IPFS repository"
            exit 1
        fi
    fi
}

# Start IPFS daemon
start_ipfs_daemon() {
    log_info "Starting IPFS daemon..."
    
    # Check if daemon is already running
    if ipfs swarm peers &> /dev/null; then
        log_success "IPFS daemon is already running"
        return 0
    fi
    
    # Start daemon in background
    log_info "Launching IPFS daemon in background..."
    ipfs daemon &> /tmp/ipfs-daemon.log &
    IPFS_DAEMON_PID=$!
    
    # Wait for daemon to be ready
    log_info "Waiting for IPFS daemon to be ready..."
    MAX_WAIT=30
    WAITED=0
    
    while [ $WAITED -lt $MAX_WAIT ]; do
        if ipfs swarm peers &> /dev/null; then
            log_success "IPFS daemon is ready"
            return 0
        fi
        sleep 1
        WAITED=$((WAITED + 1))
    done
    
    log_error "IPFS daemon failed to start within ${MAX_WAIT} seconds"
    log_info "Check /tmp/ipfs-daemon.log for details"
    exit 1
}

# Add docs directory to IPFS
add_to_ipfs() {
    log_info "Adding docs/ directory to IPFS..."
    
    # Add directory recursively and capture output
    if OUTPUT=$(ipfs add -r docs 2>&1); then
        # Extract the CID of the root directory (last line of output)
        CID=$(echo "$OUTPUT" | tail -n 1 | awk '{print $2}')
        
        if [ -z "$CID" ]; then
            log_error "Failed to extract CID from IPFS output"
            exit 1
        fi
        
        log_success "Successfully added docs/ to IPFS"
        log_info "Root CID: $CID"
        echo "$CID" > .ipfs_cid
        log_info "CID saved to .ipfs_cid file"
        
        # Export CID for use in pinning
        echo "$CID"
    else
        log_error "Failed to add docs/ to IPFS"
        log_error "$OUTPUT"
        exit 1
    fi
}

# Pin to Pinata
pin_to_pinata() {
    local CID=$1
    log_info "Pinning CID to Pinata..."
    
    # Prepare JSON payload
    JSON_PAYLOAD=$(cat <<EOF
{
  "hashToPin": "$CID",
  "pinataMetadata": {
    "name": "Peacebonds Documentation"
  }
}
EOF
)
    
    # Make API request to Pinata
    log_info "Sending pin request to Pinata API..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
        "https://api.pinata.cloud/pinning/pinByHash" \
        -H "Authorization: Bearer $PINATA_JWT" \
        -H "Content-Type: application/json" \
        -d "$JSON_PAYLOAD")
    
    # Extract HTTP status code and response body
    HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    # Check response
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
        log_success "Successfully pinned to Pinata!"
        log_info "Response: $BODY"
        
        # Save response to file
        echo "$BODY" > .pinata_response.json
        log_info "Pinata response saved to .pinata_response.json"
    else
        log_error "Failed to pin to Pinata (HTTP $HTTP_CODE)"
        log_error "Response: $BODY"
        exit 1
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up..."
    # Kill IPFS daemon if we started it
    if [ ! -z "$IPFS_DAEMON_PID" ]; then
        log_info "Stopping IPFS daemon..."
        kill $IPFS_DAEMON_PID 2>/dev/null || true
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Main execution
main() {
    log_info "=========================================="
    log_info "Peacebonds Framework Eternalization Script"
    log_info "=========================================="
    echo ""
    
    # Step 1: Check prerequisites
    check_pinata_jwt
    check_docs_directory
    
    # Step 2: Install IPFS if needed
    install_ipfs
    
    # Step 3: Initialize IPFS
    initialize_ipfs
    
    # Step 4: Start IPFS daemon
    start_ipfs_daemon
    
    # Step 5: Add docs to IPFS
    CID=$(add_to_ipfs)
    
    # Step 6: Pin to Pinata
    pin_to_pinata "$CID"
    
    echo ""
    log_success "=========================================="
    log_success "Eternalization Complete!"
    log_success "=========================================="
    log_info "CID: $CID"
    log_info "IPFS Gateway URL: https://ipfs.io/ipfs/$CID"
    log_info "Pinata Gateway URL: https://gateway.pinata.cloud/ipfs/$CID"
    echo ""
}

# Run main function
main
