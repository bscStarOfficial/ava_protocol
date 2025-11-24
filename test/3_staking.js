const {expect} = require("chai");
const {ethers, deployments, getNamedAccounts, getUnnamedAccounts} = require("hardhat");
const {parseEther, formatEther, parseUnits, solidityKeccak256} = require("ethers/lib/utils");
const {AddressZero} = ethers.constants
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const common = require("./util/common");
const {loadFixture, time} = require("@nomicfoundation/hardhat-network-helpers");
const {referralInit, userBindReferral30} = require("./util/referral");
const {addLiquidity, dexInit} = require("./util/dex");
const {stakingInit, stake, unStake, rewardOfSlot, maxStakeAmount, setTeamVirtuallyInvestValue, getTeamKpi, isPreacher, redeemUnStake} = require("./util/staking");
const {multiApprove, tokenBalance, tokenTransfer} = require("./util/common");
const BigNumber = require("bignumber.js");

let deployer, root, technology2, marketing, team;
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
  [deployer, root, technology2, marketing, team, A] = await common.getAccounts([
    "deployer", "referralRoot", 'stakingTechnology', 'stakingMarketing', 'stakingTeam', 'A'
  ]);
  wallets = await userBindReferral30();
  await multiApprove(ava, [router])
  await multiApprove(usdt, [router])
  await addLiquidity(deployer, 1000000, 1000000);
  await ava.updatePoolReserve();

  await staking.setUnStakeDay(86400);
}

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
    // it('本金正常赎回')
    // it('70%静态')
    // it('5%直推')
    // it('0.5%项目方')
    // it('0.5%技术')
    // it('团队奖励24%，按级差分配')
    it('S1--1万U -- 5%')
    it('S2--5万U -- 9%')
    it('S3--10万U --13%')
    it('S4--50万U --17%')
    it('S5--100万U--20%')
    it('S6--300万U--24%', async function () {
      let amountU = await rewardOfSlot(wallets[29], 0);
      let interest = new BigNumber(amountU).minus(100);
      let per = new BigNumber('6009236601189234');
      await expect(unStake(wallets[29], 0)).to.changeTokenBalances(
        usdt,
        [
          // wallets[29],
          // wallets[28],
          // technology2,
          // marketing,
          wallets[16],
          wallets[11],
          wallets[8],
          wallets[6],
          wallets[3],
          wallets[0],
        ],
        [
          // interest.multipliedBy(0.7).plus(100).multipliedBy(1e18).toFixed(),
          // interest.multipliedBy(0.05).multipliedBy(1e18).toFixed(),
          // interest.multipliedBy(0.005).multipliedBy(1e18).toFixed(),
          // interest.multipliedBy(0.005).multipliedBy(1e18).toFixed(),
          // 团队奖
          per.multipliedBy(5).toFixed(0),
          per.multipliedBy(4).toFixed(0),
          per.multipliedBy(4).toFixed(0),
          per.multipliedBy(4).toFixed(0),
          per.multipliedBy(3).toFixed(0),
          per.multipliedBy(4).toFixed(0),
        ]
      );
    })
  })
})

describe('开启买入赎回机制', function () {
  before(async function () {
    await initialFixture();
    await stake(wallets[29], 100, 0);
    await staking.setIsBuyUnStake(true);
  })
  it('购买总收益100%的AVA代币，方可以赎回本息', async function () {
    await time.increase(86400);
    let amountU = await rewardOfSlot(wallets[29], 0);
    let interest = new BigNumber(amountU).minus(100);
    await tokenTransfer(usdt, wallets[29], deployer,
      await tokenBalance(usdt, wallets[29])
    );
    // await expect(unStake(wallets[29], 0)).to.be.reverted;
    //
    // await tokenTransfer(usdt, deployer, wallets[29],
    //   interest.multipliedBy(10001).dividedBy(10000).toNumber()
    // );
    // let fee = parseEther((interest * 0.3).toString())
    // await expect(unStake(wallets[29], 0)).to.changeTokenBalance(
    //   usdt, wallets[29], parseEther('100').sub(fee)
    // );
    await unStake(wallets[29], 0);
  })
  it('24小时后赎回 AVA', async function () {
    await time.increase(86400 - 10);
    await expect(redeemUnStake(wallets[29], 0)).to.revertedWith('!time');

    await time.increase( 11);
    await redeemUnStake(wallets[29], 0);
  })
})

