import * as hre from "hardhat";
import {
  deployContract,
  getWallet,
  getDeployer,
  getContractBytecodeHash,
} from "./utils";
import { utils } from "zksync-ethers";
import { ethers } from "ethers";

const factoryAddress = "0xae3c9D26fa525d0Bb119B0b82BBa99C243636f92";
const verifier = "0xbabFc29e79b4935e1B99515c02354CdA2c2fDA6A";
const dkimRegistry = "0x2D3908e61B436A80bfDDD2772E7179da5A87a597";
const emailAuthImpl = "0x87c0F604256f4C92D7e80699238623370e266A16";

export default async function (): Promise<void> {
  const deployer = getDeployer(hre);
  const proxyArtifactName =
    "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy";
  const artifact = await deployer.loadArtifact(proxyArtifactName);

  const bytecodeHash = getContractBytecodeHash(artifact.bytecode);

  console.log("bytecodehash should be: ", bytecodeHash);

  const wallet = getWallet(hre);
  const contractArtifactName = "EmailRecoveryCommandHandler";
  const commandHandler = await deployContract(
    hre,
    contractArtifactName,
    undefined,
    {
      wallet,
      silent: false,
      noVerify: true
    }
  );

  const commandHandlerAddress = await commandHandler.getAddress();
  console.log("Command handler deployed at:", commandHandlerAddress);

  await deployContract(
    hre,
    "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy",
    [emailAuthImpl, "0x"]
  );


  const module = await deployContract(
    hre,
    "EmailRecoveryModule",
    [
      verifier,
      dkimRegistry,
      emailAuthImpl,
      commandHandlerAddress,
      factoryAddress,
    ],
    {
      wallet,
      silent: false,
      noVerify: true
    },
    ["0x01000079c82404627fc5a2f9658c02f7007f9914bf092673dc6c094fe7ff346b"]
  );

  const moduleAddress = await module.getAddress();
  console.log("Module deployed at:", moduleAddress);

  const recoveredAccount = "0x0000000000000000000000000000000000000001";
  const accountSalt = ethers.ZeroHash;

  const emailAuth = await module.test(
    recoveredAccount,
    accountSalt
  );
  console.log("emailAuth: ", emailAuth);

  const addresses = await module.addresses();
  console.log("addresses: ", addresses);
}
