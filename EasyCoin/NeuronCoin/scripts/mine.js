const hre = require("hardhat");
const { ethers } = require("ethers");

async function main() {
    const Mining = await hre.ethers.getContractFactory("Mining");
    const miningContract = await Mining.attach("MINING_CONTRACT_ADDRESS");

    const wallet = new ethers.Wallet("YOUR_PRIVATE_KEY", hre.ethers.provider);

    while (true) {
        try {
            const nonce = Math.floor(Math.random() * 1000000000);
            const tx = await miningContract.connect(wallet).mine(nonce);
            await tx.wait();
            console.log("Block mined successfully!");
        } catch (error) {
            console.error("Mining failed:", error.message);
        }

        // Aguarde 10 segundos antes da próxima tentativa
        await new Promise(resolve => setTimeout(resolve, 10000));
    }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });