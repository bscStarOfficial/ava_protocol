// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import '../core/interfaces/ISwapFactory.sol';
import './interfaces/ISwapRouter.sol';
import './libraries/SwapLibrary.sol';
import './interfaces/IERC20.sol';
import "../../interfaces/IManager.sol";
import "../../interfaces/IV3Pair.sol";

import "hardhat/console.sol";

contract SwapRouter is UUPSUpgradeable, ReentrancyGuardUpgradeable, ISwapRouter {
    address public immutable override factory;
    IManager public manager;
    uint public bnbFee;

    address public lpProfit;
    address public foundation;
    address public dead;

    address public ais;
    address public arb;
    ISwapPair public pair;

    uint public buyRate;  // buy fee rate ( 1:1000 )
    uint public sellRate; // sell fee rate( 1:1000 )
    bool public autoSetSellRate; // 是否自动设置卖出费率

    uint[2] public percents;
    mapping(uint => uint) public openPrices;

    constructor(address _factory) {
        factory = _factory;
    }

    function initialize(
        IManager _manager,
        address _ais,
        address _arb,
        address _foundation
    ) initializer public virtual {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        manager = _manager;
        ais = _ais;
        arb = _arb;
        pair = ISwapPair(ISwapFactory(factory).getPair(ais, arb));

        foundation = _foundation;
        dead = 0x000000000000000000000000000000000000dEaD;

        bnbFee = 0.0002 ether;

        // 2.5% lpProfit、0.5% foundation、其余销毁
        percents = [25, 5];

        buyRate = 1000;
        sellRate = 1000;
        autoSetSellRate = true;
    }


    receive() external payable {}

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address _token0,) = SwapLibrary.sortTokens(input, output);
            ISwapPair _pair = ISwapPair(SwapLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            {// scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = _pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == _token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(_pair)) - reserveInput;
                amountOutput = SwapLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == _token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? SwapLibrary.pairFor(factory, output, path[i + 2]) : _to;
            _pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function buy(
        uint amountIn,
        uint amountOutMin
    ) external virtual payable nonReentrant {
        require(false, 'stop');
        address user = msg.sender;
        require(buyRate < 1000 || manager.hasFreeRole(user), "buy1000");
        setOpenPrice();

        address[] memory path = new address[](2);
        path[0] = arb;
        path[1] = ais;

        if (bnbFee > 0) require(msg.value == bnbFee, "!fee");
        IERC20(path[0]).transferFrom(
            user, address(pair), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(path[path.length - 1]).balanceOf(address(this)) - balanceBefore;
        require(
            amountOut >= amountOutMin,
            'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );

        // 计算买入手续费
        (uint[3] memory fees, uint feeTotal) = getFee(user, amountOut, 1);
        if (fees[0] > 0) IERC20(path[1]).transfer(lpProfit, fees[0]);
        if (fees[1] > 0) IERC20(path[1]).transfer(foundation, fees[1]);
        if (fees[2] > 0) IERC20(path[1]).transfer(dead, fees[2]);

        // 剩余部分转给用户
        IERC20(path[1]).transfer(user, amountOut - feeTotal);

        updateSellRate();
    }

    function sell(
        uint amountIn,
        uint amountOutMin
    ) external virtual payable nonReentrant {
        require(false, 'stop');
        address user = msg.sender;
        require(sellRate < 1000 || manager.hasFreeRole(user), "sell1000");
        setOpenPrice();

        address[] memory path = new address[](2);
        path[0] = ais;
        path[1] = arb;

        if (bnbFee > 0) require(msg.value == bnbFee, "!fee");

        // 计算买入手续费
        (uint[3] memory fees, uint feeTotal) = getFee(user, amountIn, 0);
        if (fees[0] > 0) IERC20(path[0]).transferFrom(user, lpProfit, fees[0]);
        if (fees[1] > 0) IERC20(path[0]).transferFrom(user, foundation, fees[1]);
        if (fees[2] > 0) IERC20(path[0]).transferFrom(user, dead, fees[2]);

        // 剩余部分转给pair
        IERC20(path[0]).transferFrom(
            user, address(pair), amountIn - feeTotal
        );

        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(user);
        _swapSupportingFeeOnTransferTokens(path, user);
        uint amountOut = IERC20(path[path.length - 1]).balanceOf(user) - balanceBefore;

        require(
            amountOut >= amountOutMin,
            'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );

        updateSellRate();
    }

    function setOpenPrice() public {
        uint currentDay = block.timestamp / 86400;
        uint currentPrice = getAisPrice();
        // 设置开盘价
        if (openPrices[currentDay] == 0)
            openPrices[currentDay] = currentPrice;
    }

    function updateSellRate() public {
        // 设置卖出费率，下跌5%以内，卖出滑点都是3%。超过5%的话波动百分之几滑点就百分之几
        if (autoSetSellRate && sellRate != 1000) {
            uint currentDay = block.timestamp / 86400;
            uint currentPrice = getAisPrice();
            uint openPrice = openPrices[currentDay];
            if (currentPrice < openPrice) {
                uint rate = (openPrice - currentPrice) * 1e3 / openPrice;
                if (rate > 50 && sellRate != rate) {
                    sellRate = rate;
                } else if (sellRate != 30) {
                    sellRate = 30;
                }
            } else if (sellRate != 30){
                sellRate = 30;
            }
        }
    }

    function getFee(address user, uint amount, uint feeType) internal view returns (uint[3] memory fees, uint feeTotal) {
        if (!manager.hasFreeRole(user)) {
            uint rate;
            if (feeType == 0) {
                rate = sellRate;
            } else {
                rate = buyRate;
            }
            feeTotal = amount * rate / 1e3;
            if (feeTotal > 0) {
                fees[0] = amount * percents[0] / 1000;
                fees[1] = amount * percents[1] / 1000;
                fees[2] = amount * (rate - percents[0] - percents[1]) / 1000;
            }
        }
    }

    function getAisPrice() public view returns (uint aisPrice) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        if (reserve0 > 0) {
            uint price;
            address token0 = pair.token0();
            if (ais == token0) {
                price = reserve1 * 1e6 / reserve0;
            } else {
                price = reserve0 * 1e6 / reserve1;
            }
            aisPrice = price * getArbPrice() / 1e6;
        }
    }

    // @notice 价格精度：1e6
    function getArbPrice() public view returns (uint price) {
        if (block.chainid != 42161) price = 2 * 1e6;
        else {
            (uint160 sqrtPriceX96,,,,,,) = IV3Pair(0xcDa53B1F66614552F834cEeF361A8D12a0B8DaD8).slot0();
            uint sqrtPrice = uint(sqrtPriceX96 * 1e12 / (2 ** 96));
            // 当前精度多出1e12 因为usdt精度是6位
            price = sqrtPrice * sqrtPrice / 1e6;
        }
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return SwapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
    public
    pure
    virtual
    override
    returns (uint amountOut)
    {
        return SwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
    public
    pure
    virtual
    override
    returns (uint amountIn)
    {
        return SwapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
    public
    view
    virtual
    override
    returns (uint[] memory amounts)
    {
        return SwapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
    public
    view
    virtual
    override
    returns (uint[] memory amounts)
    {
        return SwapLibrary.getAmountsIn(factory, amountOut, path);
    }

    function claimBnbFee() external {
        manager.allowFoundation(msg.sender);
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBnbFee(uint fee) external {
        manager.allowParam(msg.sender);
        require(fee <= 0.001 ether, "max");
        bnbFee = fee;
    }

    function setBuyRate(uint _buyRate) external {
        manager.allowParam(msg.sender);
        uint fee = percents[0] + percents[1];
        require(_buyRate <= 1000 && _buyRate >= fee, "max");
        uint old = buyRate;
        buyRate = _buyRate;

        emit SetBuyRate(old, _buyRate);
    }

    function setSellRate(uint _sellRate) external {
        manager.allowParam(msg.sender);
        uint fee = percents[0] + percents[1];
        require(_sellRate <= 1000 && _sellRate >= fee, "max");
        uint old = sellRate;
        sellRate = _sellRate;

        emit SetSellRate(old, _sellRate);
    }

    function setOpenPrices(uint day, uint price) external {
        manager.allowParam(msg.sender);
        openPrices[day] = price;
    }

    function setPercents(uint[2] memory _percents) external {
        manager.allowParam(msg.sender);
        require(_percents[0] + _percents[1] <= 50, "!50");
        percents = _percents;
    }

    function setAutoSetSellRate(bool isAuto) external {
        manager.allowParam(msg.sender);
        autoSetSellRate = isAuto;
    }

    function setLpProfit(address lpProfitNew) external {
        manager.allowParam(msg.sender);
        address lpProfitOld = lpProfit;
        lpProfit = lpProfitNew;
        emit SetLpHolder(lpProfitOld, lpProfitNew);
    }

    function setFoundation(address foundationNew) external {
        manager.allowParam(msg.sender);
        address foundationOld = foundation;
        foundation = foundationNew;
        emit SetFoundation(foundationOld, foundationNew);
    }

    function setDead(address deadNew) external {
        manager.allowParam(msg.sender);
        address deadOld = dead;
        dead = deadNew;
        emit SetDead(deadOld, deadNew);
    }

    function _authorizeUpgrade(address newImplementation) internal view override {
        manager.allowUpgrade(newImplementation, msg.sender);
    }
}
