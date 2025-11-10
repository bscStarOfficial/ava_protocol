const {ethers} = require("hardhat");
let recView, dfMain, dfAdmin, registerDf;
let deployer;
const {isAddress, parseEther} = require('ethers/lib/utils');
const EXCELJS = require('exceljs');
const BigNumber = require("bignumber.js");
const WORKBOOK = new EXCELJS.Workbook();
const sql = require("../../sql");

(async () => {
  recView = await ethers.getContract("RecView");
  dfMain = await ethers.getContract("DFMain");
  dfAdmin = await ethers.getContract("DFAdminInvest");
  registerDf = await ethers.getContract("RegisterDF");

  deployer = (await ethers.getSigners())[0].address;

  await invest();
  process.exit(0);
})();

async function view() {
  let user = '0xf0Dc68c2Fdc09fe5D5ED62333135C2F91432d9C5';
  let usdtAmount = await dfAdmin.getUAmount(user);
  let btnAmount = await dfAdmin.getBtnAmount(usdtAmount);
  console.log({
    usdt: new BigNumber(usdtAmount).dividedBy(1e6).toFixed(),
    btn: new BigNumber(btnAmount.toString()).dividedBy(1e18).toFixed(),
  });
}

async function invest() {
  let users = await getUsers();
  let tx = await dfAdmin.invest(users);
  console.log(tx.hash);
  await tx.wait();
}

async function registered() {
  let users = await getUsers();
  for (let user of users) {
    let res = await registerDf.registered(user)
    if (!res) {
      console.log('---------', user);
    } else {
      console.log(user);
    }
  }
}

async function getUsers() {
  await WORKBOOK.xlsx.readFile('/Users/jc/code/my_remix/bitSync_protocol/scripts/important/tables/u_btnstake_7.xlsx');
  const SHEET = WORKBOOK.worksheets[0];
  let users = [];
  SHEET.eachRow((row, rowNumber) => {
    // 239
    if (rowNumber >= 3 && rowNumber <= 6) {
      let to = row.values[2];
      if (isAddress(to)) {
        users.push(to);
      }
    }
  });

  console.log(users)

  await sleep(3);

  return users;
}

async function insertUser() {
  let users = await getUsers();
  // let users = [
  //   '0xf9D640cd111249b47845591b97DB1b1a3B965410',
  //   '0xEd9206Ce1D64267DB7097c4Bd968F5AE65b5068c',
  //   '0x9714956c2A81CE8f664CD359C8AEeaD2592FbAAb',
  //   '0xB3829d51594af45325Ca13057Af38c5747225504',
  //   '0xE3056de4f741a72341a8058A6BadC3E3159eB052',
  //   '0x4E373485fF51b6323C7d38152a3817D130F540CB',
  //   '0xd7701938D96BE01EB78C5732C594C67577Aad3aC',
  //   '0xA25B2C18B2Dc66590B62005506FF1dC8fF6C9FeB',
  //   '0x2325D9060e7A78F695EaB758a63e854FeAe94FB3',
  //   '0x4D51a0bbaA3fC66249635f6D8363951E811271fD',
  //   '0x2FBc4615DB50F8cd77a4A3F9249a8141d81fD9AD'
  // ]
  for (let user of users) {
    let usdtAmount = await dfAdmin.getUAmount(user);
    let btnAmount = await dfAdmin.getBtnAmount(usdtAmount);
    let usdt = new BigNumber(usdtAmount).dividedBy(1e6).toFixed();
    let btn = new BigNumber(btnAmount.toString()).dividedBy(1e18).toFixed();
    await sql.query(
      'INSERT INTO `btn`.`df_t` (`user`, `usdt`, `btn`) VALUES (?,?,?)',
      [user, usdt, btn]
    )
  }

}

async function investByFoundation() {
  let [users, amounts] = await getUsers2();
  let tx = await dfMain.investByFoundation(users, amounts);
  console.log(tx.hash);
  await tx.wait();
}

async function getUsers2() {
  let arr = [

  ];
  let users = [];
  let amounts = [];
  arr.forEach(item => {
    users.push(item[0]);
    amounts.push(new BigNumber(item[1]).multipliedBy(1e18).toFixed());
  })
  return [users, amounts];
}


async function sleep(time) {
  await new Promise((resolve, reject) => {
    setTimeout(() => {
      resolve()
    }, time * 1000)
  })
}

