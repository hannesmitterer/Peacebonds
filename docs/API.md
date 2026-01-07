# API Reference

## Smart Contract API

### PeaceBondAnchor

ERC-721 smart contract for anchoring PeaceBonds.

#### Functions

##### `anchor(string manifestCID, string signatureCID) → uint256`

Creates a new PeaceBond NFT.

**Parameters:**
- `manifestCID` (string): IPFS CID of the manifest document
- `signatureCID` (string): IPFS CID of the signature file

**Returns:**
- `tokenId` (uint256): The ID of the newly minted PeaceBond NFT

**Events Emitted:**
- `PeaceBondAnchored(tokenId, manifestCID, signatureCID, manifestHash, signatureHash, creator, timestamp)`

**Example:**
```solidity
string memory manifestCID = "QmXXX...";
string memory signatureCID = "QmYYY...";
uint256 tokenId = contract.anchor(manifestCID, signatureCID);
```

##### `verify(uint256 tokenId, string manifestCID, string signatureCID) → bool`

Verifies that provided CIDs match the on-chain anchor data.

**Parameters:**
- `tokenId` (uint256): Token ID of the PeaceBond
- `manifestCID` (string): Manifest CID to verify
- `signatureCID` (string): Signature CID to verify

**Returns:**
- `bool`: True if both CIDs match the on-chain data

**Events Emitted:**
- `PeaceBondVerified(tokenId, verifier, isValid)`

**Example:**
```solidity
bool isValid = contract.verify(1, "QmXXX...", "QmYYY...");
```

##### `getAnchor(uint256 tokenId) → (string, string, bytes32, bytes32, uint256, address)`

Retrieves complete anchor data for a PeaceBond.

**Parameters:**
- `tokenId` (uint256): Token ID of the PeaceBond

**Returns:**
- `manifestCID` (string): IPFS CID of the manifest
- `signatureCID` (string): IPFS CID of the signature file
- `manifestHash` (bytes32): keccak256 hash of manifestCID
- `signatureHash` (bytes32): keccak256 hash of signatureCID
- `timestamp` (uint256): Block timestamp when anchored
- `creator` (address): Address that created the anchor

**Example:**
```solidity
(
    string memory manifestCID,
    string memory signatureCID,
    bytes32 manifestHash,
    bytes32 signatureHash,
    uint256 timestamp,
    address creator
) = contract.getAnchor(1);
```

##### `totalSupply() → uint256`

Returns the total number of PeaceBonds created.

**Returns:**
- `uint256`: Total supply of PeaceBond NFTs

## TypeScript/JavaScript API

### Signature Generation

#### `generateSignatures(manifestContent, privateKeys)`

Generates secp256k1 signatures for a manifest.

**Parameters:**
- `manifestContent` (string): The manifest content to sign
- `privateKeys` (string[]): Array of private keys (minimum 3)

**Returns:**
- `Promise<SignatureData>`: Object containing message hash and signatures

**Example:**
```typescript
import { generateSignatures } from './src/signature/generate.js';

const manifestContent = "# My Manifest\n...";
const privateKeys = ["0xabc...", "0xdef...", "0x123..."];

const signatures = await generateSignatures(manifestContent, privateKeys);
console.log(signatures.messageHash);
console.log(signatures.signatures); // Array of signature objects
```

#### `serializeSignatures(signatureData, manifestCID)`

Converts signature data to JSON format for IPFS storage.

**Parameters:**
- `signatureData` (SignatureData): Signature data object
- `manifestCID` (string): The manifest CID being signed

**Returns:**
- `string`: JSON string ready for IPFS upload

**Example:**
```typescript
import { serializeSignatures } from './src/signature/generate.js';

const json = serializeSignatures(signatures, "QmXXX...");
console.log(json); // Pretty-printed JSON
```

### Signature Verification

#### `verifySignatures(manifestContent, signatureFileContent)`

Verifies secp256k1 signatures against manifest content.

**Parameters:**
- `manifestContent` (string): Original manifest content
- `signatureFileContent` (string): Signature file JSON content

**Returns:**
- `Promise<{isValid: boolean, signers: string[], errors: string[]}>`

**Example:**
```typescript
import { verifySignatures } from './src/signature/verify.js';

const result = await verifySignatures(manifestContent, signatureJSON);
if (result.isValid) {
    console.log('Verified signers:', result.signers);
} else {
    console.log('Errors:', result.errors);
}
```

