import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import * as dotenv from 'dotenv';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

async function main() {
  console.log('========================================');
  console.log('VCD-01 PeaceContributionEngine Deployment');
  console.log('========================================\n');

  // Load contract artifact
  const artifactPath = join(
    __dirname,
    '../artifacts/contracts/PeaceContributionEngine.sol/PeaceContributionEngine.json'
  );
  
  let artifact;
  try {
    artifact = JSON.parse(readFileSync(artifactPath, 'utf-8'));
  } catch (error) {
    console.error('Error: Contract artifact not found. Please run: npm run compile');
    process.exit(1);
  }

  // Connect to network
  const rpcUrl = process.env.SEPOLIA_RPC_URL || 'http://127.0.0.1:8545';
  const privateKey = process.env.PRIVATE_KEY;

  if (!privateKey) {
    throw new Error('PRIVATE_KEY not set in .env file');
  }

  const provider = new ethers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey, provider);

  console.log(`Deploying from address: ${wallet.address}`);
  
  // Check balance
  const balance = await provider.getBalance(wallet.address);
  console.log(`Wallet balance: ${ethers.formatEther(balance)} ETH`);
  
  if (balance === 0n) {
    console.error('\nError: Wallet has no ETH. Please fund your wallet with Sepolia testnet ETH.');
    console.error('Sepolia Faucets:');
    console.error('  - https://sepoliafaucet.com/');
    console.error('  - https://www.alchemy.com/faucets/ethereum-sepolia');
    process.exit(1);
  }

  console.log('\nDeploying PeaceContributionEngine contract...');
  console.log('This may take 30-60 seconds...\n');

  // Deploy contract (no constructor parameters needed)
  const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, wallet);
  
  try {
    const contract = await factory.deploy();
    console.log('Transaction sent. Waiting for confirmation...');
    
    await contract.waitForDeployment();
    const address = await contract.getAddress();

    console.log('\n========================================');
    console.log('✓ Deployment Successful!');
    console.log('========================================\n');
    console.log(`Contract Address: ${address}`);
    console.log(`Network: ${rpcUrl.includes('sepolia') ? 'Sepolia Testnet' : 'Local'}`);
    console.log(`Deployer: ${wallet.address}`);
    console.log(`Transaction: ${contract.deploymentTransaction()?.hash}`);

    console.log('\n========================================');
    console.log('Next Steps:');
    console.log('========================================\n');
    console.log('1. Save the contract address to your .env file:');
    console.log(`   PEACE_CONTRIBUTION_ENGINE_ADDRESS=${address}\n`);
    
    console.log('2. Verify the contract on Etherscan (Sepolia):');
    console.log(`   npx hardhat verify --network sepolia ${address}\n`);
    
    console.log('3. Grant OPERATOR role to VE Operators:');
    console.log(`   Use the grantRole function with OPERATOR_ROLE hash`);
    console.log(`   OPERATOR_ROLE: ${ethers.keccak256(ethers.toUtf8Bytes('OPERATOR_ROLE'))}\n`);
    
    console.log('4. Grant VALIDATOR role to validators:');
    console.log(`   Use the grantRole function with VALIDATOR_ROLE hash`);
    console.log(`   VALIDATOR_ROLE: ${ethers.keccak256(ethers.toUtf8Bytes('VALIDATOR_ROLE'))}\n`);
    
    console.log('5. Set up multi-sig wallets (Gnosis Safe):');
    console.log('   - LOGOS Council: 5/9 multi-sig');
    console.log('   - VE Operators: 3/5 multi-sig\n');
    
    console.log('6. Test the contract:');
    console.log('   - Make a test contribution');
    console.log('   - Mint a Proof of Impact NFT');
    console.log('   - Verify category allocations\n');

    console.log('========================================');
    console.log('Contract Information:');
    console.log('========================================\n');
    console.log(`Contribution Rate: 2.7% (27/1000)`);
    console.log(`Integrity Threshold: 98.4% (984/1000)`);
    console.log(`\nCategory Allocations:`);
    console.log(`  - IDRO: 40%`);
    console.log(`  - HELIOS: 35%`);
    console.log(`  - R&D: 15%`);
    console.log(`  - Operations: 10%`);

    console.log('\n========================================\n');

  } catch (error: any) {
    console.error('\n========================================');
    console.error('Deployment Failed');
    console.error('========================================\n');
    console.error('Error:', error.message);
    
    if (error.message.includes('insufficient funds')) {
      console.error('\nYour wallet does not have enough ETH for gas fees.');
      console.error('Please fund your wallet with Sepolia testnet ETH.');
    }
    
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
