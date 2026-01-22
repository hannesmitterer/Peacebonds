# TrustWallet Integration

Integration of TrustWallet Core with PeaceBonds Security Layer (Euystacio Framework v1.1).

## Overview

This module provides secure wallet management, transaction signing, and Peace Bond commitment signing integrated with the existing security infrastructure.

## Features

### Core Wallet Operations
- **Mnemonic-based wallet** generation (BIP39/BIP44 compatible)
- **Private key management** with secure storage
- **Transaction signing** and broadcasting
- **Message signing** for authentication
- **Balance queries** and wallet info

### Security Integration
- **AES-256 encryption** for wallet backups (compatible with IPFS backup system)
- **PBKDF2 key derivation** (100,000 iterations)
- **Checksum verification** for backup integrity
- **Peace Bond commitment signing** with structured messages

### Peace Bonds Integration
- Sign Peace Bond commitments with verification
- Verify signatures against expected addresses
- Export/import wallets via IPFS backup system
- Monitor wallet status via Grafana dashboard

## Installation

The module is already integrated with the existing TypeScript codebase. No additional dependencies required beyond existing `ethers` package.

## Usage

### Initialize Wallet

```typescript
import TrustWalletIntegration from './wallet/trustwallet';

// From mnemonic
const wallet = new TrustWalletIntegration({
  mnemonic: 'your twelve word mnemonic phrase here...',
  rpcUrl: 'https://mainnet.infura.io/v3/YOUR-PROJECT-ID',
  networkId: 1
});

// From private key
const wallet = new TrustWalletIntegration({
  privateKey: '0x...',
  rpcUrl: 'https://mainnet.infura.io/v3/YOUR-PROJECT-ID'
});

// Generate new wallet
const { wallet: newWallet, mnemonic } = TrustWalletIntegration.generateWallet();
console.log('New mnemonic:', mnemonic);
```

### Sign Peace Bond Commitment

```typescript
const bondCommitment = await wallet.signPeaceBondCommitment({
  amount: '1.5',
  recipient: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
  duration: 86400, // 24 hours in seconds
  conditions: 'Peace agreement terms...'
});

console.log('Signature:', bondCommitment.signature);
console.log('Hash:', bondCommitment.hash);
```

### Export for IPFS Backup

```typescript
// Export encrypted wallet
const backupJson = await wallet.exportForIPFSBackup('strong-password');

// Save to IPFS (integrated with existing ipfs-backup.sh)
// The backup is AES-256 encrypted and includes integrity checksum
```

### Import from IPFS Backup

```typescript
// Retrieve from IPFS
const backupJson = '...'; // From IPFS

// Import wallet
const restoredWallet = await TrustWalletIntegration.importFromIPFSBackup(
  backupJson,
  'strong-password',
  'https://mainnet.infura.io/v3/YOUR-PROJECT-ID'
);

console.log('Restored address:', restoredWallet.getAddress());
```

### Send Transaction

```typescript
const txHash = await wallet.sendTransaction({
  to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
  value: '0.1', // ETH
  gasLimit: '21000'
});

console.log('Transaction hash:', txHash);
```

### Verify Peace Bond Signature

```typescript
const isValid = await wallet.verifyPeaceBondSignature(
  message,
  signature,
  expectedAddress
);

console.log('Signature valid:', isValid);
```

### Get Wallet Info for Monitoring

```typescript
const info = await wallet.getWalletInfo();
console.log('Address:', info.address);
console.log('Balance:', info.balance, 'ETH');
console.log('Network:', info.network);
console.log('Has Provider:', info.hasProvider);
```

## Integration Points

### 1. IPFS Backup System

The wallet encryption is compatible with the existing `ipfs-backup.sh` script:

```bash
# Backup wallet to IPFS
WALLET_BACKUP="/tmp/wallet-backup.json"
echo "$ENCRYPTED_WALLET_JSON" > $WALLET_BACKUP

# Use existing IPFS backup script
./protocollo-meta-salvage/scripts/ipfs-backup.sh
```

### 2. Forensic Response System

Wallet operations can trigger forensic logging:

```python
# In forensic-response.py
if detect_suspicious_transaction(tx_hash):
    log_to_loki({
        'level': 'warning',
        'component': 'trustwallet',
        'message': 'Suspicious transaction detected',
        'tx_hash': tx_hash,
        'wallet': address
    })
```

### 3. Grafana Dashboard

Add wallet monitoring panel to `grafana-dashboard.json`:

```json
{
  "title": "TrustWallet Status",
  "targets": [{
    "expr": "wallet_balance{address=\"$address\"}",
    "legendFormat": "Balance (ETH)"
  }]
}
```

### 4. QUIC/TLS Communication

Wallet operations use existing secure communication:

