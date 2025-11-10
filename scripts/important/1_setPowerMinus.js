const {ethers} = require("hardhat");
const {getMiners, getPowerMinersDataByTarget} = require("./data");
let bitMiner;

(async () => {
  bitMiner = await ethers.getContract("BitMiner");
  // console.log(await setPowerMinersDataByTarget());

  let [users,  powers] = await getPowerMinersDataByTarget();
  console.log(users,  powers); process.exit(0);

  let tx = await bitMiner.setPowerMinus(users,  powers);
  console.log(tx.hash);
  await tx.wait();

  process.exit(0);
})();