#### `validateSignatureStructure(signatureFileContent)`

Validates that signature file has required structure.

**Parameters:**
- `signatureFileContent` (string): Signature file content

**Returns:**
- `boolean`: True if structure is valid

### IPFS Integration

#### `uploadManifest(manifestContent, config?)`

Uploads a manifest file to IPFS.

**Parameters:**
- `manifestContent` (string): Manifest content as string
- `config` (IPFSConfig, optional): IPFS configuration

**Returns:**
- `Promise<string>`: Manifest CID

**Example:**
```typescript
import { uploadManifest } from './src/ipfs/upload.js';

const manifestCID = await uploadManifest(
    "# My Manifest\n...",
    { apiUrl: "http://127.0.0.1:5001" }
);
console.log(`Manifest CID: ${manifestCID}`);
```

#### `uploadSignature(signatureContent, config?)`

Uploads signature file to IPFS.

**Parameters:**
- `signatureContent` (string): Signature file content as JSON string
- `config` (IPFSConfig, optional): IPFS configuration

**Returns:**
- `Promise<string>`: Signature CID

#### `retrieveManifest(manifestCID, config?)`

Retrieves manifest content from IPFS.

**Parameters:**
- `manifestCID` (string): Manifest CID
- `config` (IPFSConfig, optional): IPFS configuration

**Returns:**
- `Promise<string>`: Manifest content as string

**Example:**
```typescript
import { retrieveManifest } from './src/ipfs/retrieve.js';

const content = await retrieveManifest("QmXXX...");
console.log(content);
```

#### `retrieveSignature(signatureCID, config?)`

Retrieves signature file from IPFS.

**Parameters:**
- `signatureCID` (string): Signature file CID
- `config` (IPFSConfig, optional): IPFS configuration

**Returns:**
- `Promise<string>`: Signature file content as string

#### `retrieveFromGateway(cid, gateway?)`

Retrieves content from IPFS using HTTP gateway (fallback method).

**Parameters:**
- `cid` (string): IPFS CID
- `gateway` (string, optional): Gateway URL (default: "https://ipfs.io")

**Returns:**
- `Promise<string>`: Content as string

### Blockchain Integration

#### `anchorPeaceBond(manifestCID, signatureCID, config)`

Anchors a PeaceBond to the blockchain.

**Parameters:**
- `manifestCID` (string): IPFS CID of the manifest
- `signatureCID` (string): IPFS CID of the signature file
- `config` (BlockchainConfig): Configuration object

**Returns:**
- `Promise<{tokenId: bigint, txHash: string, receipt: any}>`

**Example:**
```typescript
import { anchorPeaceBond } from './src/blockchain/anchor.js';

const result = await anchorPeaceBond(
    "QmXXX...",
    "QmYYY...",
    {
        rpcUrl: "https://ethereum-sepolia-rpc.publicnode.com",
        privateKey: "0x...",
        contractAddress: "0x..."
    }
);

console.log(`PeaceBond #${result.tokenId} created`);
console.log(`TX: ${result.txHash}`);
```

#### `verifyOnChain(tokenId, manifestCID, signatureCID, contractAddress, config)`

Verifies CIDs against on-chain data.

**Parameters:**
- `tokenId` (bigint): Token ID of the PeaceBond
- `manifestCID` (string): Manifest CID to verify
- `signatureCID` (string): Signature CID to verify
- `contractAddress` (string): Contract address
- `config` (BlockchainConfig): Configuration object

**Returns:**
- `Promise<boolean>`: True if verification succeeds

#### `getAnchorData(tokenId, contractAddress, config)`

Retrieves anchor data from blockchain.

**Parameters:**
- `tokenId` (bigint): Token ID of the PeaceBond
- `contractAddress` (string): Contract address
- `config` (BlockchainConfig): Configuration object

**Returns:**
- `Promise<AnchorData>`: Anchor data object

**Example:**
```typescript
import { getAnchorData } from './src/blockchain/verify.js';

const anchor = await getAnchorData(
    1n,
    "0x...",
    { rpcUrl: "https://ethereum-sepolia-rpc.publicnode.com" }
);

