const {expect} = require("chai");
const {ethers, deployments, getNamedAccounts, getUnnamedAccounts} = require("hardhat");
const {parseEther, formatEther, parseUnits, solidityKeccak256} = require("ethers/lib/utils");
const {AddressZero} = ethers.constants
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const common = require("./util/common");
const {loadFixture, time} = require("@nomicfoundation/hardhat-network-helpers");
const {referralInit, userBindReferral30} = require("./util/referral");
const {addLiquidity, dexInit} = require("./util/dex");
const {stakingInit, stake, unStake, rewardOfSlot, maxStakeAmount, setTeamVirtuallyInvestValue} = require("./util/staking");
const {multiApprove} = require("./util/common");
const BigNumber = require("bignumber.js");

let deployer, root, technology2, marketing;
let ava, usdt, referral, staking, router;
let wallets;

async function initialFixture() {
  await deployments.fixture();
  [ava, usdt, referral, staking, router] = await common.getContractByNames([
    "AVA", 'USDT', 'Referral', 'AvaStaking', 'UniswapV2Router02']
  );

  await referralInit();
  await stakingInit();
  await dexInit();
  [deployer, root, technology2, marketing] = await common.getAccounts(["deployer", "root", 'technology2', 'marketing']);
  wallets = await userBindReferral30();
  await multiApprove(ava, [router])
  await multiApprove(usdt, [router])
  await addLiquidity(deployer, 1000000, 1000000);
  await ava.updatePoolReserve();
}

describe("质押", function () {
  before(async function () {
    await initialFixture();
  })
  it('最大质押量', async () => {
    expect(await maxStakeAmount()).to.equal(1000);
  })
  it('1天日化0.3%', async function () {
    await stake(wallets[29], 100, 0);
    await time.increase(86400 * 2);
    let reward = 0.6;
    expect(await rewardOfSlot(wallets[29], 0)).to.closeTo(100.6, reward / 500);
  })
  it('15天日化0.6%', async function () {
    await stake(wallets[29], 100, 1);
    await time.increase(86400 * 2);
    let reward = 1.2;
    expect(await rewardOfSlot(wallets[29], 1)).to.closeTo(101.2, reward / 100);
  })
  it('30天日化1.2%', async function () {
    await stake(wallets[29], 100, 2);
    await time.increase(86400 * 2);
    let reward = 2.4;
    expect(await rewardOfSlot(wallets[29], 2)).to.closeTo(102.4, reward / 100);
  })
  it('50%U买入AVA添加流动性销毁', async function () {

  })
})
describe("正常赎回", function () {
  before(async function () {
    await initialFixture();
    await stake(wallets[28], 200, 0);
    await stake(wallets[29], 100, 0);
    await time.increase(86400 * 2);
  })
  describe("本金+直推+项目方=76%", function () {
    before(async function () {
      let teamYJ = [
        [0, 300_0000],
        [3, 100_0000],
        [6, 50_0000],
        [8, 10_0000],
        [11, 5_0000],
        [16, 1_0000],
      ];
      for (let item of teamYJ) {
        await setTeamVirtuallyInvestValue(wallets[item[0]], item[1]);
      }
    })
    it('本金正常赎回')
    it('70%静态')
    it('5%直推')
    it('0.5%项目方')
    it('0.5%技术')
    it('团队奖励24%，按级差分配')
    it('S1--1万U -- 5%')
    it('S2--5万U -- 9%')
    it('S3--10万U --13%')
    it('S4--50万U --17%')
    it('S5--100万U--20%')
    it('S6--300万U--24%', async function () {
      let amountU = await rewardOfSlot(wallets[29], 0);
      let interest = new BigNumber(amountU).minus(100);
      await expect(unStake(wallets[29], 0)).to.changeTokenBalances(
        usdt,
        [
          wallets[29],
          wallets[28],
          technology2,
          marketing,
          // wallets[16],
          // wallets[11],
          // wallets[8],
          // wallets[6],
          // wallets[3],
          // wallets[0],
        ],
        [
          interest.multipliedBy(0.7).plus(100).multipliedBy(1e18).toFixed(),
          interest.multipliedBy(0.05).toFixed(),
          interest.multipliedBy(0.005).toFixed(),
          interest.multipliedBy(0.005).toFixed()
          // 团队奖
          // parseEther((interest * 0.05).toFixed()),
          // parseEther((interest * 0.04).toFixed()),
          // parseEther((interest * 0.04).toFixed()),
          // parseEther((interest * 0.04).toFixed()),
          // parseEther((interest * 0.03).toFixed()),
          // parseEther((interest * 0.04).toFixed()),
        ]
      );
    })
  })
})

describe("未发送收益转到社区地址", function () {
})

describe("未到期无法赎回", function () {
  it('1天无法赎回', async () => {
    await expect(unStake(wallets[29], 0)).to.revertedWith('The time is not right');
  })
  it('15天无法赎回', async () => {
    await time.increase(15 * 86400 - 100);
    await expect(unStake(wallets[29], 1)).to.revertedWith('The time is not right');
  })
  it('30天无法赎回', async () => {
    await time.increase(15 * 86400 - 100);
    await expect(unStake(wallets[29], 2)).to.revertedWith('The time is not right');
  })
})

describe('团队业绩', function () {
  it('只计算伞下实际在线的本金总额（不含自身点位')
  it('随伞下新的捐赠增加')
  it('赎回而增减')
})

describe('本金总额大于等于200U才可获得推荐奖励', function () {
  it('低于200无法获取直推奖')
  it('低于200无法获取团队奖')
})

describe('开启买入赎回机制', function () {
  it('购买总收益100%的AVA代币，方可以赎回本息')
  it('24小时后赎回 AVA')
})

describe('本金赎回手续费机制', function () {
  it('0-49%可调整')
  it('本金部分扣除 “本”+“息”合计的10%手续费，自动从底池买入AVA代币转入黑洞地址')
  it('动态收益部分不变')
})
