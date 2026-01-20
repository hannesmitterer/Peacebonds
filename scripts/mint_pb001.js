const hre = require("hardhat");

async function main() {
  const contractAddress = "INSERISCI_INDIRIZZO_DOPO_DEPLOY"; // Lo aggiorneremo dopo il deploy
  const [signer] = await hre.ethers.getSigners();

  console.log("Minting PeaceBond #001...");
  console.log("Account:", signer.address);

  // CIDs di esempio per il Manifesto IDRO e la firma
  const manifestCID = "QmP56v9LNRyLpA1W4PzF6N2J4zGzVzRzS1T2U3V4W5X6Y7"; 
  const signatureCID = "QmZ8v9LNRyLpA1W4PzF6N2J4zGzVzRzS1T2U3V4W5X6Y8";

  const PeaceBond = await hre.ethers.getContractFactory("PeaceBondAnchor");
  const contract = PeaceBond.attach(contractAddress);

  const tx = await contract.anchor(manifestCID, signatureCID);
  console.log("Transazione inviata:", tx.hash);

  await tx.wait();
  console.log("✓ PeaceBond #001 ancorato con successo!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
