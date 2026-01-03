# PeaceBonds (Euystacio Protocol) v1.1

A minimal, open protocol for public notarization and verification of manifest-like documents using IPFS, cryptographic signatures, and blockchain anchoring.

## Overview

PeaceBonds provides:
- **Proof-of-existence**: Immutable record of document publication
- **Authorship attestation**: Cryptographic signatures from multiple signers
- **Public verifiability**: Anyone can verify without trusted intermediaries

## Features

- ✅ ERC-721 smart contract for blockchain anchoring
- ✅ IPFS integration for content-addressed storage
- ✅ secp256k1 signature generation and verification
- ✅ CLI tool for creating and verifying PeaceBonds
- ✅ Complete 6-step verification procedure
- ✅ Support for multiple blockchain networks

## Installation

```bash
npm install
npm run compile
npm run build
```

## Quick Start

### 1. Create a PeaceBond

```bash
# Create .env file with your configuration
cp .env.example .env

# Edit your manifest
nano examples/manifests/my-manifest.md

# Create and anchor a PeaceBond
node dist/cli/index.js create examples/manifests/my-manifest.md \
  --contract YOUR_CONTRACT_ADDRESS \
  --network sepolia
```

### 2. Verify a PeaceBond

```bash
node dist/cli/index.js verify TOKEN_ID \
  --contract YOUR_CONTRACT_ADDRESS \
  --network sepolia
```

### 3. Get PeaceBond Details

```bash
node dist/cli/index.js get TOKEN_ID \
  --contract YOUR_CONTRACT_ADDRESS \
  --network sepolia
```

## Architecture

```
┌─────────────┐
│   Manifest  │
│  (Document) │
└─────┬───────┘
      │
      ├─ Hash with keccak256
      │
      ├─ Sign with 3+ secp256k1 keys
      │
      ├─ Upload to IPFS → manifestCID
      │
      ├─ Upload signatures to IPFS → signatureCID
      │
      └─ Anchor to blockchain (ERC-721)
            │
            ├─ Store manifestCID
            ├─ Store signatureCID
            ├─ Store keccak256(manifestCID)
            └─ Store keccak256(signatureCID)
```

## Components

### Smart Contract
- **PeaceBondAnchor.sol**: ERC-721 contract for anchoring
- Functions: `anchor()`, `verify()`, `getAnchor()`
- Emits events for indexing and verification

### TypeScript/JavaScript
- **Signature utilities**: Generate and verify secp256k1 signatures
- **IPFS utilities**: Upload and retrieve content
- **Blockchain utilities**: Anchor and verify on-chain
- **CLI tool**: User-friendly command-line interface

## Verification Procedure

PeaceBonds implements a 6-step verification procedure:

1. Retrieve manifest via manifestCID from IPFS
2. Hash the manifest content
3. Retrieve signature file via signatureCID  
4. Verify all secp256k1 signatures against the manifest hash
5. Verify that the CID hashes match the on-chain values
6. Confirm the anchoring transaction on-chain

If all steps succeed, the PeaceBond is valid.

## Configuration

See `.env.example` for configuration options:
- Blockchain RPC URLs
- IPFS endpoints (local, Infura, Pinata)
- Private keys
- Contract addresses

## Development

```bash
# Compile smart contracts
npm run compile

# Build TypeScript
npm run build

# Run tests
npm test

# Clean build artifacts
npm run clean
```

## Documentation

- **SPEC.md**: Protocol specification
- **USAGE.md**: Detailed usage examples (coming soon)
- **API.md**: API reference (coming soon)
- **ARCHITECTURE.md**: System architecture (coming soon)

## License

MIT - See SPEC.md for details

## Non-Goals

- No enforcement of meaning or truth
- No consensus between AI models
- No governance or token economics
- No content moderation

## Security Model

- **Integrity**: Guaranteed by IPFS content addressing
- **Authenticity**: Guaranteed by cryptographic signatures
- **Immutability**: Guaranteed by blockchain anchoring

## Contributing

This is a reference implementation. Contributions welcome!

## References

- Specification: `SPEC.md`
- ERC-721: https://eips.ethereum.org/EIPS/eip-721
- IPFS: https://docs.ipfs.tech/
- secp256k1: https://en.bitcoin.it/wiki/Secp256k1
