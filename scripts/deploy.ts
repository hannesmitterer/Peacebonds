import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import * as dotenv from 'dotenv';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

async function main() {
  console.log('Deploying PeaceBondAnchor contract...');

  // Load contract artifact
  const artifactPath = join(
    __dirname,
    '../artifacts/contracts/PeaceBondAnchor.sol/PeaceBondAnchor.json'
  );
  const artifact = JSON.parse(readFileSync(artifactPath, 'utf-8'));

  // Connect to network
  const rpcUrl = process.env.SEPOLIA_RPC_URL || 'http://127.0.0.1:8545';
  const privateKey = process.env.PRIVATE_KEY;

  if (!privateKey) {
    throw new Error('PRIVATE_KEY not set in .env');
  }

  const provider = new ethers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey, provider);

  console.log(`Deploying from address: ${wallet.address}`);

  // Deploy contract
  const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, wallet);
  const contract = await factory.deploy();

  await contract.waitForDeployment();

  const address = await contract.getAddress();

  console.log(`\n✓ PeaceBondAnchor deployed to: ${address}`);
  console.log('\nSave this address to your .env file:');
  console.log(`PEACEBOND_CONTRACT_ADDRESS=${address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
