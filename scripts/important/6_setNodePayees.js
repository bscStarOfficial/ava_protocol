const {ethers} = require("hardhat");
const {formatEther} = require("ethers/lib/utils");
const {query} = require('../sql')
const {getLinks0} = require("./tables/excel");
const BigNumber = require("bignumber.js");
let nodeProfit;

(async () => {
  nodeProfit = await ethers.getContract("NodeProfit");

  await setNodePayees();
  process.exit(0);
})();

async function setNodePayees() {
  let arr = await newPayees();
  for (let item of arr) {
    let user = item[0];
    let amount = new BigNumber(item[1]).multipliedBy(1e6).toFixed();

    let payee = await nodeProfit.payees(user);
    console.log(payee.shares.toString(), user, amount);
    if (payee.shares.toString() != amount) {
      let tx = await nodeProfit.setPayee(user, amount);
      console.log(tx.hash);
      await tx.wait();
    }
  }
}

async function view() {
  let user = '0x3e8FD2552968e7634509E171991ae827A54C31fC'
  let payee = await nodeProfit.payees(user);
  console.log(user, payee.shares.toString());
}

async function newPayees() {
  return [
    ['0x94F0cB5C4A2214B84b23643519998F0bde8dAE48', 0],
    ['0x1ab9bD9b1bE33D87796ca71A8df4Fa5018ED6a61', 0],
    ['0x3E90347393676354668519387D6a56a616E09e94', 2000],
    ['0x0B8A5d52e8bD3445ae0Cba7edbbF89dc07d9733D', 10000],
    ['0xB1bC85f4ccEf7DB134e1255EAAA1CB22C4fc5798', 10000],
    ['0xF31aA2712D52981F5Bdb0105f8b2156955b9f2E6', 10000],
  ]

  return [
    ['0x07A95E1eec2265641Bfd258AB6362E85D18cdAEe', 0],
    ['0xa57Edfb732057d9B961cAD5E1Df5ca09D91E5eBb', 0],
    ['0xD5c0982f89272dcd6b037Ee03600D9DE18fC4b6F', 0],
    ['0xbdf9551515e35f5faE4a59A6f9FB674682A5aE7F', 0],
    ['0xf9D640cd111249b47845591b97DB1b1a3B965410', 0],
    ['0xEd9206Ce1D64267DB7097c4Bd968F5AE65b5068c', 0],
    ['0x39694a24bE0c0e7311e30541D5bFdDe1e57399b5', 0],
    ['0x9E7b0A6091ef46dd27aA2E1f7E741203bd08d44a', 2000],
    ['0xC5DfaB726C111234dB13844271B9e65A8b43aCA9', 10000],
    ['0x9B07237BD45c895653BF411E3ADA104980b7A931', 10000],
  ];

  return [
    ['0xE7857112a263552018426C14722F11631780dBcF', 1500],
    ['0x9BC38efDf14610D98b7C83d2Fea8599122297320', 1000],
    ['0x02C55BC0A691F5BDaCe48c58Db075699FBD8117a', 2000],
    ['0x555b68F87de2f9988bd0f36cDd3b9b1C53dd349a', 4000],
    ['0x87F5EF1d4a13BE56697f31EAAa319E4f8D89F704', 2000],
    ['0x39694a24bE0c0e7311e30541D5bFdDe1e57399b5', 1000],
    ['0x400299d3670a9E4f41c7b5A2eC7837307c7EFC0E', 10000],
    ['0x1ab9bD9b1bE33D87796ca71A8df4Fa5018ED6a61', 3000],

    ['0x902aBC827ed01a33d55B76Ff0525fe02d3661000', 0],
    ['0xe917e2C0fDf69dAf51A32BA3677616E37CA46E70', 0],
    ['0x8f4440fccc531e85A4D8fE5610a9b73C5860a2eb', 0],
    ['0x7C812c223ecFeBaFF593878388174b822716788D', 0],
    ['0x44dbE3c9bebd040B5C021d080d81106288EB7359', 0],
    ['0x565b8039a86851d4C58de73fE54c26e7a2eEF5D5', 0],
    ['0x823601d73e2c34570c1d3A6198D2Aa8b18542249', 0],
    ['0x15aD41DBd5F549f0320708a65C72e52Be20a6fb1', 0],
    ['0x6bf331Dc63A01844277e19f93fB4fcE1134ECC99', 0],
    ['0x6A2864929f4Fc97c43dA15eaF04374D04C3A0764', 0],
    ['0x7c852b6ba3Ce269E555Bd07341cd220b8e68f084', 0],
    ['0x3e8FD2552968e7634509E171991ae827A54C31fC', 0],
    ['0xC50c67d12a38a1751155fDDe054C89EB5c1807F7', 0],
  ]

  return [
    ['0x9c8AF5211bc54DB4DC208Eb3383337752fFADB37', 0],
    ['0x954148F780c200729386B5A90597d26f1392C41A', 0],
    ['0x565b8039a86851d4C58de73fE54c26e7a2eEF5D5', 0],
    ['0xC91f206f4F72bd988d3851D69928C16501c76746', 0],
    ['0x6A7e1C7D1f4b74c34c0DCFB25e15c07Fb7D39EBc', 0],
    ['0x3d66Ee807386f5475651548f51ad1B77e0Cc447c', 0],
    ['0x8590274bf244Cd06b815F82b055D04bcFB84953e', 0],

    ['0xC50c67d12a38a1751155fDDe054C89EB5c1807F7', 2000],
    ['0xf464897fC7097242C3be8F94E600d6d0C7578a4B', 1000],
    ['0x71F5b504668AEb36B8E637d32F9fc0d01a80c503', 1000],
    ['0xEd9206Ce1D64267DB7097c4Bd968F5AE65b5068c', 2000],
  ];
}
