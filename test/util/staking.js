const {parseEther, formatEther, parseUnits} = require("ethers/lib/utils");
const {ethers} = require("hardhat");
const common = require("./common");
const {setBalance} = require("@nomicfoundation/hardhat-network-helpers");
const {BigNumber} = require("bignumber.js");
const {Wallet} = require("ethers")

let ava, usdt, referral, staking, root, provider;

async function stakingInit() {
  [ava, usdt, referral, staking] = await common.getContractByNames(["AVA", 'USDT', 'Referral', 'AvaStaking']);
  provider = ethers.provider;
}

function stake(account, uAmount, stakeIndex) {
  uAmount = parseEther(uAmount.toString());
  return staking.connect(account).stake(
    uAmount, 0, stakeIndex
  );
}

function unStake(account, index) {
  return staking.connect(account).unStake(index);
}

function redeemUnStake(account, index) {
  return staking.connect(account).redeemUnStake(index);
}

function claimAbandonedBalance(token, amount) {
  amount = parseEther(amount.toString());
  return staking.claimAbandonedBalance(token, amount);
}

async function balanceOf(account) {
  return await staking.balanceOf(account.address);
}

async function maxStakeAmount() {
  let res = await staking.maxStakeAmount();
  return new BigNumber(res.toString()).dividedBy(1e18).toNumber();
}

async function rewardOfSlot(account, index) {
  let res = await staking.rewardOfSlot(account.address, index);
  return new BigNumber(res.toString()).dividedBy(1e18).toNumber();
}

async function setTeamVirtuallyInvestValue(account, amount) {
  amount = parseEther(amount.toString());
  await staking.setTeamVirtuallyInvestValue(account.address, amount);
}

async function getTeamKpi(account) {
  let res = await staking.getTeamKpi(account.address);
  return new BigNumber(res.toString()).dividedBy(1e18).toNumber();
}

async function isPreacher(account) {
  return await staking.isPreacher(account.address);
}

module.exports = {
  stakingInit,
  maxStakeAmount,
  claimAbandonedBalance,
  stake,
  unStake,
  redeemUnStake,
  balanceOf,
  rewardOfSlot,
  getTeamKpi,
  isPreacher,
  setTeamVirtuallyInvestValue
}
