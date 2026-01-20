#!/bin/bash
#
# Secure Firmware Update System for Decentralized Nodes
# Implements checksum verification and cryptographic signature validation
#

set -e

# Configuration
FIRMWARE_DIR="${FIRMWARE_DIR:-/opt/peacebonds/firmware}"
UPDATE_SERVER="${UPDATE_SERVER:-https://updates.peacebonds.io}"
GPG_KEYRING="${GPG_KEYRING:-/etc/peacebonds/trusted-keys.gpg}"
CURRENT_VERSION_FILE="${CURRENT_VERSION_FILE:-/etc/peacebonds/version}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/peacebonds/firmware}"
LOG_FILE="${LOG_FILE:-/var/log/peacebonds/firmware-updates.log}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo -e "${timestamp} [${level}] ${message}" | tee -a "${LOG_FILE}"
}

log_info() {
    log "INFO" "$@"
}

log_warn() {
    echo -e "${YELLOW}$(log "WARN" "$@")${NC}"
}

log_error() {
    echo -e "${RED}$(log "ERROR" "$@")${NC}"
}

log_success() {
    echo -e "${GREEN}$(log "SUCCESS" "$@")${NC}"
}

# Initialize directories
init_directories() {
    mkdir -p "${FIRMWARE_DIR}"
    mkdir -p "${BACKUP_DIR}"
    mkdir -p "$(dirname "${LOG_FILE}")"
    mkdir -p "$(dirname "${CURRENT_VERSION_FILE}")"
}

# Get current firmware version
get_current_version() {
    if [ -f "${CURRENT_VERSION_FILE}" ]; then
        cat "${CURRENT_VERSION_FILE}"
    else
        echo "0.0.0"
    fi
}

# Check for available updates
check_updates() {
    log_info "Checking for firmware updates..."
    
    local current_version=$(get_current_version)
    log_info "Current version: ${current_version}"
    
    # Fetch latest version info
    local manifest_url="${UPDATE_SERVER}/manifest.json"
    local manifest_file="/tmp/peacebonds-manifest.json"
    
    if ! curl -fsSL "${manifest_url}" -o "${manifest_file}"; then
        log_error "Failed to fetch update manifest"
        return 1
    fi
    
    # Extract latest version
    local latest_version=$(jq -r '.version' "${manifest_file}")
    log_info "Latest version: ${latest_version}"
    
    # Compare versions
    if [ "${current_version}" = "${latest_version}" ]; then
        log_info "Already running latest version"
        return 0
    fi
    
    echo "${manifest_file}"
}

# Verify checksum
verify_checksum() {
    local file=$1
    local expected_checksum=$2
    local algorithm=${3:-sha256}
    
    log_info "Verifying ${algorithm} checksum for $(basename ${file})..."
    
    local actual_checksum=""
    case "${algorithm}" in
        sha256)
            actual_checksum=$(sha256sum "${file}" | awk '{print $1}')
            ;;
        sha512)
            actual_checksum=$(sha512sum "${file}" | awk '{print $1}')
            ;;
        *)
            log_error "Unsupported checksum algorithm: ${algorithm}"
            return 1
            ;;
    esac
    
    if [ "${actual_checksum}" != "${expected_checksum}" ]; then
        log_error "Checksum verification failed!"
        log_error "Expected: ${expected_checksum}"
        log_error "Actual:   ${actual_checksum}"
        return 1
    fi
    
    log_success "Checksum verification passed"
    return 0
}

# Verify cryptographic signature
verify_signature() {
    local file=$1
    local signature_file=$2
    
    log_info "Verifying cryptographic signature for $(basename ${file})..."
    
    # Check if GPG keyring exists
    if [ ! -f "${GPG_KEYRING}" ]; then
        log_error "GPG keyring not found: ${GPG_KEYRING}"
        log_error "Please import trusted keys first"
        return 1
    fi
    
    # Verify signature using GPG
    if gpg --no-default-keyring --keyring "${GPG_KEYRING}" \
           --verify "${signature_file}" "${file}" 2>&1 | tee -a "${LOG_FILE}"; then
        log_success "Signature verification passed"
        return 0
    else
        log_error "Signature verification failed!"
        return 1
    fi
}

