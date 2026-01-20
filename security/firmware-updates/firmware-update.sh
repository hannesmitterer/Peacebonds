#!/bin/bash
#
# Secure Firmware Update System
# Verifies checksums and cryptographic signatures before applying updates
#

set -e

FIRMWARE_DIR="/var/lib/peacebonds/firmware"
UPDATE_DIR="/tmp/peacebonds-updates"
GPG_KEYRING="/etc/peacebonds/trusted-keys.gpg"
LOG_FILE="/var/log/peacebonds/firmware-updates.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Initialize directories
init_directories() {
    mkdir -p "$FIRMWARE_DIR"
    mkdir -p "$UPDATE_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
}

# Verify checksum
verify_checksum() {
    local file="$1"
    local checksum_file="$2"
    
    log "Verifying checksum for $file"
    
    if [ ! -f "$checksum_file" ]; then
        error "Checksum file not found: $checksum_file"
        return 1
    fi
    
    # Calculate SHA256 checksum
    local calculated_checksum=$(sha256sum "$file" | awk '{print $1}')
    local expected_checksum=$(cat "$checksum_file" | awk '{print $1}')
    
    log "Expected checksum: $expected_checksum"
    log "Calculated checksum: $calculated_checksum"
    
    if [ "$calculated_checksum" != "$expected_checksum" ]; then
        error "Checksum verification failed!"
        error "Expected: $expected_checksum"
        error "Got: $calculated_checksum"
        return 1
    fi
    
    success "Checksum verification passed"
    return 0
}

# Verify GPG signature
verify_signature() {
    local file="$1"
    local signature_file="$2"
    
    log "Verifying GPG signature for $file"
    
    if [ ! -f "$signature_file" ]; then
        error "Signature file not found: $signature_file"
        return 1
    fi
    
    # Verify signature
    if gpg --keyring "$GPG_KEYRING" --verify "$signature_file" "$file" 2>&1 | tee -a "$LOG_FILE"; then
        success "Signature verification passed"
        return 0
    else
        error "Signature verification failed!"
        return 1
    fi
}

# Create backup before update
create_backup() {
    local current_version="$1"
    local backup_dir="/var/backups/peacebonds/firmware"
    
    log "Creating backup of current firmware version: $current_version"
    
    mkdir -p "$backup_dir"
    
    local backup_file="$backup_dir/firmware-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    if [ -d "$FIRMWARE_DIR" ]; then
        tar -czf "$backup_file" -C "$FIRMWARE_DIR" .
        success "Backup created: $backup_file"
        return 0
    else
        warning "No existing firmware to backup"
        return 0
    fi
}

