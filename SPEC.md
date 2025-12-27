# PeaceBonds / Euystacio Protocol v1.1

## Status
Open Source – Public Domain Implementation

## Abstract
PeaceBonds (Euystacio Protocol) is a minimal, open protocol for
public notarization and verification of manifest-like documents using:

- IPFS for content-addressed storage
- secp256k1 cryptographic signatures
- Ethereum-compatible blockchains for immutable anchoring

The protocol provides proof-of-existence, authorship attestation,
and public verifiability without reliance on trusted intermediaries.

## Components

### 1. Manifest
A human-readable document (e.g. manifesto.md) published on IPFS.

- Format: arbitrary (Markdown, text, JSON)
- Output: IPFS CID (manifestCID)

### 2. Triple Signature
A set of independent secp256k1 signatures over the manifest hash.

- At least 3 signers
- Stored as a single file on IPFS
- Output: IPFS CID (signatureCID)

### 3. Blockchain Anchor
A minimal ERC-721 smart contract that stores:
- manifestCID
- signatureCID
- keccak256 hashes of both

The NFT represents a unique, immutable anchoring event.

## Verification Procedure

1. Retrieve manifest via manifestCID from IPFS
2. Hash the manifest content
3. Retrieve signature file via signatureCID
4. Verify all secp256k1 signatures against the manifest hash
5. Verify that the CID hashes match the on-chain values
6. Confirm the anchoring transaction on-chain

If all steps succeed, the PeaceBond is valid.

## Non-Goals

- No enforcement of meaning or truth
- No consensus between AI models
- No governance or token economics
- No content moderation

## Security Model

- Integrity guaranteed by IPFS content addressing
- Authenticity guaranteed by cryptographic signatures
- Immutability guaranteed by blockchain anchoring

## License
MIT
