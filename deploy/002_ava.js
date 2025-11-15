const {ethers} = require("hardhat");
const {parseEther, parseUnits, keccak256, toUtf8Bytes} = require("ethers/lib/utils");

module.exports = async ({getNamedAccounts, deployments, getChainId, getUnnamedAccounts}) => {
  const {deploy} = deployments;
  let {deployer, root, marketing, profit} = await getNamedAccounts();
  const chainId = await getChainId()

  let usdt, router;

  if (chainId != 56) {
    usdt = (await ethers.getContract("USDT")).address;
    router = (await ethers.getContract("UniswapV2Router02")).address;
  } else {
    usdt = '0x55d398326f99059fF775485246999027B3197955';
    router = '0x10ED43C718714eb63d5aA57B78B54704E256024E'
  }

  await deploy('Referral', {
    from: deployer,
    gasLimit: 30000000,
    args: [root],
    log: true,
  });
  let referral = await ethers.getContract("Referral");

  await deploy('AvaStaking', {
    from: deployer,
    gasLimit: 30000000,
    args: [referral.address, marketing, usdt, router],
    log: true,
  });
  let staking = await ethers.getContract("AvaStaking");

  await deploy('AVA', {
    from: deployer,
    gasLimit: 30000000,
    args: [staking.address, profit, marketing, usdt, router],
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
    let tx = await staking.setAVA(ava.address);
    if (chainId != 31337) {
      console.log('staking.setAVA', tx.hash);
      await tx.wait();
    }
  }

};
module.exports.tags = ['ava'];