describe('本金赎回手续费机制', function () {
  before(async function () {
    await initialFixture();
    await stake(wallets[29], 100, 0);
  })
  it('0-49%可调整', async () => {
    await staking.setUnStakeFee(100);
  })
  it('本金部分扣除 “本”+“息”合计的10%手续费，自动从底池买入AVA代币转入黑洞地址', async function () {
    await time.increase(86400);
    let amountU = new BigNumber(await rewardOfSlot(wallets[29], 0));
    let interest = amountU.minus(100);

    let uB = await tokenBalance(usdt, wallets[29]);
    await unStake(wallets[29], 0);
    let uBack = new BigNumber(await tokenBalance(usdt, wallets[29])).minus(uB).toNumber();

    expect(uBack).to.closeTo(
      interest.multipliedBy(0.7).plus(100).minus(
        amountU.multipliedBy(0.1)
      ).toNumber(),
      interest.dividedBy(10000).toNumber()
    );

  })
  it('动态收益部分不变')
})

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

describe("未发送团队收益转到社区地址", function () {
  before(async function () {
    await initialFixture();
    await stake(wallets[28], 200, 0);
    await stake(wallets[29], 100, 0);
    await time.increase(86400 * 2);
  })
  // 147220315060110950
  // 147221169584167490
  it('', async function () {
    let amountU = await rewardOfSlot(wallets[29], 0);
    let interest = new BigNumber(amountU).minus(100);
    await expect(unStake(wallets[29], 0)).to.changeTokenBalance(
      usdt, team,
      '147221169584167490',
    )
  })
})

describe("未到期无法赎回", function () {
  before(async function () {
    await initialFixture();
    await stake(wallets[29], 100, 0);
    await stake(wallets[29], 100, 1);
    await stake(wallets[29], 100, 2);
  })
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
  before(async function () {
    await initialFixture();
    await stake(wallets[29], 100, 0);
  })
  it('只计算伞下实际在线的本金总额（不含自身点位)', async () => {
    expect(await getTeamKpi(wallets[29])).to.eq(0);
  })
  it('随伞下新的捐赠增加', async () => {
    for (let i = 0; i < 29; i++) {
      expect(await getTeamKpi(wallets[i])).to.eq(100);
    }
  })
  it('赎回而增减', async () => {
    await time.increase(86400);
    await unStake(wallets[29], 0);
    for (let i = 0; i < 29; i++) {
      expect(await getTeamKpi(wallets[i])).to.eq(0);
    }
  })
})

describe('权限', async function () {
  before(async () => {
    await initialFixture();
  })
  it('owner', async function () {
    await expect(staking.connect(A).setMarketingAddress(A.address)).to.revertedWith('!owner');
    await staking.transferOwnership(A.address);
    await expect(staking.setMarketingAddress(A.address)).to.revertedWith('!owner');
    await expect(staking.connect(A).setMarketingAddress(A.address)).to.be.ok;
  })
  it('admin', async function () {
    await expect(staking.connect(A).setIsBuyUnStake(false)).to.revertedWith('!admin');
    await staking.transferAdmin(A.address);
    await expect(staking.setIsBuyUnStake(false)).to.revertedWith('!admin');
    await expect(staking.connect(A).setIsBuyUnStake(false)).to.be.ok;
  })
  it('abandonedBalanceOwner', async function () {
    await expect(staking.connect(A).claimAbandonedBalance(usdt.address, 0)).to.revertedWith('!o');
    await staking.transferAbandonedBalanceOwnership(A.address);
    await expect(staking.claimAbandonedBalance(usdt.address, 0)).to.revertedWith('!o');
    await expect(staking.connect(A).claimAbandonedBalance(usdt.address, 0)).to.be.ok;
  })
})

// describe('本金总额大于等于200U才可获得推荐奖励', function () {
//   before(async function () {
//     await initialFixture();
//     await stake(wallets[29], 100, 0);
//   })
//   it('低于200无法获取动态奖', async () => {
//     expect(await isPreacher(wallets[29])).to.eq(false);
//     await stake(wallets[29], 100, 0);
//     expect(await isPreacher(wallets[29])).to.eq(true);
//   })
// })
