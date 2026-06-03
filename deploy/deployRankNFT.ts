import { vars } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync";
import { Wallet } from "zksync-ethers";

export default async function deployAbswarRankNFT(hre: HardhatRuntimeEnvironment) {
  const wallet = new Wallet(vars.get("DEPLOYER_PRIVATE_KEY"));
  const signerAddress = vars.get("RANK_NFT_SIGNER_ADDRESS");
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("AbswarRankNFT");
  const contract = await deployer.deploy(artifact, [signerAddress]);

  console.log(`AbswarRankNFT deployed to ${await contract.getAddress()}`);
  console.log(`Rank NFT signer: ${signerAddress}`);
}
