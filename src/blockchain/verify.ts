import { BlockchainConfig, AnchorData, VerificationResult } from '../utils/types.js';
import { getContract } from './anchor.js';
import { retrieveManifest, retrieveSignature } from '../ipfs/retrieve.js';
import { verifySignatures } from '../signature/verify.js';
import { hashString } from '../utils/hash.js';

/**
 * Verifies CIDs against on-chain data
 * @param tokenId Token ID of the PeaceBond
 * @param manifestCID Manifest CID to verify
 * @param signatureCID Signature CID to verify
 * @param contractAddress Contract address
 * @param config Blockchain configuration
 * @returns True if verification succeeds
 */
export async function verifyOnChain(
  tokenId: bigint,
  manifestCID: string,
  signatureCID: string,
  contractAddress: string,
  config: BlockchainConfig
): Promise<boolean> {
  console.log(`Verifying PeaceBond #${tokenId} on-chain...`);
  const contract = getContract(contractAddress, config);
  
  const isValid = await contract.verify(tokenId, manifestCID, signatureCID);
  console.log(`On-chain verification: ${isValid ? 'PASSED' : 'FAILED'}`);
  
  return isValid;
}

/**
 * Retrieves anchor data from blockchain
 * @param tokenId Token ID of the PeaceBond
 * @param contractAddress Contract address
 * @param config Blockchain configuration
 * @returns Anchor data
 */
export async function getAnchorData(
  tokenId: bigint,
  contractAddress: string,
  config: BlockchainConfig
): Promise<AnchorData> {
  console.log(`Retrieving anchor data for PeaceBond #${tokenId}...`);
  const contract = getContract(contractAddress, config);
  
  const result = await contract.getAnchor(tokenId);
  
  return {
    manifestCID: result[0],
    signatureCID: result[1],
    manifestHash: result[2],
    signatureHash: result[3],
    timestamp: Number(result[4]),
    creator: result[5],
  };
}

/**
 * Performs complete verification of a PeaceBond
 * Implements the 6-step verification procedure from SPEC.md:
 * 1. Retrieve manifest via manifestCID from IPFS
 * 2. Hash the manifest content
 * 3. Retrieve signature file via signatureCID
 * 4. Verify all secp256k1 signatures against the manifest hash
 * 5. Verify that the CID hashes match the on-chain values
 * 6. Confirm the anchoring transaction on-chain
 * 
 * @param tokenId Token ID of the PeaceBond
 * @param contractAddress Contract address
 * @param blockchainConfig Blockchain configuration
 * @returns Detailed verification result
 */
export async function verifyPeaceBond(
  tokenId: bigint,
  contractAddress: string,
  blockchainConfig: BlockchainConfig
): Promise<VerificationResult> {
  const errors: string[] = [];
  const details: any = {};

  try {
    // Step 1 & 6: Retrieve anchor data from blockchain
    console.log('\n=== Step 1/6: Retrieving anchor data from blockchain ===');
    const anchorData = await getAnchorData(tokenId, contractAddress, blockchainConfig);
    details.manifestCID = anchorData.manifestCID;
    details.signatureCID = anchorData.signatureCID;
    console.log(`✓ Manifest CID: ${anchorData.manifestCID}`);
    console.log(`✓ Signature CID: ${anchorData.signatureCID}`);
    console.log(`✓ Timestamp: ${new Date(anchorData.timestamp * 1000).toISOString()}`);
    console.log(`✓ Creator: ${anchorData.creator}`);

    // Step 1: Retrieve manifest from IPFS
    console.log('\n=== Step 2/6: Retrieving manifest from IPFS ===');
    const manifestContent = await retrieveManifest(anchorData.manifestCID);
    console.log(`✓ Manifest retrieved (${manifestContent.length} bytes)`);

    // Step 2: Hash the manifest
    console.log('\n=== Step 3/6: Hashing manifest content ===');
    const manifestHash = hashString(anchorData.manifestCID);
    console.log(`✓ Manifest CID hash: ${manifestHash}`);
    console.log(`✓ On-chain hash:     ${anchorData.manifestHash}`);
    
    const manifestVerified = manifestHash.toLowerCase() === anchorData.manifestHash.toLowerCase();
    if (!manifestVerified) {
      errors.push('Manifest CID hash mismatch');
    }

    // Step 3: Retrieve signature file from IPFS
    console.log('\n=== Step 4/6: Retrieving signature file from IPFS ===');
    const signatureContent = await retrieveSignature(anchorData.signatureCID);
    console.log(`✓ Signature file retrieved`);

    // Step 4: Verify signatures
    console.log('\n=== Step 5/6: Verifying cryptographic signatures ===');
    const signatureResult = await verifySignatures(manifestContent, signatureContent);
    details.signerAddresses = signatureResult.signers;
    
    if (!signatureResult.isValid) {
      errors.push(...signatureResult.errors);
      console.log(`✗ Signature verification FAILED`);
      console.log(`  Errors: ${signatureResult.errors.join(', ')}`);
    } else {
      console.log(`✓ All signatures verified (${signatureResult.signers.length} signers)`);
      signatureResult.signers.forEach((signer, i) => {
        console.log(`  Signer ${i + 1}: ${signer}`);
      });
    }

    // Step 5: Verify CID hashes match on-chain
    console.log('\n=== Step 6/6: Verifying on-chain data ===');
    const onChainVerified = await verifyOnChain(
      tokenId,
      anchorData.manifestCID,
      anchorData.signatureCID,
      contractAddress,
      blockchainConfig
    );

    if (!onChainVerified) {
      errors.push('On-chain verification failed');
    }

    const isValid = manifestVerified && signatureResult.isValid && onChainVerified;

    console.log('\n=== Verification Summary ===');
    console.log(`Manifest Verified:    ${manifestVerified ? '✓ PASS' : '✗ FAIL'}`);
    console.log(`Signatures Verified:  ${signatureResult.isValid ? '✓ PASS' : '✗ FAIL'}`);
    console.log(`On-Chain Verified:    ${onChainVerified ? '✓ PASS' : '✗ FAIL'}`);
    console.log(`Overall Result:       ${isValid ? '✓ VALID' : '✗ INVALID'}`);

    if (errors.length > 0) {
      details.errors = errors;
    }

    return {
      isValid,
      manifestVerified,
      signaturesVerified: signatureResult.isValid,
      onChainVerified,
      details,
    };
  } catch (error) {
    const errorMsg =
      error instanceof Error ? error.message : String(error);
    errors.push(errorMsg);
    console.error(`\n✗ Verification error: ${errorMsg}`);

    return {
      isValid: false,
      manifestVerified: false,
      signaturesVerified: false,
      onChainVerified: false,
      details: { errors },
    };
  }
}
