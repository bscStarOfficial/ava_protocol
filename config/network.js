module.exports = {
  hardhat: {
    // deploy: ['*-deploy/'],
    mining: {
      auto: true,
      // interval: 2000
    }
  },
  bsc: {
    // url: "https://bsc.mytokenpocket.vip",
    url: 'https://rpc.ankr.com/bsc/805167a24b8e7e42822bef6d5b81be6e136f777141fb11363f6aa19909cc0cbd',
    // url: 'https://api.zan.top/node/v1/bsc/mainnet/74878801433245639c34cc73c3dab3a4',
    // url: "https://bsc.blockpi.network/v1/rpc/e130f44902150d543570cb0db1bfb1c36f4e7bf9",
    // url: "https://bsc.blockpi.network/v1/rpc/public",
    accounts: [process.env.PRIVATE_KEY_BSC],
    chainId: 56,
    gasPrice: 1 * 100000000, // 0.1Gwei
    timeout: 60 * 1000
  },
  arb: {
    url: "https://rpc.ankr.com/arbitrum/36d9e96e6b56e9eb728e29268f596780647330f462d1329d3ed73d3a07dd5d31",
    accounts: [process.env.PRIVATE_KEY_BSC],
    chainId: 42161,
    // gasPrice: 0.1 * 1000000000, // 6Gwei
    timeout: 60 * 1000
  },
  opBnb: {
    url: 'https://opbnb-mainnet-rpc.bnbchain.org',
    accounts: [process.env.PRIVATE_KEY_BSC],
    chainId: 204,
    gas: 5000000,
    timeout: 60 * 1000
  },
  test: {
    url: "https://bsc-testnet.publicnode.com",
    // url: "https://bsc-testnet.public.blastapi.io",
    // url: "https://data-seed-prebsc-2-s3.binance.org:8545",
    accounts:
      process.env.PRIVATE_KEY_TEST !== undefined ? [process.env.PRIVATE_KEY_TEST] : [],
    chainId: 97,
    gasPrice: 5 * 1000000000, // 5Gwei
    timeout: 60 * 1000,
  },
  opTest: {
    url: "https://opbnb-testnet-rpc.bnbchain.org",
    accounts:
      process.env.PRIVATE_KEY_TEST !== undefined ? [process.env.PRIVATE_KEY_TEST] : [],
    chainId: 5611,
  }
}
