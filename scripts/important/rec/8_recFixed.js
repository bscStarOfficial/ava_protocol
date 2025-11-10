const {ethers} = require("hardhat");
const {parseEther, parseUnits, formatEther} = require("ethers/lib/utils")
let recMaster, recSet;
let deployer;
const sql = require("../../sql");
const BigNumber = require("bignumber.js");

(async () => {
  recMaster = await ethers.getContract("RecMaster");
  recSet = await ethers.getContract("RecSet");

  deployer = (await ethers.getSigners())[0].address;

  // let users = await getMiners();

  let users = [
    '0xd86465535DAFdecf0522F91a5c3C2e4e12F69f37',
    '0x2cd6e44Bd6dBbc560b9F9553CB4591c46abC5dad',
    '0xC91f206f4F72bd988d3851D69928C16501c76746',
    '0xA24fBD759Dfb020aCC3Fc8a6e6a6d72B13Ed9570'
  ];

  for (let user of users) {
    let userBack = await recMaster.userBacks(user);
    console.log(userBack);
    // let userBackNew = {
    //   invested: userBack.invested,  // 精度6
    //   claimNoBack: userBack.claimNoBack,
    //   claimAll: new BigNumber(userBack.claimAll).minus(userBack.disable).toFixed(),
    //   available: 0,
    //   disable: 0,
    //   _dis: 0
    // }
    // let tx = await recMaster.setUserBacks(user, userBackNew);
    // console.log(tx.hash);
    // await tx.wait();
  }
  process.exit(0);
})();

async function setUsers(users) {
  let tx = await recSet.setUsers(users);
  console.log('setUsers', tx.hash);
  await tx.wait();
}

async function setUserBacks(users) {
  let tx = await recSet.setUserBacks(users);
  console.log('setUserBacks', tx.hash);
  await tx.wait();
}

async function setMinerProducts(users) {
  let tx = await recSet.setMinerProducts(users);
  console.log('setMinerProducts', tx.hash);
  await tx.wait();
}

async function setProductPowers() {
  let tx = await recSet.setProductPowers();
  console.log('setProductPowers', tx.hash);
  await tx.wait();
}

async function getMiners() {
  let list = await sql.query('select distinct(user) from btn.bs_invest');
  let users = [];
  for (let item of list) {
    users.push(item.user)
  }

  return users;
}
