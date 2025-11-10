const {ethers} = require("hardhat");
const {parseEther, parseUnits, formatEther} = require("ethers/lib/utils")
let recMaster, recSet;
let deployer;
const sql = require("../../sql");

(async () => {
  recMaster = await ethers.getContract("RecMaster");
  recSet = await ethers.getContract("RecSet");

  deployer = (await ethers.getSigners())[0].address;

  let users = await getMiners();

  let userSetArr = [];
  for (let i in users) {
    let user = users[i];
    // let userBack = await recMaster.userBacks(user);
    // console.log(userBack);continue;
    let intI = parseInt(i) + 1;
    userSetArr.push(user);

    if (intI % 30 === 0 || intI === users.length) {
      await setUsers(userSetArr);
      await setUserBacks(userSetArr)
      await setMinerProducts(userSetArr)
      userSetArr = [];
    }
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
  // let list =  await sql.query('select distinct(user) from btn.bs_invest');
  // let users = [];
  // for (let item of list) {
  //   users.push(item.user)
  // }
  //
  // return users;
  return [
    '0x4e00Dcdd2Cd59fa6c248685aB58c67938Ac93b27'
    // '0x9d4004914Ec569d27d9E559Bf0916A8d6fa7F35B',
    // '0xedBfED86Fcf3C1F986F8dD63f11FeE2F8e3CF36f',
    // '0x64C8b62F822B207bcA7d8AbE0F468E104f1Cd6D6',
    // '0x0eEd6053406d0D2F3EdcEB0BE8b0e811191ebaC6',
    // '0x3785CC279a33ff1f9b68ca0fFE24601844735c4a',
    // '0x466D5528a115C687113bF285525271e1310048DC',
    // '0xf4EDac8fe1953ceE609c7E0E08d7AD72c8f56f99',
    // '0xe6bC356281321AE434e18A638b583D534eEb5126',
    // '0xFE6Fc422a3b87AC044fA494b3D66adc831BD2b86',
    // '0x6a5ee293d479C5e48B157864f865bf331b2c5085',
    // '0x19291f26fbfe6C2A3f9FBD56D0264E69FCBD34e0',
    // '0xA0B6DF0ab3aF607A39Dd3699AF7582a05E90D2eA',
    // '0x0A6Afc6Bd98671A4bd7c4079e3f34906acB7A249',
    // '0x997C71CF8Cf80aFB509c16Acfd6024125e473751',
    // '0x32b566cc641eCbaD2524cf2E8948e54f4879090D',
    // '0x66E8C9830abB55AECDb29879f1C64beC13bEF80b',
    // '0xb09D2906FaE128f4b37cEFB57480e5431c147daf',
    // '0x303B6e755cE2767c31C78d331c13bfF871630526',
    // '0x4eB96F48fAB9Fb030a849951aaBaA2B3DF6bf51C',
    // '0x5A137EBA3caeEe2140d2E989FB8957fa60D566f0',
    // '0x653f8863BCa955DBC33DbccC963b2462f8753b85'
  ]
}
