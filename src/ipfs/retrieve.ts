import { create } from 'ipfs-http-client';
import { IPFSConfig } from '../utils/types.js';
import { createIPFSClient } from './upload.js';

/**
 * Retrieves content from IPFS by CID
 * @param cid IPFS CID
 * @param config IPFS configuration
 * @returns Content as string
 */
export async function retrieveFromIPFS(
  cid: string,
  config: IPFSConfig = {}
): Promise<string> {
  const client = createIPFSClient(config);
  
  const chunks = [];
  for await (const chunk of client.cat(cid)) {
    chunks.push(chunk);
  }
  
  const buffer = Buffer.concat(chunks);
  return buffer.toString('utf-8');
}

/**
 * Retrieves manifest content from IPFS
 * @param manifestCID Manifest CID
 * @param config IPFS configuration
 * @returns Manifest content as string
 */
export async function retrieveManifest(
  manifestCID: string,
  config: IPFSConfig = {}
): Promise<string> {
  console.log(`Retrieving manifest from IPFS (CID: ${manifestCID})...`);
  const content = await retrieveFromIPFS(manifestCID, config);
  console.log('Manifest retrieved successfully');
  return content;
}

/**
 * Retrieves signature file from IPFS
 * @param signatureCID Signature file CID
 * @param config IPFS configuration
 * @returns Signature file content as string
 */
export async function retrieveSignature(
  signatureCID: string,
  config: IPFSConfig = {}
): Promise<string> {
  console.log(`Retrieving signature file from IPFS (CID: ${signatureCID})...`);
  const content = await retrieveFromIPFS(signatureCID, config);
  console.log('Signature file retrieved successfully');
  return content;
}

/**
 * Retrieves content from IPFS using HTTP gateway (fallback method)
 * @param cid IPFS CID
 * @param gateway Gateway URL (default: ipfs.io)
 * @returns Content as string
 */
export async function retrieveFromGateway(
  cid: string,
  gateway: string = 'https://ipfs.io'
): Promise<string> {
  const url = `${gateway}/ipfs/${cid}`;
  const response = await fetch(url);
  
  if (!response.ok) {
    throw new Error(`Failed to retrieve from gateway: ${response.statusText}`);
  }
  
  return await response.text();
}
