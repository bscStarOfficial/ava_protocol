const {ethers} = require("hardhat");
let dfMain;
let deployer;
const sql = require("../../sql");
const BigNumber = require("bignumber.js");

(async () => {
  dfMain = await ethers.getContract("DFMain");

  deployer = (await ethers.getSigners())[0].address;

  await view();
  process.exit(0);
})();

async function updateQuotaMulti() {
  let list = await sql.query('SELECT `user` FROM df.df_invest GROUP BY `user`');
  let users = list.map(item => item.user);
  console.log(users);

  let userGroup = [];
  for (let i in users) {
    let intI = parseInt(i) + 1;
    let user = users[i];

    userGroup.push(user);

    if (intI % 200 == 0 || intI == users.length) {
      let tx = await dfMain.updateQuotaMulti(userGroup);
      console.log(intI, tx.hash);
      await tx.wait();

      userGroup = [];
    }
  }
}

async function view() {
  let list = await sql.query('SELECT `user` FROM df.df_invest GROUP BY `user`');
  let addresses = list.map(item => item.user);

  let keys = [101, 305, 589, 900, 1200, 3500];
  for (let key of keys) {
    let address = addresses[key];

    let user = await dfMain.users(address);
    let userQuota = await dfMain.userQuotas(address);

    let invest = new BigNumber(user.invest.toString()).dividedBy(1e5);
    let counted = new BigNumber(userQuota.counted.toString()).dividedBy(1e5);
    let quota = new BigNumber(userQuota.quota.toString()).dividedBy(1e5);

    console.log(
      address,
      invest.toFixed(2),
      counted.toFixed(2),
      quota.toFixed(2),
      quota.eq(invest.multipliedBy(5)),
      counted.eq(invest)
    );
  }
}
