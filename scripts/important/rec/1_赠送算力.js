const {ethers} = require("hardhat");
const {parseEther, parseUnits, formatEther} = require("ethers/lib/utils")
const {BigNumber} = require("ethers");
let recMaster, btn, recRegister, recDex, recView;

let deployer;
(async () => {
  recMaster = await ethers.getContract("RecMaster");
  recView = await ethers.getContract("RecView");

  recDex = await ethers.getContract("RecDex");
  btn = await ethers.getContract("BTN");
  recRegister = await ethers.getContract("RecRegister");

  deployer = (await ethers.getSigners())[0].address;

  await setUseBack();
  process.exit(0);
})();

async function setUseBack() {
  let users = [
    // '0xAC42269Fd9A13CB2F53119e2F417e7Ec612d621A',
    // '0x1c7B2AdECf386264A75837d315254e321B4424e1',
    // '0x1F0C463837EFaEe61aEcAf4f60120f8d3fBf7c0D',
    // '0x5160Da926D033535B31a8832Fe0Cc6E61d66e193',
    // '0x9649008B67B97c8ba9369914658269190aeE61c3'
    '0x94F0cB5C4A2214B84b23643519998F0bde8dAE48',
    '0x7c852b6ba3Ce269E555Bd07341cd220b8e68f084',
    '0x847c43C4803b53D78aC98107E3A74e619EaE5956'
  ]
  for (let user of users) {
    // let userBack = await recMaster.userBacks(user);
    // console.log(userBack);
    // let pro2 = await recMaster.minerProducts(user, 2);
    // let pro3 = await recMaster.minerProducts(user, 3);
    // console.log({pro2, pro3})

    let tx1 = await recMaster.setUserBacks(user, [1000_000000, 0, 0, 0, 0, 0]);
    console.log(tx1.hash);
    await tx1.wait()

    let tx2 = await recMaster.setMinerProductPower(user, 2, 4000_000);
    console.log(tx2.hash);
    await tx2.wait()

    let tx3 = await recMaster.setMinerProductPower(user, 3, 6000_000);
    console.log(tx3.hash);
    await tx3.wait()
  }
}