# Download firmware update
download_firmware() {
    local manifest_file=$1
    
    local version=$(jq -r '.version' "${manifest_file}")
    local download_url=$(jq -r '.download_url' "${manifest_file}")
    local checksum=$(jq -r '.checksum.sha256' "${manifest_file}")
    local signature_url=$(jq -r '.signature_url' "${manifest_file}")
    
    log_info "Downloading firmware version ${version}..."
    
    local firmware_file="/tmp/peacebonds-firmware-${version}.tar.gz"
    local signature_file="/tmp/peacebonds-firmware-${version}.tar.gz.sig"
    
    # Download firmware
    if ! curl -fsSL "${download_url}" -o "${firmware_file}"; then
        log_error "Failed to download firmware"
        return 1
    fi
    
    # Download signature
    if ! curl -fsSL "${signature_url}" -o "${signature_file}"; then
        log_error "Failed to download signature"
        return 1
    fi
    
    # Verify checksum
    if ! verify_checksum "${firmware_file}" "${checksum}" "sha256"; then
        rm -f "${firmware_file}" "${signature_file}"
        return 1
    fi
    
    # Verify signature
    if ! verify_signature "${firmware_file}" "${signature_file}"; then
        rm -f "${firmware_file}" "${signature_file}"
        return 1
    fi
    
    echo "${firmware_file}:${version}"
}

# Backup current firmware
backup_firmware() {
    local current_version=$(get_current_version)
    
    log_info "Backing up current firmware (version ${current_version})..."
    
    local backup_file="${BACKUP_DIR}/firmware-${current_version}-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    if tar -czf "${backup_file}" -C "${FIRMWARE_DIR}" .; then
        log_success "Backup created: ${backup_file}"
        echo "${backup_file}"
    else
        log_error "Backup failed"
        return 1
    fi
}

# Install firmware update
install_firmware() {
    local firmware_file=$1
    local version=$2
    
    log_info "Installing firmware version ${version}..."
    
    # Create backup first
    local backup_file=$(backup_firmware)
    if [ $? -ne 0 ]; then
        log_error "Cannot proceed without backup"
        return 1
    fi
    
    # Extract firmware
    if tar -xzf "${firmware_file}" -C "${FIRMWARE_DIR}"; then
        log_success "Firmware extracted successfully"
    else
        log_error "Firmware extraction failed"
        log_info "Restoring from backup..."
        tar -xzf "${backup_file}" -C "${FIRMWARE_DIR}"
        return 1
    fi
    
    # Update version file
    echo "${version}" > "${CURRENT_VERSION_FILE}"
    
    # Cleanup
    rm -f "${firmware_file}"
    
    log_success "Firmware update completed: ${version}"
    return 0
}

# Rollback to previous version
rollback_firmware() {
    log_warn "Rolling back firmware to previous version..."
    
    # Find latest backup
    local latest_backup=$(ls -t "${BACKUP_DIR}"/firmware-*.tar.gz 2>/dev/null | head -n1)
    
    if [ -z "${latest_backup}" ]; then
        log_error "No backup found for rollback"
        return 1
    fi
    
    log_info "Restoring from: $(basename ${latest_backup})"
    
    # Extract backup
    if tar -xzf "${latest_backup}" -C "${FIRMWARE_DIR}"; then
        log_success "Rollback completed successfully"
        return 0
    else
        log_error "Rollback failed"
        return 1
    fi
}

# Import trusted GPG key
import_gpg_key() {
    local key_file=$1
    
    log_info "Importing GPG key from ${key_file}..."
    
    mkdir -p "$(dirname "${GPG_KEYRING}")"
    
    if gpg --no-default-keyring --keyring "${GPG_KEYRING}" --import "${key_file}"; then
        log_success "GPG key imported successfully"
        return 0
    else
        log_error "Failed to import GPG key"
        return 1
    fi
}

# Main update function
update_firmware() {
    log_info "=== Starting Firmware Update Process ==="
    
    init_directories
    
    # Check for updates
    local manifest_file=$(check_updates)
    if [ $? -ne 0 ] || [ -z "${manifest_file}" ]; then
        return 1
    fi
    
    # Download and verify firmware
    local download_result=$(download_firmware "${manifest_file}")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local firmware_file=$(echo "${download_result}" | cut -d: -f1)
    local version=$(echo "${download_result}" | cut -d: -f2)
    
    # Install firmware
    if install_firmware "${firmware_file}" "${version}"; then
        log_success "=== Firmware Update Completed Successfully ==="
        return 0
    else
        log_error "=== Firmware Update Failed ==="
        return 1
    fi
}

# Command-line interface
case "${1:-}" in
    update)
        update_firmware
        ;;
    check)
        check_updates
        ;;
    rollback)
        rollback_firmware
        ;;
    import-key)
        if [ -z "$2" ]; then
            log_error "Usage: $0 import-key <key-file>"
            exit 1
        fi
        import_gpg_key "$2"
        ;;
    version)
        echo "Current version: $(get_current_version)"
        ;;
    *)
        echo "Usage: $0 {update|check|rollback|import-key <file>|version}"
        echo ""
        echo "Commands:"
        echo "  update       - Check and install firmware updates"
        echo "  check        - Check for available updates"
        echo "  rollback     - Rollback to previous firmware version"
        echo "  import-key   - Import trusted GPG signing key"
        echo "  version      - Display current firmware version"
        exit 1
        ;;
esac
