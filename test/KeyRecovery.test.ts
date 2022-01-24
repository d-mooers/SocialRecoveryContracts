import { expect } from "./chai-setup";
import { ethers, deployments } from "hardhat";
import { KeyRecovery } from "../typechain-types";
import * as utils from "web3-utils";

const setup = async () => {
  const [signer, ...guardians] = await ethers.getSigners();
  return {
    signer,
    guardians,
    recoveryContract: <KeyRecovery>await ethers.getContract("KeyRecovery"),
  };
};

describe("Key Recovery", function () {
  it("Allows a user to save a secret peice of data", async () => {
    const { signer, guardians, recoveryContract } = await setup();
    const secret = 0x6d616;
    const keyShares = guardians.map(
      (val) => `${parseInt(val.address, 16) & secret}`
    );
    const txn = await recoveryContract.addAccount(
      utils.padLeft(secret, 64),
      guardians.map(({ address }) => address),
      keyShares,
      Math.floor(keyShares.length / 2),
      "test"
    );
    expect(txn).to.not.reverted("");
  });
});
