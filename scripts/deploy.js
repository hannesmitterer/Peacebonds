const { ethers } = require('hardhat');
const fs = require('fs');
const path = require('path');

async function main() {
  console.log('Deploying PeaceBondAnchor contract to Sepolia...\n');

  // Get the contract factory
  const PeaceBondAnchor = await ethers.getContractFactory('PeaceBondAnchor');
  
  // Deploy the contract
  console.log('Initiating deployment...');
  const contract = await PeaceBondAnchor.deploy();
  
  await contract.waitForDeployment();
  
  const contractAddress = await contract.getAddress();
  
  // Treasury wallet address - Reference for future economic layer integration
  // Note: Current PeaceBondAnchor.sol is pure notarization; treasury will be used in future economic extensions
  const treasuryWallet = '0x5d61a4B25034393A37ef9307C8Ba3aE99e49944b';
  
  console.log('\n✓ Deployment successful!');
  console.log('─────────────────────────────────────────────────────');
  console.log(`Contract Address: ${contractAddress}`);
  console.log(`Treasury Reference: ${treasuryWallet}`);
  console.log(`Network: Sepolia (Euystacio Protocol v1.1)`);
  console.log(`Etherscan: https://sepolia.etherscan.io/address/${contractAddress}`);
  console.log('─────────────────────────────────────────────────────\n');
  
  // Save deployment information to deployed_addresses.json
  const deploymentInfo = {
    network: 'sepolia',
    contractAddress: contractAddress,
    treasuryWallet: treasuryWallet,
    deployedAt: new Date().toISOString(),
    etherscanUrl: `https://sepolia.etherscan.io/address/${contractAddress}`
  };
  
  const outputPath = path.join(__dirname, '../deployed_addresses.json');
  
  // Check if file exists and read existing data
  let existingData = {};
  if (fs.existsSync(outputPath)) {
    const fileContent = fs.readFileSync(outputPath, 'utf8');
    try {
      existingData = JSON.parse(fileContent);
    } catch (e) {
      console.log('Creating new deployed_addresses.json file...');
    }
  }
  
  // Merge with existing data
  existingData.PeaceBondAnchor = deploymentInfo;
  
  fs.writeFileSync(outputPath, JSON.stringify(existingData, null, 2));
  console.log(`✓ Deployment info saved to: ${outputPath}\n`);
  
  console.log('Next steps:');
  console.log('1. Verify the contract on Etherscan (optional)');
  console.log('2. Update your .env file with the contract address');
  console.log('3. Run the mint script to create your first PeaceBond\n');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
