# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js

# referral
npx hardhat verify --network bsc 0xA021AcDe734F0b97eB0E1Ec67Be2d700d628b789 '0x0f3b3484297bBCC02591c89b7df966084CD9503A'
```

## 不享BTN持仓分红地址

初始发行地址
- miner
- lp
- dao
- foundation
- lv2

合约地址不参与分红
- pair(btn-wbnb交易对)

## FREE_ROLE
加 liquidRouter
加 swapRouter
加 lpSwap

## BLACK_ROLE
加 btnBnb pair，不开放交易。只有通过特定router才可交易，如swapRouter、lpSwap

## pair role
减 btnBnb pair，不触发btn自带的兑换经济模型
