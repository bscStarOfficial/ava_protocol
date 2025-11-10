# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js

npx hardhat verify --network bsc --constructor-args arguments.js 0xd4c680cA376889e17F5b5c6084b1bE1704759026
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
