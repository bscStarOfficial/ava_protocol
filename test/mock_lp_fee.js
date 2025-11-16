// const BigNumber = require('bignumber.js');
//
// let ptg = new BigNumber(1.2067);
//
//
// let uAmount = new BigNumber('136643408068687943832');
// let aAmount = new BigNumber('113378040463741759491');
//
// let aNeed = uAmount.dividedBy(ptg);
// console.log('need', aNeed.toFixed());
// console.log('local', aAmount.toFixed());
// console.log(aNeed.gt(aAmount));
let reserveA = 853000;
let reserveU = 3000000;

let fee = 5000;
let half = fee / 2;

let reserveA_ = reserveA + half;
let reserveU_ = reserveA * reserveU / reserveA_;

let use1 = getOut();
let use0 = use1 / reserveU_ * reserveA_;

console.log(use0, half)


function getOut() {
  let amountInWithFee = half * 9975;
  let numerator = amountInWithFee * reserveU;
  let denominator = (reserveA * 10000) + amountInWithFee;
  return numerator / denominator;
}
