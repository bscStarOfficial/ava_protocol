const {expect} = require("chai");
const {ethers, deployments, getNamedAccounts, getUnnamedAccounts} = require("hardhat");
const {parseEther, formatEther, parseUnits, solidityKeccak256} = require("ethers/lib/utils");
const {AddressZero} = ethers.constants
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const common = require("./util/common");
const {loadFixture} = require("@nomicfoundation/hardhat-network-helpers");
const {addLiquidity, swapE2T, getAmountsIn} = require("./util/dex");
const {multiTransfer, multiApprove, getAmountsOut, tokenBalance} = require("./util/common");
let dead = {address: '0x000000000000000000000000000000000000dEaD'};

let deployer,  marketing, profit, technology, A, B, C, D, E, F, G;
let ava, usdt, swap;

async function initialFixture() {
  await deployments.fixture();

  [ava, usdt, swap] = await common.getContractByNames(["AVA", 'USDT', 'SwapMock']);
  [deployer, marketing, profit, technology, A, B, C, D, E, F, G] = await common.getAccounts(
    ["deployer", "marketing", "profit", "technology", "A", "B", "C", "D", "E", "F", "G"]
  );

  await multiTransfer(ava, deployer, [A, B, C, D], 10000);
  await multiTransfer(usdt, deployer, [A, B, C, D], 10000);
  await multiApprove(ava, [swap])
  // 1U
  await addLiquidity(deployer, 10000, 10000);
}

describe("发行", function () {
  before(async () => {
    await initialFixture();
  })
  it('AVA总发行量131万枚', async function () {
    expect(await ava.totalSupply()).to.equal(1310000 * 1e18);
    expect(await ava.balanceOf(deployer)).to.equal(1310000 * 1e18);
  });
})
describe("交易", function () {
  it('未开启预售无法交易', async function () {
    await expect(swapE2T(100, [ava, usdt], A)).to.revertedWith('pre')
    await expect(swapE2T(100, [usdt, ava], A)).to.revertedWith('pre')
  })
  it('黑名单地址无法转账', async function () {
    await ava.multi_bclist([A.address], true);
    await expect(
      ava.connect(A).transfer(B.address, 1)
    ).to.revertedWith('isReward != 0 !')

    await ava.multi_bclist([A.address], false);
  })
  it('开启预售', async function () {
    await ava.setPresale();
  })
  it('买入手续费2.5%销毁', async function () {
    let avaAmount = await getAmountsOut(
      parseEther('100'), [usdt.address, ava.address]
    );
    await swapE2T(100, [usdt, ava], B);
    expect(await tokenBalance(ava, dead)).to.eq(avaAmount * 0.025);
    expect(await ava.AmountLPFee()).to.eq(avaAmount * 0.025);
  })
  it('买入手续费2.5%构建流动性', async function () {

  })
  it('卖出手续费3%进入市场、2%进入技术', async function () {
    await swapE2T(1000, [ava, usdt], B);
    expect(await tokenBalance(ava, technology)).to.eq(25);
    expect(await ava.AmountMarketingFee()).to.eq(30);
  })
  it('30%盈利手续费进入profit')
  it('无手续费地址交易不用手续费')
  it('claimAbandonedBalance')
})
