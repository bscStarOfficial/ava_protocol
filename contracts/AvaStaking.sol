// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UD60x18, ud} from "@prb/math/src/UD60x18.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IAVA} from "./interfaces/IAVA.sol";
import {IReferral} from "./interfaces/IReferral.sol";
import {Owned} from "./abstract/Owned.sol";
import {BaseSwap} from "./abstract/dex/BaseSwap.sol";

contract AvaStaking is Owned, BaseSwap {
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        uint256 index,
        uint256 stakeTime
    );

    event UnStaked(
        address indexed user,
        uint256 reward,
        uint40 timestamp,
        uint256 index
    );
    event Transfer(address indexed from, address indexed to, uint256 amount);

    uint256[3] public rates = [1000000034670200000, 1000000069236900000, 1000000138062200000];
    uint256[3] public stakeDays = [1 days, 15 days, 30 days];

    IERC20 public immutable USDT;

    IAVA public AVA;

    IReferral public REFERRAL;
    uint public unStakeFee; // 1000

    address public marketingAddress;

    uint8 public constant decimals = 18;
    string public constant name = "Staked AVA";
    string public constant symbol = "sAVA";

    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public userIndex;

    mapping(address => Record[]) public userStakeRecord;
    bool public isBuyUnStake;
    mapping(address => Record[]) public userBuyUnStakeRecord; // Buy and redeem
    mapping(address => uint256) public teamTotalInvestValue;
    mapping(address => uint256) public teamVirtuallyInvestValue;

    uint8 immutable maxD = 30;

    RecordTT[] public t_supply;

    struct RecordTT {
        uint40 stakeTime;
        uint160 tamount;
    }

    struct Record {
        uint40 stakeTime;
        uint160 amount;
        bool status;
        uint8 stakeIndex;
        uint40 unStakeTime; // Reward at the time of unstake
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "EOA");
        _;
    }

    constructor(
        IReferral REFERRAL_,
        address marketingAddress_,
        IERC20 USDT_,
        address ROUTER_
    ) Owned(msg.sender) BaseSwap(ROUTER_) {
        REFERRAL = REFERRAL_;
        USDT = USDT_;
        marketingAddress = marketingAddress_;
        USDT.approve(address(ROUTER), type(uint256).max);
    }

    function setAVA(address _ava) external onlyOwner {
        AVA = IAVA(_ava);
        AVA.approve(address(ROUTER), type(uint256).max);
    }

    function setTeamVirtuallyInvestValue(address _user, uint256 _value) external onlyOwner {
        teamVirtuallyInvestValue[_user] = _value;
    }

    function setMarketingAddress(address _account) external onlyOwner {
        marketingAddress = _account;
    }

    function setIsBuyUnStake(bool _isBuyUnStake) external onlyOwner {
        isBuyUnStake = _isBuyUnStake;
    }

    function setUnStakeFee(uint _unStakeFee) external onlyOwner {
        require(_unStakeFee < 500, 'max 49%');
        unStakeFee = _unStakeFee;
    }

    // The amount of staking in the last minute
    function network1In() public view returns (uint256 value) {
        uint256 len = t_supply.length;
        if (len == 0) return 0;
        uint256 one_last_time = block.timestamp - 1 minutes;
        uint256 last_supply = totalSupply;
        //       |
        // t0 t1 | t2 t3 t4 t5
        //       |
        for (uint256 i = len - 1; i >= 0; i--) {
            RecordTT storage stake_tt = t_supply[i];
            if (one_last_time > stake_tt.stakeTime) {
                break;
            } else {
                last_supply = stake_tt.tamount;
            }
            if (i == 0) break;
        }
        return totalSupply - last_supply;
    }

    // One percent of the pool minus the amount staked in the most recent minute,
    // with a maximum of 100.
    function maxStakeAmount() public view returns (uint256) {
        uint256 lastIn = network1In();
        uint112 reverseu = AVA.getReserveU();
        uint256 p1 = reverseu / 100;
        if (lastIn > p1) return 0;
        else return Math.min256(p1 - lastIn, 1000 ether);
    }

    function stake(uint160 _amount, uint256 amountOutMin, uint8 _stakeIndex) external onlyEOA {
        require(_amount <= maxStakeAmount(), "<1000");
        require(_stakeIndex <= 2, "<=2");
        swapAndAddLiquidity(_amount, amountOutMin);
        mint(msg.sender, _amount, _stakeIndex);
    }

    function stakeWithInviter(
        uint160 _amount,
        uint256 amountOutMin,
        uint8 _stakeIndex,
        address parent
    ) external onlyEOA {
        require(_amount <= maxStakeAmount(), "<1000");
        require(_stakeIndex <= 2, "<=2");
        swapAndAddLiquidity(_amount, amountOutMin);
        address user = msg.sender;
        if (!REFERRAL.isBindReferral(user) && REFERRAL.isBindReferral(parent)) {
            REFERRAL.bindReferral(parent, user);
        }
        mint(user, _amount, _stakeIndex);
    }

    function swapAndAddLiquidity(uint160 _amount, uint256 amountOutMin) private {
        USDT.transferFrom(msg.sender, address(this), _amount);

        uint256 balb = AVA.balanceOf(address(this));
        swapExactTokensForTokensSF(
            address(USDT),
            address(AVA),
            _amount / 2,
            amountOutMin,
            address(this)
        );
        uint256 bala = AVA.balanceOf(address(this));

        ROUTER.addLiquidity(
            address(USDT),
            address(AVA),
            _amount / 2,
            bala - balb,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function mint(address sender, uint160 _amount, uint8 _stakeIndex) private {
        require(REFERRAL.isBindReferral(sender), "!!bind");
        RecordTT memory tsy;
        tsy.stakeTime = uint40(block.timestamp);
        tsy.tamount = uint160(totalSupply);
        t_supply.push(tsy);

        Record memory order;
        order.stakeTime = uint40(block.timestamp);
        order.amount = _amount;
        order.status = false;
        order.stakeIndex = _stakeIndex;

        totalSupply += _amount;
        balances[sender] += _amount;
        Record[] storage cord = userStakeRecord[sender];
        uint256 stake_index = cord.length;
        cord.push(order);

        address[] memory referrals = REFERRAL.getReferrals(sender, maxD);
        for (uint8 i = 0; i < referrals.length; i++) {
            teamTotalInvestValue[referrals[i]] += _amount;
        }

        emit Transfer(address(0), sender, _amount);
        emit Staked(sender, _amount, block.timestamp, stake_index, stakeDays[_stakeIndex]);
    }

    function balanceOf(address account) external view returns (uint256 balance) {
        Record[] storage cord = userStakeRecord[account];
        if (cord.length > 0) {
            for (uint256 i = cord.length - 1; i >= 0; i--) {
                Record storage user_record = cord[i];
                if (user_record.status == false) {
                    balance += caclItem(user_record);
                }
                if (i == 0) break;
            }
        }
    }

    function caclItem(Record storage user_record) private view returns (uint256 reward){
        UD60x18 stake_amount = ud(user_record.amount);
        uint40 stake_time = user_record.stakeTime;
        uint40 stake_period = (uint40(block.timestamp) - stake_time);
        stake_period = Math.min(stake_period, 30 days);
        if (stake_period == 0) reward = UD60x18.unwrap(stake_amount);
        else
            reward = UD60x18.unwrap(
                stake_amount.mul(ud(rates[user_record.stakeIndex]).powu(stake_period))
            );
    }

    function rewardOfSlot(address user, uint8 index) public view returns (uint256 reward){
        Record storage user_record = userStakeRecord[user][index];
        return caclItem(user_record);
    }

    function stakeCount(address user) external view returns (uint256 count) {
        count = userStakeRecord[user].length;
    }

    function unStake(uint256 index) external onlyEOA returns (uint256) {
        (uint256 reward, uint256 stake_amount) = burn(index);

        uint256 ava_this = AVA.balanceOf(address(this));
        uint256 usdt_this = USDT.balanceOf(address(this));
        swapTokensForExactTokens(
            address(AVA),
            address(USDT),
            reward,
            ava_this,
            address(this)
        );

        uint256 ava_now = AVA.balanceOf(address(this));
        uint256 usdt_now = USDT.balanceOf(address(this));
        uint256 amount_ava = ava_this - ava_now;
        uint256 amount_usdt = usdt_now - usdt_this;
        uint256 interest;
        if (amount_usdt > stake_amount) {
            interest = amount_usdt - stake_amount;
            buyUnStake(interest);
        }
        uint256 referral_fee = referralReward(msg.sender, interest);

        address[] memory referrals = REFERRAL.getReferrals(msg.sender, maxD);
        for (uint8 i = 0; i < referrals.length; i++) {
            teamTotalInvestValue[referrals[i]] -= stake_amount;
        }
        uint256 team_fee = teamReward(referrals, interest);

        uint256 base_fee = buyAVABurn(amount_usdt);

        USDT.transfer(msg.sender, amount_usdt - referral_fee - team_fee - base_fee);
        AVA.recycle(amount_ava);
        return reward;
    }

    function burn(uint256 index) private returns (uint256 reward, uint256 amount) {
        address sender = msg.sender;
        Record[] storage cord = userStakeRecord[sender];
        Record storage user_record = cord[index];

        uint256 stakeTime = user_record.stakeTime;
        require(block.timestamp - stakeTime >= stakeDays[user_record.stakeIndex], "The time is not right");
        require(user_record.status == false, "alw");

        amount = user_record.amount;
        totalSupply -= amount;
        balances[sender] -= amount;
        emit Transfer(sender, address(0), amount);

        reward = caclItem(user_record);
        user_record.status = true;
        user_record.unStakeTime = uint40(block.timestamp);

        userIndex[sender] = userIndex[sender] + 1;

        emit UnStaked(sender, reward, uint40(block.timestamp), index);
    }

    function buyUnStake(uint interest) private {
        if (!isBuyUnStake) return;

        USDT.transferFrom(msg.sender, address(this), interest);
        uint256 balb = AVA.balanceOf(address(this));
        swapExactTokensForTokensSF(
            address(USDT),
            address(AVA),
            interest,
            0,
            address(this)
        );
        uint256 bala = AVA.balanceOf(address(this));

        Record memory order;
        order.stakeTime = uint40(block.timestamp);
        order.amount = uint160(bala - balb);
        userBuyUnStakeRecord[msg.sender].push(order);
    }

    function redeemBuyUnStake(uint index) external onlyEOA {
        Record storage record = userBuyUnStakeRecord[msg.sender][index];

        require(record.stakeTime + 86400 <= uint40(block.timestamp), '!time');
        require(!record.status, 'redeem');
        record.status = true;
        record.unStakeTime = uint40(block.timestamp);

        AVA.transfer(msg.sender, uint(record.amount));
    }

    function getTeamKpi(address _user) public view returns (uint256) {
        return teamTotalInvestValue[_user] + teamVirtuallyInvestValue[_user];
    }

    function isPreacher(address user) public view returns (bool) {
        return balances[user] >= 100e18;
    }

    function referralReward(address _user, uint256 _interest) private returns (uint256 fee) {
        fee = (_interest * 5) / 100;
        address up = REFERRAL.getReferral(_user);
        if (up != address(0) && isPreacher(up)) {
            USDT.transfer(up, fee);
        } else {
            USDT.transfer(marketingAddress, fee);
        }
    }

    function teamReward(address[] memory referrals, uint256 _interest) private returns (uint256 fee){
        address top_team;
        uint256 team_kpi;
        uint256 maxTeamRate = 20;
        uint256 spendRate = 0;
        fee = (_interest * maxTeamRate) / 100;
        for (uint256 i = 0; i < referrals.length; i++) {
            top_team = referrals[i];
            team_kpi = getTeamKpi(top_team);
            if (
                team_kpi >= 1000000 * 10 ** 18 &&
                maxTeamRate > spendRate &&
                isPreacher(top_team)
            ) {
                USDT.transfer(
                    top_team,
                    (_interest * (maxTeamRate - spendRate)) / 100
                );
                spendRate = 20;
            }

            if (
                team_kpi >= 500000 * 10 ** 18 &&
                team_kpi < 1000000 * 10 ** 18 &&
                spendRate < 16 &&
                isPreacher(top_team)
            ) {
                USDT.transfer(top_team, (_interest * (16 - spendRate)) / 100);
                spendRate = 16;
            }

            if (
                team_kpi >= 100000 * 10 ** 18 &&
                team_kpi < 500000 * 10 ** 18 &&
                spendRate < 12 &&
                isPreacher(top_team)
            ) {
                USDT.transfer(top_team, (_interest * (12 - spendRate)) / 100);
                spendRate = 12;
            }

            if (
                team_kpi >= 50000 * 10 ** 18 &&
                team_kpi < 100000 * 10 ** 18 &&
                spendRate < 8 &&
                isPreacher(top_team)
            ) {
                USDT.transfer(top_team, (_interest * (8 - spendRate)) / 100);
                spendRate = 8;
            }

            if (
                team_kpi >= 10000 * 10 ** 18 &&
                team_kpi < 50000 * 10 ** 18 &&
                spendRate < 4 &&
                isPreacher(top_team)
            ) {
                USDT.transfer(top_team, (_interest * (4 - spendRate)) / 100);
                spendRate = 4;
            }
        }
        if (maxTeamRate > spendRate) {
            USDT.transfer(marketingAddress, fee - ((_interest * spendRate) / 100));
        }
    }

    function buyAVABurn(uint amount_usdt) private returns (uint fee) {
        fee = amount_usdt * unStakeFee / 1000;
        if (fee > 0) {
            swapExactTokensForTokensSF(
                address(USDT),
                address(AVA),
                fee,
                0,
                address(0xdead)
            );
        }
    }

    function sync() external {
        uint256 w_bal = IERC20(USDT).balanceOf(address(this));
        address pair = AVA.uniswapV2Pair();
        IERC20(USDT).transfer(pair, w_bal);
        IUniswapV2Pair(pair).sync();
    }

    function emergencyWithdrawAVA(address to, uint256 _amount) external onlyOwner {
        AVA.transfer(to, _amount);
    }
}

library Math {
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint40 a, uint40 b) internal pure returns (uint40) {
        return a < b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
