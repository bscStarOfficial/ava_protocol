const {expect} = require("chai");
const {ethers, deployments, getNamedAccounts, getUnnamedAccounts} = require("hardhat");
const {parseEther, formatEther, parseUnits, solidityKeccak256} = require("ethers/lib/utils");
const {AddressZero} = ethers.constants
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const common = require("./util/common");
const {loadFixture, time} = require("@nomicfoundation/hardhat-network-helpers");
const {referralInit, userBindReferral30} = require("./util/referral");
const {addLiquidity, dexInit} = require("./util/dex");
const {stakingInit, stake, unStake, rewardOfSlot, maxStakeAmount, setTeamVirtuallyInvestValue, getTeamKpi, isPreacher, redeemUnStake} = require("./util/staking");
const {multiApprove, tokenBalance, tokenTransfer} = require("./util/common");
const BigNumber = require("bignumber.js");

let deployer, root, technology2, marketing, team;
let ava, usdt, referral, staking, router;
let wallets;

async function initialFixture() {
  await deployments.fixture();
  [ava, usdt, referral, staking, router] = await common.getContractByNames([
    "AVA", 'USDT', 'Referral', 'AvaStaking', 'UniswapV2Router02']
  );

  await referralInit();
  await stakingInit();
  await dexInit();
  [deployer, root, technology2, marketing, team, A] = await common.getAccounts([
    "deployer", "referralRoot", 'stakingTechnology', 'stakingMarketing', 'stakingTeam', 'A'
  ]);
  wallets = await userBindReferral30();
  await multiApprove(ava, [router])
  await multiApprove(usdt, [router])
  await addLiquidity(deployer, 1000000, 1000000);
  await ava.updatePoolReserve();

  await staking.setUnStakeDay(86400);
}

describe("质押", function () {
  before(async function () {
    await initialFixture();
  })
  it('1天日化0.3%', async function () {
    await stake(wallets[29], 1000, 0);
    await time.increase(86400 * 30);
    console.log(await rewardOfSlot(wallets[29], 0))
    // let reward = 6;
    // expect(await rewardOfSlot(wallets[29], 0)).to.closeTo(100.6, reward / 500);
  })
  it('15天日化0.6%', async function () {
    await stake(wallets[29], 1000, 1);
    await time.increase(86400 * 30);
    console.log(await rewardOfSlot(wallets[29], 1))
    // let reward = 1.2;
    // expect(await rewardOfSlot(wallets[29], 1)).to.closeTo(101.2, reward / 100);
  })
  it('30天日化1.2%', async function () {
    await stake(wallets[29], 1000, 2);
    await time.increase(86400 * 30);
    console.log(await rewardOfSlot(wallets[29], 2))
    // let reward = 2.4;
    // expect(await rewardOfSlot(wallets[29], 2)).to.closeTo(102.4, reward / 100);
  })
})