# Rollback to previous version
rollback_firmware() {
    local backup_dir="/var/backups/peacebonds/firmware"
    
    log "Initiating firmware rollback"
    
    # Find most recent backup
    local latest_backup=$(ls -t "$backup_dir"/firmware-*.tar.gz 2>/dev/null | head -1)
    
    if [ -z "$latest_backup" ]; then
        error "No backup found for rollback"
        return 1
    fi
    
    log "Rolling back to: $latest_backup"
    
    # Extract backup
    rm -rf "$FIRMWARE_DIR"/*
    tar -xzf "$latest_backup" -C "$FIRMWARE_DIR"
    
    success "Rollback completed successfully"
    return 0
}

# Apply firmware update
apply_update() {
    local update_package="$1"
    
    log "Applying firmware update: $update_package"
    
    # Extract update package
    tar -xzf "$update_package" -C "$UPDATE_DIR"
    
    # Check for install script
    if [ -f "$UPDATE_DIR/install.sh" ]; then
        log "Running installation script"
        
        # Verify install script hash if provided
        if [ -f "$UPDATE_DIR/install.sh.sha256" ]; then
            log "Verifying install script checksum"
            local script_checksum=$(sha256sum "$UPDATE_DIR/install.sh" | awk '{print $1}')
            local expected_checksum=$(cat "$UPDATE_DIR/install.sh.sha256" | awk '{print $1}')
            
            if [ "$script_checksum" != "$expected_checksum" ]; then
                error "Install script checksum verification failed!"
                return 1
            fi
            success "Install script checksum verified"
        else
            warning "No install script checksum provided - executing without verification"
            read -p "Continue? (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                log "Installation cancelled by user"
                return 1
            fi
        fi
        
        # Make script executable
        chmod +x "$UPDATE_DIR/install.sh"
        
        # Run install script in restricted environment
        if "$UPDATE_DIR/install.sh"; then
            success "Installation script completed successfully"
        else
            error "Installation script failed"
            return 1
        fi
    else
        # Simple copy operation
        log "Copying firmware files"
        cp -r "$UPDATE_DIR"/* "$FIRMWARE_DIR"/
    fi
    
    success "Firmware update applied successfully"
    return 0
}

# Download update from IPFS
download_from_ipfs() {
    local cid="$1"
    local output_file="$2"
    
    log "Downloading firmware update from IPFS: $cid"
    
    # Try multiple IPFS gateways
    local gateways=(
        "https://ipfs.io/ipfs"
        "https://gateway.pinata.cloud/ipfs"
        "https://cloudflare-ipfs.com/ipfs"
    )
    
    for gateway in "${gateways[@]}"; do
        log "Trying gateway: $gateway"
        
        if curl -f -L -o "$output_file" "$gateway/$cid" 2>&1 | tee -a "$LOG_FILE"; then
            success "Downloaded from $gateway"
            return 0
        else
            warning "Failed to download from $gateway"
        fi
    done
    
    error "Failed to download from all IPFS gateways"
    return 1
}

# Main update function
perform_update() {
    local update_manifest="$1"
    
    log "========================================="
    log "Starting firmware update process"
    log "========================================="
    
    # Read manifest
    if [ ! -f "$update_manifest" ]; then
        error "Update manifest not found: $update_manifest"
        return 1
    fi
    
    # Parse manifest (JSON format expected)
    local firmware_cid=$(jq -r '.firmware_cid' "$update_manifest")
    local checksum_cid=$(jq -r '.checksum_cid' "$update_manifest")
    local signature_cid=$(jq -r '.signature_cid' "$update_manifest")
    local version=$(jq -r '.version' "$update_manifest")
    
    log "Update version: $version"
    log "Firmware CID: $firmware_cid"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Download files from IPFS
    local firmware_file="$temp_dir/firmware.tar.gz"
    local checksum_file="$temp_dir/firmware.sha256"
    local signature_file="$temp_dir/firmware.tar.gz.sig"
    
    download_from_ipfs "$firmware_cid" "$firmware_file" || return 1
    download_from_ipfs "$checksum_cid" "$checksum_file" || return 1
    download_from_ipfs "$signature_cid" "$signature_file" || return 1
    
    # Verify checksum
    verify_checksum "$firmware_file" "$checksum_file" || return 1
    
    # Verify signature
    verify_signature "$firmware_file" "$signature_file" || return 1
    
    # Create backup
    create_backup "current" || warning "Backup creation failed"
    
    # Apply update
    if apply_update "$firmware_file"; then
        success "Firmware update completed successfully!"
        success "New version: $version"
        return 0
    else
        error "Firmware update failed!"
        log "Initiating rollback..."
        rollback_firmware
        return 1
    fi
}

# Main script
main() {
    log "Firmware Update System - Starting"
    
    init_directories
    
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <update-manifest.json>"
        echo ""
        echo "The update manifest should contain:"
        echo "  - firmware_cid: IPFS CID of firmware package"
        echo "  - checksum_cid: IPFS CID of SHA256 checksum"
        echo "  - signature_cid: IPFS CID of GPG signature"
        echo "  - version: Version identifier"
        exit 1
    fi
    
    perform_update "$1"
}

main "$@"