async function getUsers2____() {
  let arr = [
    ['0xaa70713E0cAd923d86C8E7Aa0c54f47fce98b337', 32967],
    ["0x54d594071587fBfA0049e198b8C4a8f2A54B59b6", 34169],
    ["0x307AB719085470BC388039aE4DedD11150229ffd", 17084],
    ["0x7C9B04111Dee61bBA76771ae35808411904DbBec", 17084],
    ["0xeb3BDC14B7eEcd0A0B7f6DC5325f3c906f722d48", 17084],
    ["0x3e0eA76D98da69Cae5e7067581841CB516586f80", 17084],
    ["0x29a536B70322F717C960e2d6d1862CfEcb199882", 8542],
    ["0xc10c52d22d5AA627aB1Db31C2Eb7d208abb29a57", 8542],
    ["0xeA7e2c6109fA7c2c9e102CA65c555Dd1886D031d", 8542],
    ["0xDCE804Eb2A3dEc703C89778B60EB6aE222936F12", 8542]
    ['0x8A0c36D8B7c107934b8eE106220dFF7BB15A5F72', '7000'],
    // ['0xBB7c9c10e2FdB93091ad0cDeA27A258A0E3848ab', '34286'],
    ['0xd96791C3Dd66B15adB07b5DdCFc95286787a0394', '80000'],
    // ['0x8f1e3F6c61cfA97948291c7c3c43Fe51FE044a9D', '34286'],
    ['0x87F5EF1d4a13BE56697f31EAAa319E4f8D89F704', '80000'],
    ['0x90e403b3D554D79f5FEf7207915a194FAAe88A67', '80000'],
    ['0xa5Bf5450ACAc1DA39aFA45C5b403d0B980Db584D', '34286'],
    ['0x39694a24bE0c0e7311e30541D5bFdDe1e57399b5', '34286'],
    ['0x0480702C4F5C97De20DeAD0dD5D2D564D8E13297', '17143'],
    ['0x14c23574E8627075F92044fBD219Ae1A50c642DB', '17143'],
    ['0xB154F22966f7b4c35EEed680F6c3CC5B0AADEE66', '34286'],
    ['0xDe40ff548a4c62D15C9Ae48d5AD1699cD6D0026d', '80000'],
    ['0x2393e8fa996C2417c1e7323075eab1068Dc0CB96', '34286'],
    ['0xf02cbe3B72558334b96A71AdFCc4C30C1825fF61', '34286'],
    ['0xa0BD6Fbeed316AF6F129C626a912A611E38dFd1c', '34286'],
    ['0x337020baA9Ce6b87702631AA4DE9A32E73256E02', '34286'],
    ['0x2F8DD9dD05cceb99Cf4089eA65177e539FA3fAb1', '34286'],
    ['0x8a022fC5Faf205CB5A3506A8F1Ac5d0Ed696c37D', '34286'],
    ['0x15EE40a4d95137034a3Bf5015b60C5DdDe538Cc3', '34286'],
    ['0x555b68F87de2f9988bd0f36cDd3b9b1C53dd349a', '34286'],

    ['0x53EF39D7F5d62850B66E21b1574feC53fd2E8984', 35778],
    ['0xc396014ae3A466ff65458866Ee4b922654d24d61', 35778],
    ['0x6Eb1a43ADc1A566044a448aABC5F35e668685EcA', 35778],
    ['0x8b356C220e3f1982E5F815553CADdCF37b10fc55', 35778],
    ['0x5F793eE77016A2e20182F6CD466A7a056F0EfBef', 71556],
    ['0xee39E0d847c13e5859920c51F619569cf3071338', 1967799],
    ['0x785Db2EDCF91C02f8DcD208B71C8CBdEdF2DD643', 357781],
    ['0xbb5F02DF03139a12A90A94A7B54bEF25793517e3', 357781],
    ['0xF84370186242CE1cd9c746983cf3Ebad56b107de', 357781],
    ['0xD3E79F11Db6FbE173Be230607CDF7D61e75e8c00', 357781],
    ['0xc429605891Db6284D16122D95466a83f0d226Bf3', 357781],
    ['0x442E70DAD3671FA450f3Ac54c48C81d21a881e5E', 71556],
    ['0xe159f28476b249Cb3390a0f118A323Bc08b3c1AA', 357781],
    ['0x2Bfb5587ded64cc53Cd0915a9835AdaA5339c687', 357781],
    ['0xbb5D2564CEbE064d50D7d854840E6Ea4aC0e4DE4', 357781],
    ['0x9fBfbFA23C19b33F4A1F81fd247ACe64EE489878', 35778],
    ['0xEc759eC3b03B4A546e4D3dB2Ac8417aDb7C78242', 357781],
    ['0x9d31B816a5a322a1354e376BF92E9015aAc50eE5', 357781],
  ];
  let users = [];
  let amounts = [];
  arr.forEach(item => {
    users.push(item[0]);
    amounts.push(new BigNumber(item[1]).multipliedBy(1e18).toFixed());
  })
  // await WORKBOOK.xlsx.readFile('/Users/jc/code/my_remix/bitSync_protocol/scripts/important/tables/df_invest_by_foundation.xlsx');
  // const SHEET = WORKBOOK.worksheets[2];
  // let users = [];
  // let amounts = [];
  // SHEET.eachRow((row, rowNumber) => {
  //   // 239
  //   if (rowNumber >= 3 && rowNumber <= 22) {
  //     let to = row.values[5];
  //     if (isAddress(to)) {
  //       console.log(`['${to}', '${new BigNumber(row.values[6].result).toFixed(0)}'],`)
  //       users.push(to);
  //     }
  //   }
  // });
  //
  // await sleep(3);

  return [users, amounts];
}
