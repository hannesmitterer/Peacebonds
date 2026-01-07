import { ethers, Contract, Wallet, JsonRpcProvider } from 'ethers';
import { BlockchainConfig } from '../utils/types.js';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * Loads the PeaceBondAnchor contract ABI
 * @returns Contract ABI
 */
function loadContractABI(): any[] {
  const artifactPath = join(
    __dirname,
    '../../artifacts/contracts/PeaceBondAnchor.sol/PeaceBondAnchor.json'
  );
  const artifact = JSON.parse(readFileSync(artifactPath, 'utf-8'));
  return artifact.abi;
}

/**
 * Creates a contract instance
 * @param contractAddress Contract address
 * @param config Blockchain configuration
 * @param withSigner Whether to attach a signer
 * @returns Contract instance
 */
export function getContract(
  contractAddress: string,
  config: BlockchainConfig,
  withSigner: boolean = false
): Contract {
  const provider = new JsonRpcProvider(config.rpcUrl);
  const abi = loadContractABI();
  
  if (withSigner && config.privateKey) {
    const wallet = new Wallet(config.privateKey, provider);
    return new Contract(contractAddress, abi, wallet);
  }
  
  return new Contract(contractAddress, abi, provider);
}

/**
 * Anchors a PeaceBond to the blockchain
 * @param manifestCID IPFS CID of the manifest
 * @param signatureCID IPFS CID of the signature file
 * @param config Blockchain configuration (must include privateKey)
 * @returns Transaction receipt and token ID
 */
export async function anchorPeaceBond(
  manifestCID: string,
  signatureCID: string,
  config: BlockchainConfig
): Promise<{ tokenId: bigint; txHash: string; receipt: any }> {
  if (!config.contractAddress) {
    throw new Error('Contract address required');
  }
  
  if (!config.privateKey) {
    throw new Error('Private key required for anchoring');
  }
  
  console.log('Anchoring PeaceBond to blockchain...');
  const contract = getContract(config.contractAddress, config, true);
  
  const tx = await contract.anchor(manifestCID, signatureCID);
  console.log(`Transaction sent: ${tx.hash}`);
  
  const receipt = await tx.wait();
  console.log('Transaction confirmed');
  
  // Extract token ID from PeaceBondAnchored event
  const event = receipt.logs.find((log: any) => {
    try {
      const parsed = contract.interface.parseLog(log);
      return parsed?.name === 'PeaceBondAnchored';
    } catch {
      return false;
    }
  });
  
  if (!event) {
    throw new Error('PeaceBondAnchored event not found in transaction');
  }
  
  const parsedEvent = contract.interface.parseLog(event);
  const tokenId = parsedEvent?.args[0];
  
  console.log(`PeaceBond anchored with Token ID: ${tokenId}`);
  
  return {
    tokenId,
    txHash: tx.hash,
    receipt,
  };
}

/**
 * Gets the total number of PeaceBonds created
 * @param contractAddress Contract address
 * @param config Blockchain configuration
 * @returns Total supply
 */
export async function getTotalSupply(
  contractAddress: string,
  config: BlockchainConfig
): Promise<bigint> {
  const contract = getContract(contractAddress, config);
  return await contract.totalSupply();
}
