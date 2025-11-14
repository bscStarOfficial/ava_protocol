const {parseEther, formatEther, parseUnits} = require("ethers/lib/utils");
const {ethers} = require("hardhat");
const common = require("./common");
const {setBalance} = require("@nomicfoundation/hardhat-network-helpers");
const {BigNumber} = require("bignumber.js");

let ava, usdt, swap;

async function dexInit() {
  [ava, usdt, swap] = await common.getContractByNames(["AVA", 'USDT', 'SwapMock']);
}

async function getAmountsOut(amountIn, contractAddresses = []) {
  let res = await swap.getAmountsOut(amountIn, contractAddresses);
  return Number(formatEther(res[res.length - 1]));
}

async function getAmountsIn(amountOut, contractAddresses = []) {
  let res = await swap.getAmountsIn(amountOut, contractAddresses);
  return Number(formatEther(res[0]));
}

async function addLiquidity(account, avaAmount, usdtAmount) {
  await swap.connect(account).addLiquidity(
    ava.address, usdt.address,
    parseEther(avaAmount), parseEther(usdtAmount), account.address, 9999999999
  );
}

function swapExactTokensForTokensSupportingFeeOnTransferTokens(
  amountIn, path, account,
) {
  let pathAddr = [path[0].address, path[1].address];
  return swap.connect(account).swapExactTokensForTokensSupportingFeeOnTransferTokens(
    parseEther(amountIn.toString()),
    0,
    pathAddr,
    account.address,
    9999999999
  );
}


module.exports = {
  getAmountsOut,
  getAmountsIn,
  addLiquidity,
  swapE2T: swapExactTokensForTokensSupportingFeeOnTransferTokens,
}
