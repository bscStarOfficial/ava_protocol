const {ethers} = require("hardhat");
const {parseEther, parseUnits, formatEther, keccak256, toUtf8Bytes} = require("ethers/lib/utils")

const {BigNumber} = require("bignumber.js");
const {getLinks0} = require("./tables/excel");
let btn, multiPay, deployer;

(async () => {
  btn = await ethers.getContract("BTN");
  multiPay = await ethers.getContract('MultiPay');
  deployer = (await ethers.getSigners())[0];

  await pay();

  process.exit(0);
})();


async function pay() {
  console.log('btn balance', formatEther(await btn.balanceOf(deployer.address)))

  if ((await btn.allowance(deployer.address, multiPay.address)).eq(0)) {
    let tx = await btn.approve(multiPay.address, parseEther('1000000000000'));
    console.log("approve:", tx.hash)
    await tx.wait();
  }

  let arr = await getLinks0();
  let length = arr.length;
  return;

  let newArr = [];
  let count = 0;
  for (let i in arr) {
    newArr.push(arr[i]);
    if ((parseInt(i) + 1) % 200 == 0 || parseInt(i) == (length - 1)) {
      count++;
      if (count > 0) {
        console.log(i, count)
        // console.log(JSON.stringify(newArr));
        let tx = await multiPay.pay(btn.address, newArr, {gasLimit: 10000000});
        console.log("pay:", tx.hash)
        await tx.wait();
      }
      newArr = [];
    }
  }
}
