import { Wallet, keccak256, toUtf8Bytes, Signature } from 'ethers';
import { SignatureData } from '../utils/types.js';

/**
 * Generates secp256k1 signatures for a manifest
 * @param manifestContent The manifest content to sign
 * @param privateKeys Array of private keys (at least 3)
 * @returns Signature data structure
 */
export async function generateSignatures(
  manifestContent: string,
  privateKeys: string[]
): Promise<SignatureData> {
  if (privateKeys.length < 3) {
    throw new Error('At least 3 private keys required for triple signature');
  }

  // Hash the manifest content
  const messageHash = keccak256(toUtf8Bytes(manifestContent));

  const signatures = await Promise.all(
    privateKeys.map(async (privateKey) => {
      const wallet = new Wallet(privateKey);
      const sig = await wallet.signMessage(toUtf8Bytes(manifestContent));
      const signature = Signature.from(sig);

      return {
        signature: sig,
        signer: wallet.address,
        v: signature.v,
        r: signature.r,
        s: signature.s,
      };
    })
  );

  return {
    messageHash,
    signatures,
  };
}

/**
 * Converts signature data to JSON format for IPFS storage
 * @param signatureData The signature data
 * @param manifestCID The manifest CID being signed
 * @returns JSON string
 */
export function serializeSignatures(
  signatureData: SignatureData,
  manifestCID: string
): string {
  return JSON.stringify(
    {
      version: '1.0',
      protocol: 'PeaceBonds',
      manifestCID,
      messageHash: signatureData.messageHash,
      signatures: signatureData.signatures.map((sig) => ({
        signature: sig.signature,
        signer: sig.signer,
        v: sig.v,
        r: sig.r,
        s: sig.s,
      })),
      timestamp: new Date().toISOString(),
    },
    null,
    2
  );
}
