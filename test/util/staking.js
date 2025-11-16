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
  return staking.connect(account).stake(uAmount, 0, stakeIndex);
}

function unStake(account, stakeIndex) {
  return staking.connect(account).unStake(stakeIndex);
}

function redeemBuyUnStake(account, index) {
  return staking.connect(account).redeemBuyUnStake(index);
}

function claimAbandonedBalance(token, amount) {
  amount = parseEther(amount.toString());
  return staking.claimAbandonedBalance(token, amount);
}

async function balanceOf(account) {
  return await staking.balanceOf(account.address);
}

async function rewardOfSlot(account, index) {
  return await staking.rewardOfSlot(account.address, index);
}

async function getTeamKpi(account) {
  return await staking.getTeamKpi(account.address);
}

async function isPreacher(account) {
  return await staking.isPreacher(account.address);
}

module.exports = {
  stakingInit,
  claimAbandonedBalance,
  stake,
  unStake,
  redeemBuyUnStake,
  balanceOf,
  rewardOfSlot,
  getTeamKpi,
  isPreacher,
}
