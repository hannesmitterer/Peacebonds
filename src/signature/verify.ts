import { verifyMessage, keccak256, toUtf8Bytes } from 'ethers';

/**
 * Verifies secp256k1 signatures against manifest content
 * @param manifestContent The original manifest content
 * @param signatureFileContent The signature file JSON content
 * @returns Verification result with signer addresses
 */
export async function verifySignatures(
  manifestContent: string,
  signatureFileContent: string
): Promise<{
  isValid: boolean;
  signers: string[];
  errors: string[];
}> {
  const errors: string[] = [];
  const signers: string[] = [];

  try {
    const signatureData = JSON.parse(signatureFileContent);

    // Verify manifest hash
    const expectedHash = keccak256(toUtf8Bytes(manifestContent));
    if (signatureData.messageHash !== expectedHash) {
      errors.push('Manifest hash mismatch');
      return { isValid: false, signers: [], errors };
    }

    // Verify each signature
    for (const sig of signatureData.signatures) {
      try {
        const recoveredAddress = verifyMessage(
          toUtf8Bytes(manifestContent),
          sig.signature
        );

        if (recoveredAddress.toLowerCase() === sig.signer.toLowerCase()) {
          signers.push(sig.signer);
        } else {
          errors.push(
            `Signature verification failed for ${sig.signer}: recovered ${recoveredAddress}`
          );
        }
      } catch (error) {
        errors.push(
          `Error verifying signature for ${sig.signer}: ${
            error instanceof Error ? error.message : String(error)
          }`
        );
      }
    }

    // Must have at least 3 valid signatures
    if (signers.length < 3) {
      errors.push(
        `Insufficient valid signatures: ${signers.length} (minimum 3 required)`
      );
      return { isValid: false, signers, errors };
    }

    return {
      isValid: errors.length === 0,
      signers,
      errors,
    };
  } catch (error) {
    errors.push(
      `Error parsing signature file: ${
        error instanceof Error ? error.message : String(error)
      }`
    );
    return { isValid: false, signers: [], errors };
  }
}

/**
 * Verifies that signature file has required structure
 * @param signatureFileContent The signature file content
 * @returns True if structure is valid
 */
export function validateSignatureStructure(
  signatureFileContent: string
): boolean {
  try {
    const data = JSON.parse(signatureFileContent);
    return (
      data.version &&
      data.protocol === 'PeaceBonds' &&
      data.messageHash &&
      Array.isArray(data.signatures) &&
      data.signatures.length >= 3
    );
  } catch {
    return false;
  }
}
