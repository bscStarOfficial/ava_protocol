const {ethers} = require("hardhat");
const {formatEther} = require("ethers/lib/utils");
const {query} = require('../../sql')
let recMiner, recHelper;

(async () => {
  recMiner = await ethers.getContract("RecMiner");
  recHelper = await ethers.getContract("RecHelper");

  await countTotalRewards();
  process.exit(0);
})();

async function claims() {
  let list = await query("SELECT * FROM btn.temp where amount > 1000");
  let users = [];
  let productIds = [];
  for (let item of list) {
    users.push(item.user);
    productIds.push(item.productId);
  }
  // console.log(users, productIds);
  // console.log(users.length);
  let tx = await recHelper.claim(users, productIds, recMiner.address);
  await tx.wait();
}

async function countTotalRewards() {
  let list = await query('SELECT `user` FROM btn.bs_invest GROUP BY `user`');

  let total = 0;
  let productIds = [0, 1, 4, 5];
  for (let item of list) {
    for (let productId of productIds) {
      let reward = await recMiner.getTotalReward(item.user, productId);
      total += Number(formatEther(reward));
      console.log(item.user, productId, formatEther(reward));
      await query(
        'INSERT INTO `btn`.`temp` (`user`, `productId`, `amount`) VALUES (?,?,?)',
        [item.user, productId, formatEther(reward)]
      )
    }

  }
  console.log(total);
}
