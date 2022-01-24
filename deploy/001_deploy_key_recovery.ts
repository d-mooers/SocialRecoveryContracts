import { DeployFunction } from "hardhat-deploy/types";
import * as fs from "fs/promises";
import path from "path";

const deploy: DeployFunction = async function ({
  getNamedAccounts,
  deployments,
  getChainId,
  getUnnamedAccounts,
}) {
  // await hre.run('compile');
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();
  const { deploy } = deployments;
  console.log(`Deploying from ${deployer} on chain ${chainId}`);
  const deployment = await deploy("KeyRecovery", {
    from: deployer,
    args: [],
    log: true,
  });

  //   writeDeployment(chainId, {
  //     [`KeyRecovery-${Date.now()}`]: deployment.address,
  //   });
};

const makeConfigPath = (chainId: string): string =>
  path.join(__dirname, "..", "..", "records", `${chainId}.addresses.json`);

const writeDeployment = async (
  chainId: string,
  addresses: Record<string, string>
): Promise<void> => {
  const configPath = makeConfigPath(chainId);
  Object.entries(addresses).forEach(([name, addr]) =>
    console.log(`${name}: ${addr}`)
  );
  await fs.writeFile(configPath, JSON.stringify(addresses, null, 2));
};

export default deploy;
deploy.id = "deploy";
deploy.tags = ["Main"];
