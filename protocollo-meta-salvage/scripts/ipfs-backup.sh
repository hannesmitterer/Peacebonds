#!/bin/bash
#
# Autonomous Encrypted Distributed Backup System
# Uses IPFS for distributed storage and GnuPG for encryption
#

set -e

# Configuration
BACKUP_SOURCE="${BACKUP_SOURCE:-/opt/peacebonds/data}"
BACKUP_METADATA_DIR="${BACKUP_METADATA_DIR:-/var/lib/peacebonds/backups}"
GPG_RECIPIENT="${GPG_RECIPIENT:-peacebonds@backup}"
IPFS_API="${IPFS_API:-http://localhost:5001}"
RETENTION_DAYS="${RETENTION_DAYS:-90}"
LOG_FILE="${LOG_FILE:-/var/log/peacebonds/backups.log}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo -e "${timestamp} [${level}] ${message}" | tee -a "${LOG_FILE}"
}

log_info() {
    echo -e "${BLUE}$(log "INFO" "$@")${NC}"
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

# Initialize
init() {
    mkdir -p "${BACKUP_METADATA_DIR}"
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    # Check dependencies
    check_dependencies
}

# Check required dependencies
check_dependencies() {
    local missing_deps=()
    
    for cmd in gpg ipfs jq tar; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install them first"
        exit 1
    fi
    
    # Check if IPFS daemon is running
    if ! ipfs id &> /dev/null; then
        log_error "IPFS daemon is not running"
        log_error "Please start IPFS with: ipfs daemon"
        exit 1
    fi
    
    # Check GPG key
    if ! gpg --list-keys "${GPG_RECIPIENT}" &> /dev/null; then
        log_warn "GPG key for '${GPG_RECIPIENT}' not found"
        log_info "Generating new GPG key..."
        generate_gpg_key
    fi
}

# Generate GPG key for backups
generate_gpg_key() {
    cat > /tmp/gpg-key-config << EOF
%echo Generating backup encryption key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: PeaceBonds Backup
Name-Email: ${GPG_RECIPIENT}
Expire-Date: 0
%no-protection
%commit
%echo Done
EOF
    
    gpg --batch --generate-key /tmp/gpg-key-config
    rm -f /tmp/gpg-key-config
    
    log_success "GPG key generated successfully"
}

# Create backup
create_backup() {
    log_info "=== Starting Backup Process ==="
    
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_name="peacebonds-backup-${timestamp}"
    local temp_dir="/tmp/${backup_name}"
    
    log_info "Backup name: ${backup_name}"
    
    # Create temporary directory
    mkdir -p "${temp_dir}"
    
    # Create tarball
    log_info "Creating tarball from ${BACKUP_SOURCE}..."
    local tarball="${temp_dir}/${backup_name}.tar.gz"
    
    if ! tar -czf "${tarball}" -C "${BACKUP_SOURCE}" .; then
        log_error "Failed to create tarball"
        rm -rf "${temp_dir}"
        return 1
    fi
    
    local original_size=$(stat -f%z "${tarball}" 2>/dev/null || stat -c%s "${tarball}")
    log_info "Tarball size: $(numfmt --to=iec-i --suffix=B ${original_size} 2>/dev/null || echo ${original_size} bytes)"
    
    # Calculate checksum
    log_info "Calculating checksum..."
    local checksum=$(sha256sum "${tarball}" | awk '{print $1}')
    
    # Encrypt with GPG
    log_info "Encrypting backup with GPG..."
    local encrypted_file="${tarball}.gpg"
    
    if ! gpg --encrypt --recipient "${GPG_RECIPIENT}" \
             --trust-model always --output "${encrypted_file}" "${tarball}"; then
        log_error "Encryption failed"
        rm -rf "${temp_dir}"
        return 1
    fi
    
    local encrypted_size=$(stat -f%z "${encrypted_file}" 2>/dev/null || stat -c%s "${encrypted_file}")
    log_info "Encrypted size: $(numfmt --to=iec-i --suffix=B ${encrypted_size} 2>/dev/null || echo ${encrypted_size} bytes)"
    
    # Upload to IPFS
    log_info "Uploading to IPFS..."
    local ipfs_hash=$(ipfs add -q "${encrypted_file}")
    
    if [ -z "${ipfs_hash}" ]; then
        log_error "IPFS upload failed"
        rm -rf "${temp_dir}"
        return 1
    fi
    
    log_success "IPFS hash: ${ipfs_hash}"
    
    # Pin the backup
    log_info "Pinning backup to IPFS..."
    ipfs pin add "${ipfs_hash}" &> /dev/null
    
    # Create metadata
    local metadata_file="${BACKUP_METADATA_DIR}/${backup_name}.json"
    cat > "${metadata_file}" << EOF
{
  "name": "${backup_name}",
  "timestamp": "${timestamp}",
  "ipfs_hash": "${ipfs_hash}",
  "checksum": "${checksum}",
  "original_size": ${original_size},
  "encrypted_size": ${encrypted_size},
  "source": "${BACKUP_SOURCE}",
  "gpg_recipient": "${GPG_RECIPIENT}",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    
    log_info "Metadata saved to ${metadata_file}"
    
    # Cleanup
    rm -rf "${temp_dir}"
    
    log_success "=== Backup Completed Successfully ==="
    log_success "IPFS Hash: ${ipfs_hash}"
    log_success "Metadata: ${metadata_file}"
    
    # Publish to IPNS for easy discovery
    publish_to_ipns "${ipfs_hash}"
    
    return 0
}

# Publish backup to IPNS
publish_to_ipns() {
    local ipfs_hash=$1
    
    log_info "Publishing to IPNS..."
    
    local ipns_name=$(ipfs name publish --key=peacebonds-backup "${ipfs_hash}" 2>&1 | grep -oE 'k[a-zA-Z0-9]{46,}' | head -n1)
    
    if [ -n "${ipns_name}" ]; then
        log_success "IPNS name: ${ipns_name}"
        echo "${ipns_name}" > "${BACKUP_METADATA_DIR}/latest-ipns.txt"
    fi
}

# List backups
list_backups() {
    log_info "Available backups:"
    echo ""
    
    local count=0
    for metadata_file in "${BACKUP_METADATA_DIR}"/*.json; do
        if [ -f "${metadata_file}" ]; then
            local name=$(jq -r '.name' "${metadata_file}")
            local timestamp=$(jq -r '.timestamp' "${metadata_file}")
            local ipfs_hash=$(jq -r '.ipfs_hash' "${metadata_file}")
            local size=$(jq -r '.encrypted_size' "${metadata_file}")
            
            echo "  [$((++count))] ${name}"
            echo "      Timestamp: ${timestamp}"
            echo "      IPFS Hash: ${ipfs_hash}"
            echo "      Size: $(numfmt --to=iec-i --suffix=B ${size} 2>/dev/null || echo ${size} bytes)"
            echo ""
        fi
    done
    
    if [ ${count} -eq 0 ]; then
        echo "  No backups found"
    fi
}

# Restore backup
restore_backup() {
    local ipfs_hash=$1
    local restore_dir=${2:-${BACKUP_SOURCE}}
    
    if [ -z "${ipfs_hash}" ]; then
        log_error "Usage: $0 restore <ipfs_hash> [restore_directory]"
        return 1
    fi
    
    log_info "=== Starting Restore Process ==="
    log_info "IPFS Hash: ${ipfs_hash}"
    log_info "Restore directory: ${restore_dir}"
    
    local temp_dir="/tmp/peacebonds-restore-$$"
    mkdir -p "${temp_dir}"
    
    # Download from IPFS
    log_info "Downloading from IPFS..."
    local encrypted_file="${temp_dir}/backup.tar.gz.gpg"
    
    if ! ipfs get -o "${encrypted_file}" "${ipfs_hash}"; then
        log_error "Failed to download from IPFS"
        rm -rf "${temp_dir}"
        return 1
    fi
    
    # Decrypt with GPG
    log_info "Decrypting backup..."
    local decrypted_file="${temp_dir}/backup.tar.gz"
    
    if ! gpg --decrypt --output "${decrypted_file}" "${encrypted_file}"; then
        log_error "Decryption failed"
        rm -rf "${temp_dir}"
        return 1
    fi
    
    # Verify checksum if metadata exists
    local metadata_file=$(grep -l "\"ipfs_hash\": \"${ipfs_hash}\"" "${BACKUP_METADATA_DIR}"/*.json 2>/dev/null | head -n1)
    if [ -n "${metadata_file}" ]; then
        log_info "Verifying checksum..."
        local expected_checksum=$(jq -r '.checksum' "${metadata_file}")
        local actual_checksum=$(sha256sum "${decrypted_file}" | awk '{print $1}')
        
        if [ "${expected_checksum}" != "${actual_checksum}" ]; then
            log_error "Checksum verification failed!"
            log_error "Expected: ${expected_checksum}"
            log_error "Actual: ${actual_checksum}"
            rm -rf "${temp_dir}"
            return 1
        fi
        log_success "Checksum verified"
    fi
    
    # Extract
    log_info "Extracting to ${restore_dir}..."
    mkdir -p "${restore_dir}"
    
    if ! tar -xzf "${decrypted_file}" -C "${restore_dir}"; then
        log_error "Extraction failed"
        rm -rf "${temp_dir}"
        return 1
    fi
    
    # Cleanup
    rm -rf "${temp_dir}"
    
    log_success "=== Restore Completed Successfully ==="
    return 0
}

# Verify backup
verify_backup() {
    local ipfs_hash=$1
    
    if [ -z "${ipfs_hash}" ]; then
        log_error "Usage: $0 verify <ipfs_hash>"
        return 1
    fi
    
    log_info "Verifying backup: ${ipfs_hash}"
    
    # Check if backup exists in IPFS
    if ipfs cat "${ipfs_hash}" > /dev/null 2>&1; then
        log_success "Backup exists in IPFS"
    else
        log_error "Backup not found in IPFS"
        return 1
    fi
    
    # Check metadata
    local metadata_file=$(grep -l "\"ipfs_hash\": \"${ipfs_hash}\"" "${BACKUP_METADATA_DIR}"/*.json 2>/dev/null | head -n1)
    if [ -n "${metadata_file}" ]; then
        log_info "Metadata found: $(basename ${metadata_file})"
        jq '.' "${metadata_file}"
    else
        log_warn "No metadata found for this backup"
    fi
    
    return 0
}

# Cleanup old backups
cleanup_old_backups() {
    log_info "Cleaning up backups older than ${RETENTION_DAYS} days..."
    
    local count=0
    local cutoff_date=$(date -d "${RETENTION_DAYS} days ago" +%Y%m%d 2>/dev/null || date -v-${RETENTION_DAYS}d +%Y%m%d)
    
    for metadata_file in "${BACKUP_METADATA_DIR}"/*.json; do
        if [ -f "${metadata_file}" ]; then
            local timestamp=$(jq -r '.timestamp' "${metadata_file}")
            local backup_date=$(echo "${timestamp}" | cut -d- -f1)
            
            if [ "${backup_date}" -lt "${cutoff_date}" ]; then
                local ipfs_hash=$(jq -r '.ipfs_hash' "${metadata_file}")
                local name=$(jq -r '.name' "${metadata_file}")
                
                log_info "Removing old backup: ${name}"
                
                # Unpin from IPFS
                ipfs pin rm "${ipfs_hash}" &> /dev/null || true
                
                # Remove metadata
                rm -f "${metadata_file}"
                
                ((count++))
            fi
        fi
    done
    
    log_success "Removed ${count} old backup(s)"
}

# Main function
main() {
    init
    
    case "${1:-}" in
        create)
            create_backup
            ;;
        list)
            list_backups
            ;;
        restore)
            restore_backup "$2" "$3"
            ;;
        verify)
            verify_backup "$2"
            ;;
        cleanup)
            cleanup_old_backups
            ;;
        *)
            echo "Usage: $0 {create|list|restore <ipfs_hash> [dir]|verify <ipfs_hash>|cleanup}"
            echo ""
            echo "Commands:"
            echo "  create   - Create new encrypted backup and upload to IPFS"
            echo "  list     - List available backups"
            echo "  restore  - Restore backup from IPFS hash"
            echo "  verify   - Verify backup integrity"
            echo "  cleanup  - Remove backups older than ${RETENTION_DAYS} days"
            exit 1
            ;;
    esac
}

main "$@"
