const {isAddress, parseEther} = require('ethers/lib/utils');
const EXCELJS = require('exceljs');
const BigNumber = require("bignumber.js");
const WORKBOOK = new EXCELJS.Workbook();

async function getLinks0() {
  await WORKBOOK.xlsx.readFile('/Users/jc/code/my_remix/bitSync_protocol/scripts/important/tables/btn_airdrop_7_19.xlsx');
  const SHEET = WORKBOOK.worksheets[0];
  let transfers = [];
  let total = 0;
  SHEET.eachRow((row, rowNumber) => {
    if (rowNumber >= 3 && rowNumber <= 57) {
      let to = row.values[2];
      let amount = row.values[4];
      if (isAddress(to) && Number(amount) > 0) {
        // console.log(to, amount)
        printSql(to, amount);
        total += amount
        transfers.push([to, new BigNumber(amount).multipliedBy(1e18).toFixed()]);
      }
    }
  });

  console.log(total)

  await sleep(3);

  return transfers;
}

async function getLinksx() {
  return [
    // ['0x7aaf857De5A2880d9F07Fff56C2ba30c46221C3E', parseEther('208333')],
    ['0x25748f31322187820F0654DcD63e2f319F28eEc1', parseEther('55556')],
    ['0xD9A6656cEC6d7592fC8E2BE16eE77fa7BFBB7777', parseEther('50000')],
    ['0x960B75Fd2CB9f8a61da457b5b7f17004c0687ddD', parseEther('50000')],
    ['0x5c1F1F54840900067Dd45c7742ec3DEcA6e9ec2E', parseEther('25000')]
  ]
}

async function sleep(time) {
  await new Promise((resolve, reject) => {
    setTimeout(() => {
      resolve()
    }, time * 1000)
  })
}

async function printSql(to, amount) {
  console.log(`UPDATE w_app_users SET btnClaimed = btnClaimed + ${amount} WHERE wallet0 = '${to}';`);
}


module.exports = {
  getLinks0
}
