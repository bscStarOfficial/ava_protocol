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

describe("发行", function () {
  it('AVA总发行量131万枚');
})
describe("交易", function () {
  before(async () => {
    await initialFixture();
  })
  it('未开启预售无法交易')
  it('黑名单地址无法转账')
  it('买入手续费2.5%销毁、2.5构建流动性')
  it('卖出手续费3%进入基金、2%进入技术')
  it('30%盈利手续费进入profit')
  it('无手续费地址交易不用手续费')
})
