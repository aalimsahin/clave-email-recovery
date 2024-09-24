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
const emailRecoveryCommandHandler =
  "0x8ae2a49fF65ed2389B8AeB06449654b9Bdb15c68";

export default async function (): Promise<void> {
  const wallet = getWallet(hre);
  const deployer = getDeployer(hre);

  const proxyArtifactName =
    "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy";
  const artifact = await deployer.loadArtifact(proxyArtifactName);
  const bytecodeHash = getContractBytecodeHash(artifact.bytecode);
  console.log("bytecodehash should be: ", bytecodeHash);

  await deployContract(hre, proxyArtifactName, [emailAuthImpl, "0x"], {
    wallet,
    silent: true,
    noVerify: true,
  });

  const module = await deployContract(
    hre,
    "Debug",
    [
      verifier,
      dkimRegistry,
      emailAuthImpl,
      emailRecoveryCommandHandler,
      factoryAddress,
    ],
    {
      wallet,
      silent: true,
      noVerify: false,
    },
    ["0x01000079c82404627fc5a2f9658c02f7007f9914bf092673dc6c094fe7ff346b"]
  );

  const moduleAddress = await module.getAddress();
  console.log("Module deployed at:", moduleAddress);

  const recoveredAccount = "0x0000000000000000000000000000000000000001";
  const accountSalt = ethers.ZeroHash;

  await module.testWithoutParameters(recoveredAccount, accountSalt);

  const addresses: Array<string> = await module.getAddressesWithoutParameters();
  const isSameAddressWithoutParams =
    addresses[0].toLowerCase() === addresses[1].toLowerCase();

  console.log(`
/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                    TEST WITHOUT PARAMS                     */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
`);

  if (!isSameAddressWithoutParams) {
    console.log("expected contract address: ", addresses[0]);
    console.log("deployed contract address: ", addresses[1]);
  } else {
    console.log("Without Parameters!");
    console.log("Expected and deployed contract addresses are the same!", true);
  }

  console.log(`
/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                    TEST WITH PARAMS                      */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
`);

  try {
    await module.testWithParams(recoveredAccount, accountSalt);

    const addresses: Array<string> = await module.getAddressesWithParams();
    const isSameAddressWithoutParams =
      addresses[0].toLowerCase() === addresses[1].toLowerCase();

    if (!isSameAddressWithoutParams) {
      console.log("expected contract address: ", addresses[0]);
      console.log("deployed contract address: ", addresses[1]);
    } else {
      console.log("With Parameters!");
      console.log(
        "Expected and deployed contract addresses are the same!",
        true
      );
    }
  } catch (e) {
    console.log("With Parameters: ", e);
  }
}
