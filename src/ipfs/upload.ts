import { create } from 'ipfs-http-client';
import { IPFSConfig } from '../utils/types.js';

/**
 * Creates an IPFS client based on configuration
 * @param config IPFS configuration
 * @returns IPFS client instance
 */
export function createIPFSClient(config: IPFSConfig) {
  const url = config.apiUrl || 'http://127.0.0.1:5001';
  
  // Use Infura if credentials provided
  if (config.infuraProjectId && config.infuraProjectSecret) {
    const auth =
      'Basic ' +
      Buffer.from(
        config.infuraProjectId + ':' + config.infuraProjectSecret
      ).toString('base64');
    
    return create({
      url: 'https://ipfs.infura.io:5001',
      headers: {
        authorization: auth,
      },
    });
  }
  
  // Use Pinata if credentials provided
  if (config.pinataApiKey && config.pinataSecretKey) {
    return create({
      url: 'https://api.pinata.cloud',
      headers: {
        pinata_api_key: config.pinataApiKey,
        pinata_secret_api_key: config.pinataSecretKey,
      },
    });
  }
  
  // Default to local node
  return create({ url });
}

/**
 * Uploads content to IPFS
 * @param content Content to upload (string or Buffer)
 * @param config IPFS configuration
 * @returns IPFS CID
 */
export async function uploadToIPFS(
  content: string | Buffer,
  config: IPFSConfig = {}
): Promise<string> {
  const client = createIPFSClient(config);
  
  const buffer = typeof content === 'string' ? Buffer.from(content, 'utf-8') : content;
  
  const result = await client.add(buffer);
  return result.path; // This is the CID
}

/**
 * Uploads a manifest file to IPFS
 * @param manifestContent Manifest content as string
 * @param config IPFS configuration
 * @returns Manifest CID
 */
export async function uploadManifest(
  manifestContent: string,
  config: IPFSConfig = {}
): Promise<string> {
  console.log('Uploading manifest to IPFS...');
  const cid = await uploadToIPFS(manifestContent, config);
  console.log(`Manifest uploaded with CID: ${cid}`);
  return cid;
}

/**
 * Uploads signature file to IPFS
 * @param signatureContent Signature file content as JSON string
 * @param config IPFS configuration
 * @returns Signature CID
 */
export async function uploadSignature(
  signatureContent: string,
  config: IPFSConfig = {}
): Promise<string> {
  console.log('Uploading signature file to IPFS...');
  const cid = await uploadToIPFS(signatureContent, config);
  console.log(`Signature file uploaded with CID: ${cid}`);
  return cid;
}