```typescript
// Transactions routed through QUIC/TLS 1.3
const provider = new ethers.JsonRpcProvider(
  'https://secure-node.peacebonds.network',  // Uses QUIC
  { name: 'peacebonds', chainId: 1 }
);
```

## Security Features

### Encryption
- **Algorithm**: AES-256-CBC
- **Key Derivation**: PBKDF2 (100,000 iterations, SHA-256)
- **IV**: Random 16 bytes per encryption
- **Salt**: Random 32 bytes per encryption

### Backup Integrity
- SHA-256 checksum of encrypted data
- Verification before decryption
- Timestamp tracking

### Peace Bond Signing
- Structured message format
- Network ID verification
- Timestamp inclusion
- Keccak256 hash for reference

## CLI Integration

Example CLI command (can be added to `src/cli/index.js`):

```typescript
import TrustWalletIntegration from '../wallet/trustwallet';

program
  .command('wallet:sign-bond')
  .description('Sign a Peace Bond commitment')
  .requiredOption('-a, --amount <amount>', 'Bond amount in ETH')
  .requiredOption('-r, --recipient <address>', 'Recipient address')
  .requiredOption('-d, --duration <seconds>', 'Bond duration')
  .requiredOption('-c, --conditions <text>', 'Bond conditions')
  .action(async (options) => {
    const wallet = new TrustWalletIntegration({
      privateKey: process.env.PRIVATE_KEY,
      rpcUrl: process.env.RPC_URL
    });

    const commitment = await wallet.signPeaceBondCommitment({
      amount: options.amount,
      recipient: options.recipient,
      duration: parseInt(options.duration),
      conditions: options.conditions
    });

    console.log('Commitment signed successfully!');
    console.log('Signature:', commitment.signature);
    console.log('Hash:', commitment.hash);
  });
```

## Environment Variables

Add to `.env.example`:

```bash
# TrustWallet Configuration
WALLET_MNEMONIC=your twelve word mnemonic here
WALLET_PRIVATE_KEY=0x...
WALLET_RPC_URL=https://mainnet.infura.io/v3/YOUR-PROJECT-ID
WALLET_NETWORK_ID=1
WALLET_DERIVATION_PATH=m/44'/60'/0'/0/0

# Backup Encryption
WALLET_BACKUP_PASSWORD=strong-password-here
```

## Deployment

The TrustWallet integration is automatically deployed with the security layer:

```bash
# Using GitHub Actions
Actions → Auto-Deploy Security Enhancements → Run workflow

# Using manual script
cd protocollo-meta-salvage/scripts
./autodeploy.sh --environment staging
```

## Testing

```typescript
import TrustWalletIntegration from './wallet/trustwallet';

describe('TrustWallet Integration', () => {
  it('should generate new wallet', () => {
    const { wallet, mnemonic } = TrustWalletIntegration.generateWallet();
    expect(wallet.address).toBeDefined();
    expect(mnemonic.split(' ')).toHaveLength(12);
  });

  it('should sign Peace Bond commitment', async () => {
    const wallet = new TrustWalletIntegration({
      privateKey: '0x...'
    });

    const commitment = await wallet.signPeaceBondCommitment({
      amount: '1.0',
      recipient: '0x...',
      duration: 86400,
      conditions: 'Test conditions'
    });

    expect(commitment.signature).toBeDefined();
    expect(commitment.hash).toBeDefined();
  });

  it('should encrypt and decrypt wallet', async () => {
    const wallet = new TrustWalletIntegration({
      privateKey: '0x...'
    });

    const encrypted = await wallet.encryptWallet('password');
    expect(encrypted.checksum).toBeDefined();

    const privateKey = await TrustWalletIntegration.decryptWallet(
      encrypted,
      'password'
    );
    expect(privateKey).toBe('0x...');
  });
});
```

## Monitoring & Alerts

Integration with existing Loki/Grafana stack:

- **Wallet balance** monitoring
- **Transaction success/failure** tracking
- **Signature verification** metrics
- **Backup/restore** operations logging

## Security Considerations

1. **Never commit private keys** or mnemonics to version control
2. **Use environment variables** for sensitive data
3. **Encrypt backups** before IPFS upload
4. **Verify checksums** before wallet restoration
5. **Clear sensitive data** after use with `disconnect()`

## Support

For issues or questions:
- GitHub Issues: https://github.com/hannesmitterer/Peacebonds/issues
- Security Layer Documentation: `protocollo-meta-salvage/SECURITY_ENHANCEMENTS.md`
- Deployment Guide: `protocollo-meta-salvage/AUTODEPLOY.md`

---

**Version:** 1.0.0  
**Framework:** Euystacio v1.1  
**Last Updated:** January 2026
