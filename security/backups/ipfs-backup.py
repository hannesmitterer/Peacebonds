#!/usr/bin/env python3
"""
Distributed Encrypted Backup System
Automates backup to IPFS with GnuPG encryption
"""

import os
import subprocess
import json
import logging
import hashlib
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/peacebonds/backup.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class BackupConfig:
    """Backup configuration"""
    
    def __init__(self, config_path: str = "/etc/peacebonds/backup-config.json"):
        self.config_path = config_path
        self.config = self._load_config()
        
    def _load_config(self) -> Dict[str, Any]:
        """Load configuration"""
        default_config = {
            "backup_paths": [
                "/var/lib/peacebonds/data",
                "/etc/peacebonds",
                "/var/lib/peacebonds/firmware"
            ],
            "backup_dir": "/var/backups/peacebonds",
            "gpg_recipient": "peacebonds@example.com",
            "ipfs_api_url": "http://127.0.0.1:5001",
            "retention_days": 30,
            "schedule": "daily",
            "compression": "gzip",
            "encryption": "gpg"
        }
        
        try:
            if os.path.exists(self.config_path):
                with open(self.config_path, 'r') as f:
                    loaded_config = json.load(f)
                    default_config.update(loaded_config)
        except Exception as e:
            logger.warning(f"Could not load config: {e}. Using defaults.")
            
        return default_config


