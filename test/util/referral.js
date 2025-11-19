const {parseEther, formatEther, parseUnits} = require("ethers/lib/utils");
const {ethers} = require("hardhat");
const common = require("./common");
const {setBalance} = require("@nomicfoundation/hardhat-network-helpers");
const {BigNumber} = require("bignumber.js");
const {Wallet} = require("ethers")

let ava, usdt, referral, staking, root, provider;

async function referralInit() {
  [ava, usdt, referral, staking] = await common.getContractByNames(["AVA", 'USDT', 'Referral', 'AvaStaking']);
  [root] = await common.getAccounts(["referralRoot"]);
  provider = ethers.provider;
}

async function userBindReferral30() {
  let wallets = [];

  for (let i = 0; i < 30; i++) {
    let wallet = Wallet.createRandom().connect(provider);
    await setBalance(wallet.address, parseEther('100'));
    let referrer = i == 0 ? root.address : wallets[i - 1].address;
    await referral.connect(wallet).userBindReferral(referrer);

    await usdt.transfer(wallet.address, parseEther('100000'));
    await usdt.connect(wallet).approve(staking.address, parseEther('100000'));

    wallets.push(wallet);
  }

  return wallets;
}

module.exports = {
  referralInit,
  userBindReferral30
}