console.log(anchor.manifestCID);
console.log(anchor.signatureCID);
console.log(new Date(anchor.timestamp * 1000));
```

#### `verifyPeaceBond(tokenId, contractAddress, blockchainConfig)`

Performs complete 6-step verification of a PeaceBond.

**Parameters:**
- `tokenId` (bigint): Token ID of the PeaceBond
- `contractAddress` (string): Contract address
- `blockchainConfig` (BlockchainConfig): Configuration object

**Returns:**
- `Promise<VerificationResult>`: Detailed verification result

**Example:**
```typescript
import { verifyPeaceBond } from './src/blockchain/verify.js';

const result = await verifyPeaceBond(
    1n,
    "0x...",
    { rpcUrl: "https://ethereum-sepolia-rpc.publicnode.com" }
);

if (result.isValid) {
    console.log('✓ PeaceBond is valid');
    console.log('Signers:', result.details.signerAddresses);
} else {
    console.log('✗ PeaceBond is invalid');
    console.log('Errors:', result.details.errors);
}
```

### Utility Functions

#### `hashString(content)`

Computes the keccak256 hash of a string.

**Parameters:**
- `content` (string): Content to hash

**Returns:**
- `string`: keccak256 hash as hex string

**Example:**
```typescript
import { hashString } from './src/utils/hash.js';

const hash = hashString("QmXXX...");
console.log(hash); // 0x...
```

#### `hashBytes(data)`

Computes the keccak256 hash of binary data.

**Parameters:**
- `data` (Uint8Array): Data to hash

**Returns:**
- `string`: keccak256 hash as hex string

#### `verifyHash(content, expectedHash)`

Verifies that a hash matches the expected value.

**Parameters:**
- `content` (string): Content to hash
- `expectedHash` (string): Expected hash value

**Returns:**
- `boolean`: True if hashes match

## Type Definitions

### AnchorData

```typescript
interface AnchorData {
  manifestCID: string;
  signatureCID: string;
  manifestHash: string;
  signatureHash: string;
  timestamp: number;
  creator: string;
}
```

### SignatureData

```typescript
interface SignatureData {
  messageHash: string;
  signatures: {
    signature: string;
    signer: string;
    v: number;
    r: string;
    s: string;
  }[];
}
```

### VerificationResult

```typescript
interface VerificationResult {
  isValid: boolean;
  manifestVerified: boolean;
  signaturesVerified: boolean;
  onChainVerified: boolean;
  details: {
    manifestCID?: string;
    signatureCID?: string;
    signerAddresses?: string[];
    errors?: string[];
  };
}
```

### IPFSConfig

```typescript
interface IPFSConfig {
  apiUrl?: string;
  gateway?: string;
  pinataApiKey?: string;
  pinataSecretKey?: string;
  infuraProjectId?: string;
  infuraProjectSecret?: string;
}
```

### BlockchainConfig

```typescript
interface BlockchainConfig {
  rpcUrl: string;
  privateKey?: string;
  contractAddress?: string;
}
```

## CLI Commands

### create

```bash
peacebond create <manifest-file> [options]
```

**Arguments:**
- `<manifest-file>`: Path to manifest file

**Options:**
- `--signers <keys>`: Comma-separated private keys (min 3)
- `--network <network>`: Network (ethereum/polygon/etc) [default: "hardhat"]
- `--contract <address>`: Contract address
- `--ipfs-url <url>`: IPFS API URL

### verify

```bash
peacebond verify <tokenId> [options]
```

**Arguments:**
- `<tokenId>`: Token ID of the PeaceBond

**Options:**
- `--network <network>`: Network [default: "hardhat"]
- `--contract <address>`: Contract address
- `--ipfs-url <url>`: IPFS API URL

### get

```bash
peacebond get <tokenId> [options]
```

**Arguments:**
- `<tokenId>`: Token ID of the PeaceBond

**Options:**
- `--network <network>`: Network [default: "hardhat"]
- `--contract <address>`: Contract address

## Error Handling

All async functions may throw errors. Always use try-catch:

```typescript
try {
    const result = await anchorPeaceBond(...);
} catch (error) {
    console.error('Failed to anchor:', error.message);
}
```

Common errors:
- `IPFS connection failed`: Check IPFS daemon is running
- `Transaction failed`: Check wallet has sufficient funds
- `Contract not found`: Verify contract address
- `Insufficient signatures`: Need at least 3 signers
- `Signature verification failed`: Manifest was modified
