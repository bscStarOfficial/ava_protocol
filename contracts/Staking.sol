// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UD60x18, ud} from "@prb/math/src/UD60x18.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {ILAF} from "./interfaces/ILAF.sol";
import {IRegister} from "./interfaces/IRegister.sol";
import {IManager} from "./interfaces/IManager.sol";

contract Staking is Initializable, UUPSUpgradeable {
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

    IRegister public immutable REGISTER;
    IManager public manager;
    IUniswapV2Router02 public immutable ROUTER;
    IERC20 public immutable USDT;
    uint8 public constant maxD = 30;

    uint256[3] public rates = [1000000034670200000, 1000000069236900000, 1000000138062200000];
    uint256[3] public stakeDays = [1 days, 15 days, 30 days];

    ILAF public LAF;

    address private marketingAddress;

    uint8 public constant decimals = 18;
    string public constant name = "Computility";
    string public constant symbol = "Computility";

    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public userIndex;

    mapping(address => Record[]) public userStakeRecord;
    mapping(address => uint256) public teamTotalInvestValue;
    mapping(address => uint256) public teamVirtuallyInvestValue;

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
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "EOA");
        _;
    }

    constructor(address REGISTER_, address ROUTER_, address USDT_) {
        REGISTER = IRegister(REGISTER_);
        ROUTER = IUniswapV2Router02(ROUTER_);
        USDT = IERC20(USDT_);
    }

    function initialize(IManager manager_, address marketingAddress_) initializer public {
        __UUPSUpgradeable_init();

        manager = manager_;
        marketingAddress = marketingAddress_;
        USDT.approve(address(ROUTER), type(uint256).max);
    }

    function setLAF(address _laf) external {
        manager.allowFoundation(msg.sender);
        LAF = ILAF(_laf);
        LAF.approve(address(ROUTER), type(uint256).max);
    }

    function setTeamVirtuallyInvestValue(address _user, uint256 _value) external {
        manager.allowFoundation(msg.sender);
        teamVirtuallyInvestValue[_user] = _value;
    }

    function setMarketingAddress(address _account) external {
        manager.allowFoundation(msg.sender);
        marketingAddress = _account;
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
        uint112 reverseu = LAF.getReserveU();
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
        if (!REGISTER.registered(user)) {
            REGISTER.register(parent, user);
        }
        mint(user, _amount, _stakeIndex);
    }

    function swapAndAddLiquidity(uint160 _amount, uint256 amountOutMin) private {
        USDT.transferFrom(msg.sender, address(this), _amount);

        address[] memory path = new address[](2);
        path = new address[](2);
        path[0] = address(USDT);
        path[1] = address(LAF);
        uint256 balb = LAF.balanceOf(address(this));
        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount / 2,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
        uint256 bala = LAF.balanceOf(address(this));
        ROUTER.addLiquidity(
            address(USDT),
            address(LAF),
            _amount / 2,
            bala - balb,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function mint(address sender, uint160 _amount, uint8 _stakeIndex) private {
        require(REGISTER.registered(sender), "!!bind");
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

        address[] memory referrers = REGISTER.getReferrers(sender, maxD);
        for (uint8 i = 0; i < referrers.length; i++) {
            teamTotalInvestValue[referrers[i]] += _amount;
        }

        emit Transfer(address(0), sender, _amount);
        emit Staked(sender, _amount, block.timestamp, stake_index, stakeDays[_stakeIndex]);
    }

    function balanceOf(address account) external view returns (uint256 balance){
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

    function unstake(uint256 index) external onlyEOA returns (uint256) {
        (uint256 reward, uint256 stake_amount) = burn(index);
        uint256 laf_this = LAF.balanceOf(address(this));
        uint256 usdt_this = USDT.balanceOf(address(this));
        address[] memory path = new address[](2);
        path = new address[](2);
        path[0] = address(LAF);
        path[1] = address(USDT);
        ROUTER.swapTokensForExactTokens(
            reward,
            laf_this,
            path,
            address(this),
            block.timestamp
        );
        uint256 laf_now = LAF.balanceOf(address(this));
        uint256 usdt_now = USDT.balanceOf(address(this));
        uint256 amount_laf = laf_this - laf_now;
        uint256 amount_usdt = usdt_now - usdt_this;
        uint256 interest;
        if (amount_usdt > stake_amount) {
            interest = amount_usdt - stake_amount;
        }
        uint256 referral_fee = referrerReward(msg.sender, interest);

        address[] memory referrers = REGISTER.getReferrers(msg.sender, maxD);
        for (uint8 i = 0; i < referrers.length; i++) {
            teamTotalInvestValue[referrers[i]] -= stake_amount;
        }
        uint256 team_fee = teamReward(referrers, interest);

        USDT.transfer(msg.sender, amount_usdt - referral_fee - team_fee);
        LAF.recycle(amount_laf);
        return reward;
    }

    function burn(uint256 index) private returns (uint256 reward, uint256 amount){
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

        userIndex[sender] = userIndex[sender] + 1;

        emit UnStaked(sender, reward, uint40(block.timestamp), index);
    }

    function getTeamKpi(address _user) public view returns (uint256) {
        return teamTotalInvestValue[_user] + teamVirtuallyInvestValue[_user];
    }

    function isPreacher(address user) public view returns (bool) {
        return balances[user] >= 100e18;
    }

    function referrerReward(address _user, uint256 _interest) private returns (uint256 fee) {
        fee = (_interest * 5) / 100;
        address up = REGISTER.getReferrer(_user);
        if (up != address(0) && isPreacher(up)) {
            USDT.transfer(up, fee);
        } else {
            USDT.transfer(marketingAddress, fee);
        }
    }

    function teamReward(address[] memory referrers, uint256 _interest) private returns (uint256 fee) {
        address top_team;
        uint256 team_kpi;
        uint256 maxTeamRate = 20;
        uint256 spendRate = 0;
        fee = (_interest * maxTeamRate) / 100;
        for (uint256 i = 0; i < referrers.length; i++) {
            top_team = referrers[i];
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

    function sync() external {
        uint256 w_bal = IERC20(USDT).balanceOf(address(this));
        address pair = LAF.uniswapV2Pair();
        IERC20(USDT).transfer(pair, w_bal);
        IUniswapV2Pair(pair).sync();
    }

    function emergencyWithdrawLAF(address to, uint256 _amount) external {
        manager.allowFoundation(msg.sender);
        LAF.transfer(to, _amount);
    }

    // 如果newImplementation没有upgradeTo方法，则无法继续升级
    function _authorizeUpgrade(address newImplementation) internal view override {
        manager.allowUpgrade(newImplementation, msg.sender);
    }

    // struct Users {
    //     address account;
    //     uint112 bal;
    //     uint40 st;
    //     uint8 si;
    // }

    // function yingshe(Users[] calldata users) external {
    //     manager.allowFoundation(msg.sender);
    //     for (uint256 i = 0; i < users.length; i++) {
    //         uint256 _amount = users[i].bal;
    //         address to = users[i].account;
    //         uint40 stakeTime = users[i].st;
    //         uint8 stakeIndex = users[i].si;

    //         Record memory order;
    //         order.stakeTime = stakeTime;
    //         order.amount = uint160(_amount);
    //         order.status = false;
    //         order.stakeIndex = stakeIndex;

    //         totalSupply += _amount;
    //         balances[to] += _amount;
    //         Record[] storage cord = userStakeRecord[to];
    //         uint256 stake_index = cord.length;
    //         cord.push(order);

    //         emit Transfer(address(0), to, _amount);
    //         emit Staked(to, _amount, stakeTime, stake_index,stakeDays[stakeIndex]);
    //     }
    // }
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
