# IPFS Integration Guide

## Overview

The Seedbringer Treasury system now supports real IPFS storage through multiple pinning services:
- **Pinata** (recommended)
- **Web3.Storage**
- **Fallback**: Deterministic mock hashes for development

## Configuration

### Option 1: Pinata (Recommended)

1. Sign up at [Pinata.cloud](https://www.pinata.cloud/)
2. Get your API keys from the dashboard
3. Set environment variables:

```bash
export PINATA_API_KEY=your_api_key_here
export PINATA_SECRET_API_KEY=your_secret_key_here
```

### Option 2: Web3.Storage

1. Sign up at [Web3.Storage](https://web3.storage/)
2. Generate an API token
3. Set environment variable:

```bash
export WEB3_STORAGE_TOKEN=your_token_here
```

## Usage

The `storeToIPFS()` function automatically detects available credentials and uses the appropriate service:

```javascript
const treasuryService = require('./src/services/treasuryService');

const data = {
  balances: { eth: 10, btc: 0.5 },
  prices: { ethPrice: 2000, btcPrice: 40000 },
  timestamp: new Date().toISOString()
};

const ipfsHash = await treasuryService.storeToIPFS(data);
console.log('IPFS Hash:', ipfsHash);
// Retrieve via: https://ipfs.io/ipfs/{ipfsHash}
```

## Service Priority

The system tries services in this order:
1. **Pinata** - If `PINATA_API_KEY` and `PINATA_SECRET_API_KEY` are set
2. **Web3.Storage** - If `WEB3_STORAGE_TOKEN` is set
3. **Fallback** - Deterministic hash for development/testing

## Development Mode

Without credentials, the system generates **deterministic hashes** based on the data content. This is useful for:
- Local development
- Testing (same data always produces the same hash)
- CI/CD pipelines

The fallback hash is fully deterministic: identical data will always generate the same hash, making it suitable for testing.

## Retrieving Data

Once stored, retrieve your data from any IPFS gateway:

```
https://ipfs.io/ipfs/{hash}
https://gateway.pinata.cloud/ipfs/{hash}
https://cloudflare-ipfs.com/ipfs/{hash}
```

## Metadata

When using Pinata, the system automatically adds metadata:
- **name**: `treasury-snapshot-{timestamp}`
- **type**: `treasury-data`
- **timestamp**: ISO 8601 timestamp

## Error Handling

The service includes comprehensive error handling:
- API failures log warnings and fall back to next option
- Network errors are caught and logged
- Invalid credentials trigger fallback mode

## Best Practices

1. **Production**: Always use Pinata or Web3.Storage
2. **Staging**: Use real IPFS for integration testing
3. **Development**: Fallback mode is acceptable
4. **Security**: Never commit API keys to version control
5. **Monitoring**: Check logs for "No IPFS pinning service configured" warnings

## Troubleshooting

### "No IPFS pinning service configured"
- Set one of the environment variables listed above
- Verify credentials are valid
- Check network connectivity

### "Pinata API error" or "Web3.Storage API error"
- Verify API keys are correct
- Check API rate limits
- Ensure account is active and has available storage

### Data not accessible on IPFS gateways
- Wait a few minutes for IPFS network propagation
- Try different gateways
- Verify the hash is correct

## Example: Full Integration

```javascript
// Store treasury snapshot
const metrics = await treasuryService.getTreasuryMetrics();
const ipfsHash = await treasuryService.storeToIPFS(metrics);

// Notify via Discord/Telegram
await notificationService.notifyIPFSSnapshot(ipfsHash, metrics);

// Retrieve later
const data = await treasuryService.retrieveFromIPFS(ipfsHash);
```

## Cost Considerations

- **Pinata**: Free tier includes 1GB storage, paid plans for more
- **Web3.Storage**: Currently free for public data
- **Development fallback**: No cost, not persistent

## Security Notes

- IPFS data is **public** by default
- Do not store private keys or sensitive information
- Treasury data is intentionally public for transparency
- API keys should be stored securely in environment variables
