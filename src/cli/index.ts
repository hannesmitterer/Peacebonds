#!/usr/bin/env node

import { Command } from 'commander';
import { config as dotenvConfig } from 'dotenv';
import { readFileSync } from 'fs';
import { Wallet } from 'ethers';
import { generateSignatures, serializeSignatures } from '../signature/generate.js';
import { uploadManifest, uploadSignature } from '../ipfs/upload.js';
import { anchorPeaceBond } from '../blockchain/anchor.js';
import { verifyPeaceBond, getAnchorData } from '../blockchain/verify.js';

dotenvConfig();

const program = new Command();

program
  .name('peacebond')
  .description('PeaceBonds (Euystacio Protocol) CLI')
  .version('1.0.0');

/**
 * Create command: Creates a new PeaceBond
 */
program
  .command('create')
  .description('Create a new PeaceBond')
  .argument('<manifest-file>', 'Path to manifest file')
  .option('--signers <keys>', 'Comma-separated private keys (min 3)', '')
  .option('--network <network>', 'Network (ethereum/polygon/etc)', 'hardhat')
  .option('--contract <address>', 'Contract address', process.env.PEACEBOND_CONTRACT_ADDRESS)
  .option('--ipfs-url <url>', 'IPFS API URL', process.env.IPFS_API_URL)
  .action(async (manifestFile, options) => {
    try {
      console.log('\n=== Creating PeaceBond ===\n');

      // Read manifest
      console.log(`Reading manifest from ${manifestFile}...`);
      const manifestContent = readFileSync(manifestFile, 'utf-8');

      // Parse private keys
      let privateKeys: string[] = [];
      if (options.signers) {
        privateKeys = options.signers.split(',').map((k: string) => k.trim());
      } else {
        // Generate 3 random keys for testing
        console.log('No signers provided, generating 3 random keys...');
        privateKeys = [
          Wallet.createRandom().privateKey,
          Wallet.createRandom().privateKey,
          Wallet.createRandom().privateKey,
        ];
        console.log('Generated signers:');
        privateKeys.forEach((pk, i) => {
          const wallet = new Wallet(pk);
          console.log(`  Signer ${i + 1}: ${wallet.address}`);
        });
      }

      if (privateKeys.length < 3) {
        throw new Error('At least 3 signers required');
      }

      // Upload manifest to IPFS
      console.log('\nUploading manifest to IPFS...');
      const manifestCID = await uploadManifest(manifestContent, {
        apiUrl: options.ipfsUrl,
      });

      // Generate signatures
      console.log('\nGenerating signatures...');
      const signatures = await generateSignatures(manifestContent, privateKeys);
      const signatureJSON = serializeSignatures(signatures, manifestCID);

      // Upload signatures to IPFS
      console.log('\nUploading signatures to IPFS...');
      const signatureCID = await uploadSignature(signatureJSON, {
        apiUrl: options.ipfsUrl,
      });

      // Anchor to blockchain
      if (!options.contract) {
        console.log('\n⚠ No contract address provided. Skipping blockchain anchoring.');
        console.log('\nPeaceBond Created (not anchored):');
        console.log(`  Manifest CID:  ${manifestCID}`);
        console.log(`  Signature CID: ${signatureCID}`);
        return;
      }

      const rpcUrl = getRpcUrl(options.network);
      const privateKey = process.env.PRIVATE_KEY || privateKeys[0];

      console.log('\nAnchoring to blockchain...');
      const result = await anchorPeaceBond(manifestCID, signatureCID, {
        rpcUrl,
        privateKey,
        contractAddress: options.contract,
      });

      console.log('\n✓ PeaceBond Created Successfully!');
      console.log(`  Token ID:      ${result.tokenId}`);
      console.log(`  Manifest CID:  ${manifestCID}`);
      console.log(`  Signature CID: ${signatureCID}`);
      console.log(`  TX Hash:       ${result.txHash}`);
    } catch (error) {
      console.error('\n✗ Error:', error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

/**
 * Verify command: Verifies an existing PeaceBond
 */
program
  .command('verify')
  .description('Verify an existing PeaceBond')
  .argument('<tokenId>', 'Token ID of the PeaceBond')
  .option('--network <network>', 'Network (ethereum/polygon/etc)', 'hardhat')
  .option('--contract <address>', 'Contract address', process.env.PEACEBOND_CONTRACT_ADDRESS)
  .option('--ipfs-url <url>', 'IPFS API URL', process.env.IPFS_API_URL)
  .action(async (tokenId, options) => {
    try {
      console.log(`\n=== Verifying PeaceBond #${tokenId} ===\n`);

      if (!options.contract) {
        throw new Error('Contract address required (--contract or PEACEBOND_CONTRACT_ADDRESS)');
      }

      const rpcUrl = getRpcUrl(options.network);

      const result = await verifyPeaceBond(BigInt(tokenId), options.contract, {
        rpcUrl,
      });

      if (result.isValid) {
        console.log('\n✓ PeaceBond is VALID');
        process.exit(0);
      } else {
        console.log('\n✗ PeaceBond is INVALID');
        if (result.details.errors) {
          console.log('Errors:');
          result.details.errors.forEach((err: string) => console.log(`  - ${err}`));
        }
        process.exit(1);
      }
    } catch (error) {
      console.error('\n✗ Error:', error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

/**
 * Get command: Retrieves PeaceBond details
 */
program
  .command('get')
  .description('Get details of a PeaceBond')
  .argument('<tokenId>', 'Token ID of the PeaceBond')
  .option('--network <network>', 'Network (ethereum/polygon/etc)', 'hardhat')
  .option('--contract <address>', 'Contract address', process.env.PEACEBOND_CONTRACT_ADDRESS)
  .action(async (tokenId, options) => {
    try {
      console.log(`\n=== PeaceBond #${tokenId} Details ===\n`);

      if (!options.contract) {
        throw new Error('Contract address required (--contract or PEACEBOND_CONTRACT_ADDRESS)');
      }

      const rpcUrl = getRpcUrl(options.network);

      const anchor = await getAnchorData(BigInt(tokenId), options.contract, {
        rpcUrl,
      });

      console.log('Manifest CID:  ', anchor.manifestCID);
      console.log('Signature CID: ', anchor.signatureCID);
      console.log('Manifest Hash: ', anchor.manifestHash);
      console.log('Signature Hash:', anchor.signatureHash);
      console.log('Timestamp:     ', new Date(anchor.timestamp * 1000).toISOString());
      console.log('Creator:       ', anchor.creator);
    } catch (error) {
      console.error('\n✗ Error:', error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

/**
 * Helper to get RPC URL for network
 */
function getRpcUrl(network: string): string {
  const urls: { [key: string]: string } = {
    hardhat: 'http://127.0.0.1:8545',
    localhost: 'http://127.0.0.1:8545',
    sepolia: process.env.SEPOLIA_RPC_URL || 'https://ethereum-sepolia-rpc.publicnode.com',
    polygon: process.env.POLYGON_RPC_URL || 'https://polygon-rpc.com',
  };

  return urls[network] || urls.hardhat;
}

program.parse();
