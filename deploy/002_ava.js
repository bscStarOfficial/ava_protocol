const {ethers} = require("hardhat");
const {parseEther, parseUnits, keccak256, toUtf8Bytes} = require("ethers/lib/utils");
const accounts = require("../config/account")
module.exports = async ({getNamedAccounts, deployments, getChainId, getUnnamedAccounts}) => {
  const {deploy} = deployments;
  let {deployer, referralRoot, avaProfit, avaMarketing, avaTechnology, stakingMarketing, stakingTechnology} = await getNamedAccounts();
  const chainId = await getChainId()

  let usdt, router;

  if (chainId == 31337) {
    usdt = (await ethers.getContract("USDT")).address;
    router = (await ethers.getContract("UniswapV2Router02")).address;
  } else if (chainId == 5611) {
    usdt = (await ethers.getContract("USDT")).address;
    router = (await ethers.getContract("UniswapV2Router02")).address;
  } else {
    usdt = '0x55d398326f99059fF775485246999027B3197955';
    router = '0x10ED43C718714eb63d5aA57B78B54704E256024E'
  }

  if (chainId != 31337) {
    referralRoot = accounts[chainId].referralRoot;
    avaProfit = accounts[chainId].avaProfit;
    avaMarketing = accounts[chainId].avaMarketing;
    avaTechnology = accounts[chainId].avaTechnology;
    stakingMarketing = accounts[chainId].stakingMarketing;
    stakingTechnology = accounts[chainId].stakingTechnology;
  }

  await deploy('Referral', {
    from: deployer,
    gasLimit: 30000000,
    args: [referralRoot],
    log: true,
  });
  let referral = await ethers.getContract("Referral");

  await deploy('AvaStaking', {
    from: deployer,
    gasLimit: 30000000,
    args: [referral.address, stakingMarketing, stakingTechnology, usdt, router],
    log: true,
  });
  let staking = await ethers.getContract("AvaStaking");

  await deploy('AVA', {
    from: deployer,
    gasLimit: 30000000,
    args: [staking.address, avaProfit, avaMarketing, avaTechnology, usdt, router],
    log: true,
  });
  let ava = await ethers.getContract("AVA");

  if (await referral.stakingContract() === ethers.constants.AddressZero) {
    let tx = await referral.setStakingContract(staking.address);
    if (chainId != 31337) {
      console.log('referral.setStakingContract', tx.hash);
      await tx.wait();
    }
  }

  if (await staking.AVA() === ethers.constants.AddressZero) {
    let tx1 = await staking.setAVA(ava.address);
    if (chainId != 31337) {
      console.log('staking.setAVA', tx1.hash);
      await tx1.wait();
    }

    let tx2 = await ava.transfer(staking.address, parseEther('200000'));
    if (chainId != 31337) {
      console.log('transfer 20w', tx2.hash);
      await tx2.wait();
    }
  }

};
module.exports.tags = ['ava'];
