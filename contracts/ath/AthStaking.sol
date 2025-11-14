// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UD60x18, ud} from "@prb/math/src/UD60x18.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IATH} from "../interfaces/IATH.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IReferral} from "../interfaces/IReferral.sol";
import {Owned} from "../abstract/Owned.sol";
import {_USDT, _ROUTER} from "../lib/Const.sol";

contract AthStaking is Owned {
    uint256 constant S1_THRESHOLD = 3000 * 10**18; // test: 3000
    uint256 constant S2_THRESHOLD = 30000 * 10**18; // test: 6000
    uint256 constant S3_THRESHOLD = 100000 * 10**18; // test: 9000
    uint256 constant S4_THRESHOLD = 500000 * 10**18; // test: 12000
    uint256 constant S5_THRESHOLD = 1000000 * 10**18; // test: 15000
    uint256 constant S6_THRESHOLD = 3000000 * 10**18; // test: 18000
    uint256 constant S7_THRESHOLD = 5000000 * 10**18; // test: 21000

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        uint256 index,
        uint256 stakeTime
    );

    event RewardPaid(
        address indexed user,
        uint256 reward,
        uint40 timestamp,
        uint256 index
    );
    event Transfer(address indexed from, address indexed to, uint256 amount);

    uint256[3] rates = [1000000034670200000,1000000069236900000,1000000138062200000];
    uint256[3] stakeDays = [1 days,15 days,30 days];

    IUniswapV2Router02 constant ROUTER = IUniswapV2Router02(_ROUTER);
    IERC20 constant USDT = IERC20(_USDT);

    IATH public ATH;

    IReferral public REFERRAL;

    address marketingAddress;

    address public s5Address;
    address public s6Address;
    address public s7Address;

    uint256 public s5Count;
    uint256 public s6Count;
    uint256 public s7Count;

    uint8 public constant decimals = 18;
    string public constant name = "Staked ATH";
    string public constant symbol = "sATH";

    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public userIndex;

    mapping(address => Record[]) public userStakeRecord;
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
        uint256 finalReward; // Reward at the time of unstake
        uint256 id;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "EOA");
        _;
    }

    constructor(address REFERRAL_,address marketingAddress_) Owned(msg.sender) {
        REFERRAL = IReferral(REFERRAL_);
        marketingAddress = marketingAddress_;
        USDT.approve(address(ROUTER), type(uint256).max);
    }

    function setAthena(address _ath) external onlyOwner {
        ATH = IATH(_ath);
        ATH.approve(address(ROUTER), type(uint256).max);
    }

    function setTeamVirtuallyInvestValue(address _user, uint256 _value)
        external
        onlyOwner
    {
        uint256 oldKpi = getTeamKpi(_user);
        teamVirtuallyInvestValue[_user] = _value;
        uint256 newKpi = teamTotalInvestValue[_user] + _value;
        _updateTeamLevelCounts(_user, oldKpi, newKpi);
    }

    function setMarketingAddress(address _account) external  onlyOwner{
        marketingAddress = _account;
    }

    function setS5Address(address _addr) external onlyOwner {
        s5Address = _addr;
    }

    function setS6Address(address _addr) external onlyOwner {
        s6Address = _addr;
    }

    function setS7Address(address _addr) external onlyOwner {
        s7Address = _addr;
    }

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

    function maxStakeAmount() public view returns (uint256) {
        uint256 lastIn = network1In();
        uint112 reverseu = ATH.getReserveU();
        uint256 p1 = reverseu / 100;
        if (lastIn > p1) return 0;
        else return Math.min256(p1 - lastIn, 1000 ether);
    }

    function stake(uint160 _amount, uint256 amountOutMin,uint8 _stakeIndex) external onlyEOA {
        require(_amount <= maxStakeAmount(), "<1000");
        require(_stakeIndex<=2,"<=2");
        swapAndAddLiquidity(_amount, amountOutMin);
        mint(msg.sender, _amount,_stakeIndex);
    }

    function stakeWithInviter(
        uint160 _amount,
        uint256 amountOutMin,
        uint8 _stakeIndex,
        address parent
    ) external onlyEOA {
        require(_amount <= maxStakeAmount(), "<1000");
        require(_stakeIndex<=2,"<=2");
        swapAndAddLiquidity(_amount, amountOutMin);
        address user = msg.sender;
        if (!REFERRAL.isBindReferral(user) && REFERRAL.isBindReferral(parent)) {
            REFERRAL.bindReferral(parent, user);
        }
        mint(user, _amount,_stakeIndex);
    }

    function swapAndAddLiquidity(uint160 _amount, uint256 amountOutMin)
        private
    {
        USDT.transferFrom(msg.sender, address(this), _amount);

        address[] memory path = new address[](2);
        path = new address[](2);
        path[0] = address(USDT);
        path[1] = address(ATH);
        uint256 balb = ATH.balanceOf(address(this));
        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount / 2,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
        uint256 bala = ATH.balanceOf(address(this));
        ROUTER.addLiquidity(
            address(USDT),
            address(ATH),
            _amount / 2,
            bala - balb,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function mint(address sender, uint160 _amount,uint8 _stakeIndex) private {
        require(REFERRAL.isBindReferral(sender),"!!bind");
        RecordTT memory tsy;
        tsy.stakeTime = uint40(block.timestamp);
        tsy.tamount = uint160(totalSupply);
        t_supply.push(tsy);

        Record[] storage cord = userStakeRecord[sender];
        uint256 stake_index = cord.length;

        Record memory order;
        order.stakeTime = uint40(block.timestamp);
        order.amount = _amount;
        order.status = false;
        order.stakeIndex = _stakeIndex;
        order.id = stake_index;

        totalSupply += _amount;
        balances[sender] += _amount;
        cord.push(order);

        address[] memory referrals = REFERRAL.getReferrals(sender, maxD);
        for (uint8 i = 0; i < referrals.length; i++) {
            address referral = referrals[i];
            uint256 oldKpi = getTeamKpi(referral);
            teamTotalInvestValue[referral] += _amount;
            _updateTeamLevelCounts(referral, oldKpi, oldKpi + _amount);
        }

        emit Transfer(address(0), sender, _amount);
        emit Staked(sender, _amount, block.timestamp, stake_index,stakeDays[_stakeIndex]);
    }

    function balanceOf(address account)
        external
        view
        returns (uint256 balance)
    {
        Record[] storage cord = userStakeRecord[account];
        if (cord.length > 0) {
            for (uint256 i = cord.length - 1; i >= 0; i--) {
                Record storage user_record = cord[i];
                if (user_record.status == false) {
                    balance += caclItem(user_record);
                }
                // else {
                //     continue;
                // }
                if (i == 0) break;
            }
        }
    }

    function caclItem(Record storage user_record)
        private
        view
        returns (uint256 reward)
    {
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

    function rewardOfSlot(address user, uint256 index)
        public
        view
        returns (uint256 reward)
    {
        Record storage user_record = userStakeRecord[user][index];
        return caclItem(user_record);
    }

    function stakeCount(address user) external view returns (uint256 count) {
        count = userStakeRecord[user].length;
    }

    function getUserRecords(
        address _user,
        uint256 _offset,
        uint256 _limit,
        uint8 _status // 0: ongoing, 1: redeemed
    ) external view returns (Record[] memory records, uint256 total) {
        Record[] storage allRecords = userStakeRecord[_user];
        uint256 allRecordsCount = allRecords.length;
        bool targetStatus = (_status == 1);

        Record[] memory resultPage = new Record[](_limit);
        uint256 resultCount = 0;
        uint256 totalFilteredCount = 0;

        for (uint256 i = allRecordsCount; i > 0; i--) { // Newest first
            uint256 index = i - 1;
            if (allRecords[index].status == targetStatus) {
                if (totalFilteredCount >= _offset && resultCount < _limit) {
                    resultPage[resultCount] = allRecords[index];
                    resultCount++;
                }
                totalFilteredCount++;
            }
        }

        // Resize the array to the actual number of records found for the page.
        records = new Record[](resultCount);
        for (uint256 j = 0; j < resultCount; j++) {
            records[j] = resultPage[j];
        }

        return (records, totalFilteredCount);
    }

    function unstake(uint256 index) external onlyEOA returns (uint256) {
        (uint256 reward, uint256 stake_amount) = burn(index);
        uint256 bal_this = ATH.balanceOf(address(this));
        uint256 usdt_this = USDT.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(ATH);
        path[1] = address(USDT);
        ROUTER.swapTokensForExactTokens(
            reward,
            bal_this,
            path,
            address(this),
            block.timestamp
        );
        uint256 bal_now = ATH.balanceOf(address(this));
        uint256 usdt_now = USDT.balanceOf(address(this));
        uint256 amount_lab = bal_this - bal_now;
        uint256 amount_usdt = usdt_now - usdt_this;
        uint256 interset;
        if (amount_usdt > stake_amount) {
            interset = amount_usdt - stake_amount;
        }

        address[] memory referrals = REFERRAL.getReferrals(msg.sender, maxD);
        uint256 s_fee_usdt = (interset * 7) / 100;
        uint256 team_fee_usdt = (interset * 28) / 100;
        uint256 total_reward_usdt = s_fee_usdt + team_fee_usdt;

        if (total_reward_usdt > 0) {
            address[] memory path_usdt_to_ath = new address[](2);
            path_usdt_to_ath[0] = address(USDT);
            path_usdt_to_ath[1] = address(ATH);

            uint256[] memory amounts = ROUTER.getAmountsOut(
                total_reward_usdt,
                path_usdt_to_ath
            );
            uint256 amount_out_min = (amounts[1] * 90) / 100;

            uint256 ath_bal_before_swap = ATH.balanceOf(address(this));
            ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                total_reward_usdt,
                amount_out_min, // 10% slippage
                path_usdt_to_ath,
                address(this),
                block.timestamp
            );
            uint256 ath_bal_after_swap = ATH.balanceOf(address(this));
            uint256 total_ath_reward_amount = ath_bal_after_swap -
                ath_bal_before_swap;

            if (total_ath_reward_amount > 0) {
                uint256 s_level_ath_total = (total_ath_reward_amount *
                    s_fee_usdt) / total_reward_usdt;
                uint256 ath_distributed = 0;

                address s5Target = (s5Count > 0 && s5Address != address(0))
                    ? s5Address
                    : marketingAddress;
                uint256 s5_ath = (s_level_ath_total * 4) / 7;
                ATH.transfer(s5Target, s5_ath);
                if (s5Target == s5Address) {
                    IPool(s5Address).addRewards(address(ATH), s5_ath);
                }
                ath_distributed += s5_ath;

                address s6Target = (s6Count > 0 && s6Address != address(0))
                    ? s6Address
                    : marketingAddress;
                uint256 s6_ath = (s_level_ath_total * 2) / 7;
                ATH.transfer(s6Target, s6_ath);
                if (s6Target == s6Address) {
                    IPool(s6Address).addRewards(address(ATH), s6_ath);
                }
                ath_distributed += s6_ath;

                address s7Target = (s7Count > 0 && s7Address != address(0))
                    ? s7Address
                    : marketingAddress;
                uint256 s7_ath = s_level_ath_total - ath_distributed;
                ATH.transfer(s7Target, s7_ath);
                if (s7Target == s7Address) {
                    IPool(s7Address).addRewards(address(ATH), s7_ath);
                }

                uint256 team_level_ath_total = total_ath_reward_amount -
                    s_level_ath_total;
                distributeTeamRewardATH(
                    referrals,
                    interset,
                    team_level_ath_total
                );
            }
        }

        for (uint8 i = 0; i < referrals.length; i++) {
            address referral = referrals[i];
            uint256 oldKpi = getTeamKpi(referral);
            teamTotalInvestValue[referral] -= stake_amount;
            _updateTeamLevelCounts(referral, oldKpi, oldKpi - stake_amount);
        }

        USDT.transfer(msg.sender, amount_usdt - total_reward_usdt);
        ATH.recycle(amount_lab);
        return reward;
    }

    function burn(uint256 index)
        private
        returns (uint256 reward, uint256 amount)
    {
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
        user_record.finalReward = reward;
        user_record.status = true;

        userIndex[sender] = userIndex[sender] + 1;

        emit RewardPaid(sender, reward, uint40(block.timestamp), index);
    }

    function getTeamKpi(address _user) public view returns (uint256) {
        return teamTotalInvestValue[_user] + teamVirtuallyInvestValue[_user];
    }

    function isPreacher(address user) public view returns (bool) {
        return balances[user] >= 200e18;
    }

    function distributeTeamRewardATH(
        address[] memory referrals,
        uint256 _interset,
        uint256 total_team_ath
    ) private {
        if (total_team_ath == 0) return;
        uint256 maxTeamRate = 28;
        uint256 total_team_usdt = (_interset * maxTeamRate) / 100;
        if (total_team_usdt == 0) {
            ATH.transfer(marketingAddress, total_team_ath);
            return;
        }

        address top_team;
        uint256 team_kpi;
        uint256 spendRate = 0;
        uint256 ath_distributed = 0;

        for (uint256 i = 0; i < referrals.length; i++) {
            top_team = referrals[i];
            team_kpi = getTeamKpi(top_team);

            if (
                team_kpi >= S7_THRESHOLD && maxTeamRate > spendRate && isPreacher(top_team)
            ) {
                uint256 current_rate = maxTeamRate - spendRate;
                uint256 reward_ath = (total_team_ath * current_rate) /
                    maxTeamRate;
                ATH.transfer(top_team, reward_ath);
                ath_distributed += reward_ath;
                spendRate = maxTeamRate;
            } else if (
                team_kpi >= S6_THRESHOLD && spendRate < 24 && isPreacher(top_team)
            ) {
                uint256 current_rate = 24 - spendRate;
                uint256 reward_ath = (total_team_ath * current_rate) /
                    maxTeamRate;
                ATH.transfer(top_team, reward_ath);
                ath_distributed += reward_ath;
                spendRate = 24;
            } else if (
                team_kpi >= S5_THRESHOLD && spendRate < 20 && isPreacher(top_team)
            ) {
                uint256 current_rate = 20 - spendRate;
                uint256 reward_ath = (total_team_ath * current_rate) /
                    maxTeamRate;
                ATH.transfer(top_team, reward_ath);
                ath_distributed += reward_ath;
                spendRate = 20;
            } else if (
                team_kpi >= S4_THRESHOLD && spendRate < 16 && isPreacher(top_team)
            ) {
                uint256 current_rate = 16 - spendRate;
                uint256 reward_ath = (total_team_ath * current_rate) /
                    maxTeamRate;
                ATH.transfer(top_team, reward_ath);
                ath_distributed += reward_ath;
                spendRate = 16;
            } else if (
                team_kpi >= S3_THRESHOLD && spendRate < 12 && isPreacher(top_team)
            ) {
                uint256 current_rate = 12 - spendRate;
                uint256 reward_ath = (total_team_ath * current_rate) /
                    maxTeamRate;
                ATH.transfer(top_team, reward_ath);
                ath_distributed += reward_ath;
                spendRate = 12;
            } else if (
                team_kpi >= S2_THRESHOLD && spendRate < 8 && isPreacher(top_team)
            ) {
                uint256 current_rate = 8 - spendRate;
                uint256 reward_ath = (total_team_ath * current_rate) /
                    maxTeamRate;
                ATH.transfer(top_team, reward_ath);
                ath_distributed += reward_ath;
                spendRate = 8;
            } else if (
                team_kpi >= S1_THRESHOLD && spendRate < 4 && isPreacher(top_team)
            ) {
                uint256 current_rate = 4 - spendRate;
                uint256 reward_ath = (total_team_ath * current_rate) /
                    maxTeamRate;
                ATH.transfer(top_team, reward_ath);
                ath_distributed += reward_ath;
                spendRate = 4;
            }
        }

        if (ath_distributed < total_team_ath) {
            ATH.transfer(marketingAddress, total_team_ath - ath_distributed);
        }
    }

    function _updateTeamLevelCounts(
        address user,
        uint256 oldKpi,
        uint256 newKpi
    ) private {
        // Determine old level
        uint8 oldLevel;
        if (oldKpi >= S7_THRESHOLD) {
            oldLevel = 7;
        } else if (oldKpi >= S6_THRESHOLD) {
            oldLevel = 6;
        } else if (oldKpi >= S5_THRESHOLD) {
            oldLevel = 5;
        }

        // Determine new level
        uint8 newLevel;
        if (newKpi >= S7_THRESHOLD) {
            newLevel = 7;
        } else if (newKpi >= S6_THRESHOLD) {
            newLevel = 6;
        } else if (newKpi >= S5_THRESHOLD) {
            newLevel = 5;
        }

        if (oldLevel == newLevel) {
            return;
        }

        // Withdraw from old level's pool
        if (oldLevel == 7) {
            s7Count--;
            if (s7Address != address(0)) {
                IPool(s7Address).withdraw(user, 1e18);
            }
        } else if (oldLevel == 6) {
            s6Count--;
            if (s6Address != address(0)) {
                IPool(s6Address).withdraw(user, 1e18);
            }
        } else if (oldLevel == 5) {
            s5Count--;
            if (s5Address != address(0)) {
                IPool(s5Address).withdraw(user, 1e18);
            }
        }

        // Deposit to new level's pool
        if (newLevel == 7) {
            s7Count++;
            if (s7Address != address(0)) {
                IPool(s7Address).deposit(user, 1e18);
            }
        } else if (newLevel == 6) {
            s6Count++;
            if (s6Address != address(0)) {
                IPool(s6Address).deposit(user, 1e18);
            }
        } else if (newLevel == 5) {
            s5Count++;
            if (s5Address != address(0)) {
                IPool(s5Address).deposit(user, 1e18);
            }
        }
    }

    function sync() external {
        uint256 w_bal = IERC20(USDT).balanceOf(address(this));
        address pair = ATH.uniswapV2Pair();
        IERC20(USDT).transfer(pair, w_bal);
        IUniswapV2Pair(pair).sync();
    }

    function emergencyWithdrawATH(address to, uint256 _amount)
        external
        onlyOwner
    {
        ATH.transfer(to, _amount);
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