class EncryptedBackupSystem:
    """Main backup system"""
    
    def __init__(self, config: BackupConfig):
        self.config = config
        
    def _create_archive(self, paths: List[str], output_file: str) -> bool:
        """Create compressed archive of paths"""
        try:
            logger.info(f"Creating archive: {output_file}")
            
            # Build tar command
            cmd = ['tar', '-czf', output_file]
            
            # Add paths that exist
            existing_paths = [p for p in paths if os.path.exists(p)]
            if not existing_paths:
                logger.error("No backup paths exist")
                return False
                
            cmd.extend(existing_paths)
            
            # Run tar
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
            
            if result.returncode == 0:
                logger.info(f"Archive created successfully: {output_file}")
                return True
            else:
                logger.error(f"Failed to create archive: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Error creating archive: {e}")
            return False
    
    def _encrypt_file(self, input_file: str, output_file: str) -> bool:
        """Encrypt file with GPG"""
        try:
            logger.info(f"Encrypting file: {input_file}")
            
            recipient = self.config.config['gpg_recipient']
            
            # Verify recipient key exists before encrypting
            verify_result = subprocess.run(
                ['gpg', '--list-keys', recipient],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if verify_result.returncode != 0:
                logger.error(f"GPG key not found for recipient: {recipient}")
                logger.error("Please import the recipient's public key first")
                return False
            
            cmd = [
                'gpg',
                '--encrypt',
                '--recipient', recipient,
                '--output', output_file,
                input_file
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            
            if result.returncode == 0:
                logger.info(f"File encrypted successfully: {output_file}")
                return True
            else:
                logger.error(f"Failed to encrypt file: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Error encrypting file: {e}")
            return False
    
    def _decrypt_file(self, input_file: str, output_file: str) -> bool:
        """Decrypt file with GPG"""
        try:
            logger.info(f"Decrypting file: {input_file}")
            
            cmd = [
                'gpg',
                '--decrypt',
                '--output', output_file,
                input_file
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            
            if result.returncode == 0:
                logger.info(f"File decrypted successfully: {output_file}")
                return True
            else:
                logger.error(f"Failed to decrypt file: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Error decrypting file: {e}")
            return False
    
    def _upload_to_ipfs(self, file_path: str) -> Optional[str]:
        """Upload file to IPFS"""
        try:
            logger.info(f"Uploading to IPFS: {file_path}")
            
            cmd = [
                'curl',
                '-F', f'file=@{file_path}',
                f"{self.config.config['ipfs_api_url']}/api/v0/add?pin=true"
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
            
            if result.returncode == 0:
                response = json.loads(result.stdout)
                cid = response.get('Hash')
                logger.info(f"Uploaded to IPFS with CID: {cid}")
                return cid
            else:
                logger.error(f"Failed to upload to IPFS: {result.stderr}")
                return None
                
        except Exception as e:
            logger.error(f"Error uploading to IPFS: {e}")
            return None
    
    def _download_from_ipfs(self, cid: str, output_file: str) -> bool:
        """Download file from IPFS"""
        try:
            logger.info(f"Downloading from IPFS: {cid}")
            
            cmd = [
                'curl',
                '-o', output_file,
                f"{self.config.config['ipfs_api_url']}/api/v0/cat?arg={cid}"
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
            
            if result.returncode == 0 and os.path.exists(output_file):
                logger.info(f"Downloaded from IPFS: {output_file}")
                return True
            else:
                logger.error(f"Failed to download from IPFS: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Error downloading from IPFS: {e}")
            return False
    
    def _calculate_checksum(self, file_path: str) -> str:
        """Calculate SHA256 checksum"""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()
    
    def _save_backup_metadata(self, metadata: Dict[str, Any]):
        """Save backup metadata"""
        try:
            metadata_file = os.path.join(
                self.config.config['backup_dir'],
                'backup-metadata.json'
            )
            
            # Load existing metadata
            existing_metadata = []
            if os.path.exists(metadata_file):
                with open(metadata_file, 'r') as f:
                    existing_metadata = json.load(f)
            
            # Append new metadata
            existing_metadata.append(metadata)
            
            # Save updated metadata
            with open(metadata_file, 'w') as f:
                json.dump(existing_metadata, f, indent=2)
                
            logger.info(f"Backup metadata saved: {metadata_file}")
            
        except Exception as e:
            logger.error(f"Error saving backup metadata: {e}")
    
    def create_backup(self) -> Optional[str]:
        """Create encrypted backup and upload to IPFS"""
        try:
            logger.info("=" * 60)
            logger.info("Starting backup process")
            logger.info("=" * 60)
            
            timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
            backup_name = f"peacebonds-backup-{timestamp}"
            
            # Create backup directory
            backup_dir = self.config.config['backup_dir']
            os.makedirs(backup_dir, exist_ok=True)
            
            # File paths
            archive_file = os.path.join(backup_dir, f"{backup_name}.tar.gz")
            encrypted_file = os.path.join(backup_dir, f"{backup_name}.tar.gz.gpg")
            
            # Step 1: Create archive
            if not self._create_archive(self.config.config['backup_paths'], archive_file):
                return None
            
            # Step 2: Calculate checksum
            checksum = self._calculate_checksum(archive_file)
            logger.info(f"Archive checksum: {checksum}")
            
            # Step 3: Encrypt archive
            if not self._encrypt_file(archive_file, encrypted_file):
                return None
            
            # Step 4: Upload to IPFS
            cid = self._upload_to_ipfs(encrypted_file)
            if not cid:
                return None
            
            # Step 5: Save metadata
            metadata = {
                "timestamp": datetime.now().isoformat(),
                "backup_name": backup_name,
                "cid": cid,
                "checksum": checksum,
                "encrypted": True,
                "size_bytes": os.path.getsize(encrypted_file),
                "paths": self.config.config['backup_paths']
            }
            self._save_backup_metadata(metadata)
            
            # Clean up local files (optional - keep encrypted file)
            os.remove(archive_file)
            
            logger.info("=" * 60)
            logger.info(f"Backup completed successfully!")
            logger.info(f"IPFS CID: {cid}")
            logger.info(f"Encrypted file: {encrypted_file}")
            logger.info("=" * 60)
            
            return cid
            
        except Exception as e:
            logger.error(f"Error creating backup: {e}")
            return None
    
    def restore_backup(self, cid: str, output_dir: str) -> bool:
        """Restore backup from IPFS"""
        try:
            logger.info("=" * 60)
            logger.info(f"Starting restore process for CID: {cid}")
            logger.info("=" * 60)
            
            # Create temp directory
            temp_dir = "/tmp/peacebonds-restore"
            os.makedirs(temp_dir, exist_ok=True)
            
            encrypted_file = os.path.join(temp_dir, "backup.tar.gz.gpg")
            decrypted_file = os.path.join(temp_dir, "backup.tar.gz")
            
            # Step 1: Download from IPFS
            if not self._download_from_ipfs(cid, encrypted_file):
                return False
            
            # Step 2: Decrypt file
            if not self._decrypt_file(encrypted_file, decrypted_file):
                return False
            
            # Step 3: Extract archive
            logger.info(f"Extracting archive to: {output_dir}")
            os.makedirs(output_dir, exist_ok=True)
            
            cmd = ['tar', '-xzf', decrypted_file, '-C', output_dir]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
            
            if result.returncode == 0:
                logger.info("=" * 60)
                logger.info("Restore completed successfully!")
                logger.info(f"Files restored to: {output_dir}")
                logger.info("=" * 60)
                return True
            else:
                logger.error(f"Failed to extract archive: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Error restoring backup: {e}")
            return False


def main():
    """Main entry point"""
    import sys
    
    if len(sys.argv) < 2:
        print("Usage:")
        print(f"  {sys.argv[0]} backup                    - Create backup")
        print(f"  {sys.argv[0]} restore <CID> <output>    - Restore backup")
        sys.exit(1)
    
    config = BackupConfig()
    backup_system = EncryptedBackupSystem(config)
    
    command = sys.argv[1]
    
    if command == 'backup':
        cid = backup_system.create_backup()
        if cid:
            print(f"\nBackup CID: {cid}")
            sys.exit(0)
        else:
            sys.exit(1)
            
    elif command == 'restore':
        if len(sys.argv) < 4:
            print("Usage: restore <CID> <output_directory>")
            sys.exit(1)
            
        cid = sys.argv[2]
        output_dir = sys.argv[3]
        
        if backup_system.restore_backup(cid, output_dir):
            sys.exit(0)
        else:
            sys.exit(1)
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == '__main__':
    main()
