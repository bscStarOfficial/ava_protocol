const {expect} = require("chai");
const {ethers, deployments, getNamedAccounts, getUnnamedAccounts} = require("hardhat");
const {parseEther, formatEther, parseUnits, solidityKeccak256} = require("ethers/lib/utils");
const {AddressZero} = ethers.constants
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const common = require("./util/common");
const {loadFixture} = require("@nomicfoundation/hardhat-network-helpers");

let deployer, A, B, C, D, E, F, G;
let registerV2;

async function initialFixture() {
  await deployments.fixture();

  [registerV2] = await common.getContractByNames(["RegisterV2"]);
  [deployer, A, B, C, D, E, F, G] = await common.getAccounts(
    ["deployer", "A", "B", "C", "D", "E", "F", "G"]
  );
}

describe("投资", function () {
  it('AVA总发行量131万枚');
})
describe("收益", function () {
  it('1天日化0.3%')
  it('15天日化0.6%')
  it('30天日化1.2%')
})
describe("正常赎回", function () {
  describe("团队贡献收益奖励24%，按级差分配", function () {
    it('本金正常赎回')
    it('70%静态')
    it('5%直推')
    it('0.5%项目方')
    it('0.5%技术')
  })

  describe("团队贡献收益奖励24%，按级差分配", function () {
    it('S1--1万U -- 5%')
    it('S2--5万U -- 9%')
    it('S3--10万U --13%')
    it('S4--50万U --17%')
    it('S5--100万U--20%')
    it('S6--300万U--24%')

    it('未发送收益转到社区地址')
  })

  describe('赎回触发 recycle 价格影响', function () {

  })
})

describe('团队业绩', function() {
  it('只计算伞下实际在线的本金总额（不含自身点位')
  it('随伞下新的捐赠增加')
  it('赎回而增减')
})

describe('本金总额大于等于200U才可获得推荐奖励', function (){
  it('低于200无法获取直推奖')
  it('低于200无法获取团队奖')
})

describe('开启买入赎回机制', function() {
  it('购买总收益100%的AVA代币，方可以赎回本息')
  it('24小时后赎回 AVA')
})

describe('本金赎回手续费机制', function() {
  it('0-49%可调整')
  it('本金部分扣除 “本”+“息”合计的10%手续费，自动从底池买入AVA代币转入黑洞地址')
  it('动态收益部分不变')
})
