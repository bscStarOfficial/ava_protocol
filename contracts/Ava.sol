// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {FirstLaunch} from "./abstract/FirstLaunch.sol";
import {Owned} from "./abstract/Owned.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {ERC20} from "./abstract/token/ERC20.sol";
import {ExcludedFromFeeList} from "./abstract/ExcludedFromFeeList.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Helper} from "./lib/Helper.sol";
import {BaseUSDT, USDT} from "./abstract/dex/BaseUSDT.sol";
import {IStaking} from "./interfaces/IStaking.sol";

contract AVA is ExcludedFromFeeList, BaseUSDT, FirstLaunch, ERC20 {
    bool public presale;
    uint40 public coldTime = 1 minutes;

    uint256 public AmountMarketingFee;
    uint256 public AmountLPFee;

    address public profitAddress;
    address public marketingAddress;

    uint256 public swapAtAmount = 20 ether;

    mapping(address => bool) public _bcList;

    mapping(address => uint256) public tOwnedU;
    mapping(address => uint40) public lastBuyTime;
    address public STAKING;

    struct POOLUStatus {
        uint112 bal; // pool usdt reserve last time update
        uint40 t; // last update time
    }

    POOLUStatus public poolStatus;

    function setPresale() external onlyOwner {
        presale = true;
        launch();
        updatePoolReserve();
    }

    function setColdTime(uint40 _coldTime) external onlyOwner {
        coldTime = _coldTime;
    }

    // Not removable; early calls to the staking contract.
    function updatePoolReserve() public {
        require(block.timestamp >= poolStatus.t + 1 hours, "1hor");
        poolStatus.t = uint40(block.timestamp);
        (uint112 reserveU, ,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        poolStatus.bal = reserveU;
    }

    function updatePoolReserve(uint112 reserveU) private {
        if (block.timestamp >= poolStatus.t + 1 hours) {
            poolStatus.t = uint40(block.timestamp);
            poolStatus.bal = reserveU;
        }
    }

    function getReserveU() external view returns (uint112) {
        return poolStatus.bal;
    }

    constructor(
        address _staking,
        address profitAddress_,
        address marketingAddress_
    ) Owned(msg.sender) ERC20("LAF", "LAF", 18, 1310000 ether) {
        allowance[address(this)][address(uniswapV2Router)] = type(uint256).max;
        IERC20(USDT).approve(address(uniswapV2Router), type(uint256).max);
        STAKING = _staking;
        profitAddress = profitAddress_;
        marketingAddress = marketingAddress_;

        excludeFromFee(msg.sender);
        excludeFromFee(address(this));
        excludeFromFee(STAKING);
        excludeFromFee(profitAddress);
        excludeFromFee(marketingAddress);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(isReward(sender) == 0, "isReward != 0 !");
        if (
            inSwapAndLiquify ||
            _isExcludedFromFee[sender] ||
            _isExcludedFromFee[recipient]
        ) {
            super._transfer(sender, recipient, amount);
            return;
        }
        require(
            !Helper.isContract(recipient) || uniswapV2Pair == recipient,
            "contract"
        );
        if (uniswapV2Pair == sender) {
            require(presale, "pre");

            // buy
            unchecked {
                (uint112 reserveU, uint112 reserveThis,) = IUniswapV2Pair(
                    uniswapV2Pair
                ).getReserves();
                require(amount <= reserveThis / 10, "max cap buy"); //每次买单最多只能卖池子的10%
                updatePoolReserve(reserveU);
                uint256 amountUBuy = Helper.getAmountIn(
                    amount,
                    reserveU,
                    reserveThis
                );
                tOwnedU[recipient] = tOwnedU[recipient] + amountUBuy;
                lastBuyTime[recipient] = uint40(block.timestamp);

                uint256 fee;
                uint256 burnAmount = balanceOf[address(0xdead)];
                if (burnAmount < 1000000 * 10 ** 18) {
                    fee = (amount * 5) / 1000;
                    fee = 1000000 * 10 ** 18 - burnAmount > fee
                        ? fee
                        : 1000000 * 10 ** 18 - burnAmount;
                    super._transfer(sender, address(0xdead), fee);
                }
                uint256 LPFee = (amount * 25) / 1000;
                AmountLPFee += LPFee;
                super._transfer(sender, address(this), LPFee);
                super._transfer(sender, recipient, amount - fee - LPFee);
            }
        } else if (uniswapV2Pair == recipient) {
            require(presale, "pre");
            require(block.timestamp >= lastBuyTime[sender] + coldTime, "cold");
            //sell
            (uint112 reserveU, uint112 reserveThis,) = IUniswapV2Pair(
                uniswapV2Pair
            ).getReserves();
            require(amount <= reserveThis / 10, "max cap sell"); //每次卖单最多只能卖池子的20%
            uint256 marketingFee = (amount * marketingFeeRate()) / 1000;
            uint256 amountUOut = Helper.getAmountOut(
                amount - marketingFee,
                reserveThis,
                reserveU
            );
            updatePoolReserve(reserveU);
            uint256 fee;
            if (tOwnedU[sender] >= amountUOut) {
                unchecked {
                    tOwnedU[sender] = tOwnedU[sender] - amountUOut;
                }
            } else if (tOwnedU[sender] > 0 && tOwnedU[sender] < amountUOut) {
                uint256 profitU = amountUOut - tOwnedU[sender];
                uint256 profitThis = Helper.getAmountOut(
                    profitU,
                    reserveU,
                    reserveThis
                );
                fee = profitThis / 4;
                tOwnedU[sender] = 0;
            } else {
                fee = amount / 4;
                tOwnedU[sender] = 0;
            }

            if (fee > 0) {
                super._transfer(sender, address(this), fee);
                if (shouldSwapProfit(fee)) {
                    swapProfit(fee);
                }
            }
            if (shouldSwapTokenForFund(AmountLPFee + AmountMarketingFee)) {
                swapTokenForFund();
            }
            super._transfer(sender, address(this), marketingFee);
            AmountMarketingFee += marketingFee;
            super._transfer(sender, recipient, amount - fee - marketingFee);
        } else {
            // normal transfer
            super._transfer(sender, recipient, amount);
        }
    }

    function marketingFeeRate() internal view returns (uint256 result) {
        result = 30;
        if (
            launchedAtTimestamp > 0 &&
            block.timestamp - launchedAtTimestamp <= 15 minutes
        ) {
            result = 80;
        }
    }

    function shouldSwapTokenForFund(uint256 amount) internal view returns (bool) {
        if (amount >= swapAtAmount && !inSwapAndLiquify) {
            return true;
        } else {
            return false;
        }
    }

    function swapTokenForFund() internal lockTheSwap {
        if (AmountMarketingFee > 0) {
            swapTokenForUsdt(AmountMarketingFee, marketingAddress);
            AmountMarketingFee = 0;
        }

        if (AmountLPFee > 0) {
            swapAndLiquify(AmountLPFee);
            AmountLPFee = 0;
        }
    }

    function shouldSwapProfit(uint256 amount) internal view returns (bool) {
        if (amount >= 1 gwei && !inSwapAndLiquify) {
            return true;
        } else {
            return false;
        }
    }

    function swapProfit(uint256 tokenAmount) internal lockTheSwap {
        uint256 bal = balanceOf[address(this)] -
                    AmountLPFee -
                    AmountMarketingFee;
        uint256 t2 = tokenAmount * 2;
        uint256 amountIn = t2 >= bal ? bal : t2;
        unchecked {
            swapTokenForUsdt(amountIn, address(distributor));
            uint256 amount = IERC20(USDT).balanceOf(address(distributor));

            IERC20(USDT).transferFrom(
                address(distributor),
                profitAddress,
                amount
            );
        }
    }

    // After selling LAF, the price dropped. The USDT allocation decreased, resulting in excess USDT.
    function swapAndLiquify(uint256 tokens) internal {
        IERC20 usdt = IERC20(USDT);
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;
        uint256 initialBalance = usdt.balanceOf(address(this));
        swapTokenForUsdt(half, address(distributor));
        usdt.transferFrom(
            address(distributor),
            address(this),
            usdt.balanceOf(address(distributor))
        );
        uint256 newBalance = usdt.balanceOf(address(this)) - initialBalance;
        addLiquidity(otherHalf, newBalance);
    }

    function addLiquidity(uint256 tokenAmount, uint256 usdtAmount) internal {
        uniswapV2Router.addLiquidity(
            address(this),
            address(USDT),
            tokenAmount,
            usdtAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    function swapTokenForUsdt(uint256 tokenAmount, address to) internal {
        unchecked {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = address(USDT);
        // make the swap
            uniswapV2Router
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                to,
                block.timestamp
            );
        }
    }

    function recycle(uint256 amount) external {
        require(STAKING == msg.sender, "cycle");
        uint256 maxBurn = balanceOf[uniswapV2Pair] / 3;
        uint256 burn_maount = amount >= maxBurn ? maxBurn : amount;
        super._transfer(uniswapV2Pair, STAKING, burn_maount);
        IUniswapV2Pair(uniswapV2Pair).sync();
    }

    function claimAbandonedBalance(address token, uint amount) external {
        require(msg.sender == abandonedBalanceOwner, '!o');
        require(token != address(this), '!this');

        IERC20(token).transfer(msg.sender, amount);
    }

    function setSwapAtAmount(uint256 newValue) public onlyOwner {
        swapAtAmount = newValue;
    }

    function setMarketingAddress(address addr) external onlyOwner {
        marketingAddress = addr;
        excludeFromFee(addr);
    }

    function setProfitAddress(address addr) external onlyOwner {
        profitAddress = addr;
        excludeFromFee(addr);
    }

    function setStaking(address addr) external onlyOwner {
        STAKING = addr;
        excludeFromFee(addr);
    }

    function multi_bclist(address[] calldata addresses, bool value) public onlyOwner {
        require(addresses.length < 201);
        for (uint256 i; i < addresses.length; ++i) {
            _bcList[addresses[i]] = value;
        }
    }

    function isReward(address account) public view returns (uint256) {
        if (_bcList[account]) {
            return 1;
        } else {
            return 0;
        }
    }
}
