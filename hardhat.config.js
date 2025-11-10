require("dotenv").config();

require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require('hardhat-deploy');
require('hardhat-contract-sizer');
require("hardhat-change-network");
require('@primitivefi/hardhat-dodoc');
require('hardhat-abi-exporter');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: require("./config/solidity"),
  networks: require("./config/network"),
  paths: require("./config/paths"),
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://bscscan.com/
    apiKey: "HS6ITM6A72SC787W8724KJHS1N3WYQ92XI"
  },
  namedAccounts: {
    deployer: 0,
    miner: 1, // btn
    lp: 2,// btn
    dao: 3,// btn
    foundation: 4,// btn
    lv2: 5,// btn
    income: 6,// btn
    feeAccount: 7, // bitMiner
    poolAccount: 8,// reserve
    reserve1: 8,
    defaultCommunity: 9, // 默认社区分红地址
    reserve2: 9,
    A: 10,
    B: 11,
    C: 12,
    D: 13,
    E: 14,
    F: 15,
    G: 16,
    H: 17,
    I: 18,
    J: 19
  },
  dodoc: {
    include: [
      "Manager",
      "Card",
      "CardBuy"
    ],
    exclude: [
      'node_modules',
      'legacy',
      'libraries',
      'interfaces',
    ],
    runOnCompile: false,
    keepFileStructure: false,
  },
  abiExporter: { // npx hardhat export-abi --no-compile
    path: './docs',
    clear: false,
    flat: true,
    runOnCompile: true,
    only: [
      "Manager",
      "Card",
      "CardBuy",
      "PowerBuy"
    ],
    except: [
      'node_modules',
      'libraries',
      'interfaces',
    ]
  },
  gasReporter: {
    excludeContracts: [
      'node_modules',
      'libraries',
      'interfaces',
      'USDT',
      'ERC20',
      'WTRX',
      'LiquidRouter',
      'RegisterV2',
      'BTN',
      'Manager'
    ],
    enabled: process.env.GAS_REPORT==1
  }
};
