const { ethers } = require('hardhat');
const fs = require('fs');
const path = require('path');

async function main() {
  console.log('Minting PeaceBond #001...\n');

  // Load deployment information
  const deploymentPath = path.join(__dirname, '../deployed_addresses.json');
  
  if (!fs.existsSync(deploymentPath)) {
    throw new Error('deployed_addresses.json not found. Please deploy the contract first.');
  }
  
  const deploymentData = JSON.parse(fs.readFileSync(deploymentPath, 'utf8'));
  const contractAddress = deploymentData.PeaceBondAnchor?.contractAddress;
  
  if (!contractAddress) {
    throw new Error('Contract address not found in deployed_addresses.json');
  }
  
  console.log(`Contract Address: ${contractAddress}`);
  console.log(`Network: Sepolia (Euystacio Protocol v1.1)\n`);
  
  // Get contract instance
  const PeaceBondAnchor = await ethers.getContractFactory('PeaceBondAnchor');
  const contract = PeaceBondAnchor.attach(contractAddress);
  
  // IPFS CIDs - Example valid format (46 characters starting with Qm)
  // IMPORTANT: Replace these with your actual IPFS CIDs before minting
  // Example format: QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG
  const manifestCID = 'QmPeaceBondManifest001ExampleCIDReplace46Char';
  const signatureCID = 'QmPeaceBondSignatur001ExampleCIDReplace46Char';
  
  console.log('⚠️  IMPORTANT: Replace placeholder CIDs with actual IPFS CIDs');
  console.log('   Valid IPFS CID format: Qm followed by 44 base58 characters (46 total)');
  console.log(`   Manifest CID: ${manifestCID}`);
  console.log(`   Signature CID: ${signatureCID}\n`);
  
  console.log('Invoking anchor() function...');
  
  // Call the anchor function
  const tx = await contract.anchor(manifestCID, signatureCID);
  console.log(`Transaction submitted: ${tx.hash}`);
  console.log('Waiting for confirmation...\n');
  
  const receipt = await tx.wait();
  
  // Extract TokenID from the event
  const event = receipt.logs.find(log => {
    try {
      const parsedLog = contract.interface.parseLog(log);
      return parsedLog && parsedLog.name === 'PeaceBondAnchored';
    } catch (e) {
      return false;
    }
  });
  
  let tokenId = null;
  if (event) {
    const parsedLog = contract.interface.parseLog(event);
    tokenId = parsedLog.args.tokenId.toString();
  }
  
  console.log('✓ PeaceBond #001 successfully anchored!');
  console.log('─────────────────────────────────────────────────────');
  console.log(`Token ID: ${tokenId || 'Check transaction receipt'}`);
  console.log(`Transaction Hash: ${receipt.hash}`);
  console.log(`Block Number: ${receipt.blockNumber}`);
  console.log(`Etherscan: https://sepolia.etherscan.io/tx/${receipt.hash}`);
  console.log('─────────────────────────────────────────────────────\n');
  
  console.log('PeaceBond #001 Details:');
  console.log(`- Manifest: ipfs://${manifestCID}`);
  console.log(`- Signature: ipfs://${signatureCID}`);
  console.log(`- Status: Notarized on Sepolia blockchain\n`);
  
  // Update deployed_addresses.json with first PeaceBond info
  deploymentData.firstPeaceBond = {
    tokenId: tokenId,
    manifestCID: manifestCID,
    signatureCID: signatureCID,
    transactionHash: receipt.hash,
    blockNumber: receipt.blockNumber,
    mintedAt: new Date().toISOString()
  };
  
  fs.writeFileSync(deploymentPath, JSON.stringify(deploymentData, null, 2));
  console.log('✓ PeaceBond info saved to deployed_addresses.json\n');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('\n❌ Error:', error.message);
    process.exit(1);
  });
