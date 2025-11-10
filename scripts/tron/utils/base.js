const TronWeb = require('tronweb')
const {ethers} = require("hardhat");
let tronWeb;

module.exports = {
  init(api, privateKey) {
    console.log(api)
    tronWeb = new TronWeb({
      fullHost: api,
      headers: {"TRON-PRO-API-KEY": process.env.TRON_API_KEY},
      privateKey: privateKey
    })
    return tronWeb;
  },

  async deploy(factoryName, abi, name, opt = {}) {
    let issuerAddress = tronWeb.defaultAddress.base58;
    issuerAddress = tronWeb.address.toHex(issuerAddress);

    let contract;
    if (opt.hasOwnProperty("libraries")) {
      contract = await ethers.getContractFactory(factoryName, {libraries: opt.libraries});
    } else {
      contract = await ethers.getContractFactory(factoryName);
    }

    let bytecode = contract.bytecode;

    let options = {
      feeLimit: 10000_000_000,
      abi: JSON.stringify(abi),//Abi string
      bytecode: bytecode,//Bytecode, default hexString
      name,//Contract name string
      owner_address: issuerAddress,
    };

    if (opt.hasOwnProperty("parameters")) {
      options.parameters = opt.parameters;
    }
    let data = await tronWeb.transactionBuilder.createSmartContract(options, issuerAddress);

    const signedTxn = await tronWeb.trx.sign(data);
    const receipt = await tronWeb.trx.sendRawTransaction(signedTxn);
    console.log(name + ": " + tronWeb.address.fromHex(receipt.transaction.contract_address));
    await sleep(5);
    let contractAddress = receipt.transaction.contract_address;
    return await tronWeb.contract(abi, contractAddress);
  },

  async attach(contractAddress) {
    return await tronWeb.contract().at(contractAddress);
  },
  async attachWithAbi(contractAddress, abiName) {
    return await tronWeb.contract(JSON.parse(abis[abiName]), contractAddress);
  },
}

async function sleep(time) {
  await new Promise((resolve, reject) => {
    setTimeout(() => {
      resolve()
    }, time * 1000)
  })
}


function addressToHex(address) {
  // return "0x" + tronWeb.address.toHex(address).substr(2, 42);
  return tronWeb.address.toHex(address);
}

function addressFromHex(address) {
  return tronWeb.address.fromHex(address);
}

// console.log(util.addressToHex("TJqED6HnksuEcvXKEPY8h5S45p28UCnzJV"));
// console.log(util.addressFromHex("410a2b53078e3f7d7b3cd99e266f3ca35e430fdd9f"));
// console.log(util.addressFromHex("0x9a81987c824e3684b79499a134cba97866ef92a3"));
