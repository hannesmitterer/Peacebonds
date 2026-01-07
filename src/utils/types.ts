/**
 * Common types for PeaceBonds implementation
 */

export interface AnchorData {
  manifestCID: string;
  signatureCID: string;
  manifestHash: string;
  signatureHash: string;
  timestamp: number;
  creator: string;
}

export interface SignatureData {
  messageHash: string;
  signatures: {
    signature: string;
    signer: string;
    v: number;
    r: string;
    s: string;
  }[];
}

export interface VerificationResult {
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

export interface IPFSConfig {
  apiUrl?: string;
  gateway?: string;
  pinataApiKey?: string;
  pinataSecretKey?: string;
  infuraProjectId?: string;
  infuraProjectSecret?: string;
}

export interface BlockchainConfig {
  rpcUrl: string;
  privateKey?: string;
  contractAddress?: string;
}
