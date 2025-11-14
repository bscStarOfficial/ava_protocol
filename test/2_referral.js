const {expect} = require("chai");
const {ethers, deployments, getNamedAccounts, getUnnamedAccounts} = require("hardhat");
const {parseEther, formatEther, parseUnits, solidityKeccak256} = require("ethers/lib/utils");
const {AddressZero} = ethers.constants
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const common = require("./util/common");
const {loadFixture} = require("@nomicfoundation/hardhat-network-helpers");

let deployer, A, B, C, D, E, F, G;
let registerV2;

async function initialFixture() {
  await deployments.fixture();

  [registerV2] = await common.getContractByNames(["RegisterV2"]);
  [deployer, A, B, C, D, E, F, G] = await common.getAccounts(
    ["deployer", "A", "B", "C", "D", "E", "F", "G"]
  );
}

describe("注册", function () {
  it('注册30代');
  it('getReferral')
  it('getReferrals')
})

