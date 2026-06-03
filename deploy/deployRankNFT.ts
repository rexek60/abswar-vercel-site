import { vars } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync";
import { Wallet } from "zksync-ethers";

export default async function deployAbswarRankNFT(hre: HardhatRuntimeEnvironment) {
    const deployerKey = process.env.DEPLOYER_PRIVATE_KEY || vars.get("DEPLOYER_PRIVATE_KEY");
    const signerAddress = process.env.RANK_NFT_SIGNER_ADDRESS || vars.get("RANK_NFT_SIGNER_ADDRESS");
    const wallet = new Wallet(deployerKey);
    const deployer = new Deployer(hre, wallet);
    const artifact = await deployer.loadArtifact("AbswarRankNFT");
    const contract = await deployer.deploy(artifact, [signerAddress]);

  console.log(`AbswarRankNFT deployed to ${await contract.getAddress()}`);
    console.log(`Rank NFT signer: ${signerAddress}`);
}
