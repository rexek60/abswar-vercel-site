import { vars } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync";
import { Wallet } from "zksync-ethers";

export default async function deployAbswarRankNFT(hre: HardhatRuntimeEnvironment) {
        const deployerKey = process.env.DEPLOYER_PRIVATE_KEY || vars.get("DEPLOYER_PRIVATE_KEY");
        const signerAddress = process.env.RANK_NFT_SIGNER_ADDRESS || vars.get("RANK_NFT_SIGNER_ADDRESS");
        const ownerAddress = process.env.RANK_NFT_OWNER_ADDRESS || "0x9C5e9dB5836e9c95be7cBec023D543c36E865B5B";
        const wallet = new Wallet(deployerKey);
        const deployer = new Deployer(hre, wallet);
        const artifact = await deployer.loadArtifact("AbswarRankNFT");
        const contract = await deployer.deploy(artifact, [signerAddress]);
        const contractAddress = await contract.getAddress();

  if (ownerAddress.toLowerCase() !== wallet.address.toLowerCase()) {
            const tx = await contract.transferOwnership(ownerAddress);
            await tx.wait();
  }

  console.log(`AbswarRankNFT deployed to ${contractAddress}`);
        console.log(`Rank NFT signer: ${signerAddress}`);
        console.log(`Rank NFT owner: ${ownerAddress}`);
}
