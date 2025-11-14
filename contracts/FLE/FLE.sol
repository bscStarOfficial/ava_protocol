// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/ERC20StandardToken.sol";
import "../abstract/Owned.sol";
import "../interfaces/IPancake.sol";

interface INode {
    function processDividend(uint256 amount) external;
}

contract FLE is ERC20StandardToken, Ownable {

    mapping (address => bool) public isExcludedFromFees;
    address private constant fundAddress = 0x0B2e316666e925447EBb662C1f6430BC367B564d;
    address private constant operateAddress = 0x7cD54Ad04C761E5d5e0c476759f470FA98d93734;
    address private constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public stakeContract;
    address public nodeContract;

    uint256 public coolingTime = 60;
    struct UserSwapInfo {
        uint256 lastBuyTime;
        uint256 usdtAmount;
    }
    mapping(address => UserSwapInfo) public userSwaps;
    address public immutable usdtPair;
    bool public canBuy;

    constructor(string memory symbol_, string memory name_, uint8 decimals_, uint256 totalSupply_) ERC20StandardToken(symbol_, name_, decimals_, totalSupply_) {
        address factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
        address usdt = 0x55d398326f99059fF775485246999027B3197955;
        usdtPair = pairFor(factory, usdt, address(this));
        isExcludedFromFees[fundAddress] = true;
        isExcludedFromFees[operateAddress] = true;
        isExcludedFromFees[0xd38290CA161206fC47d4e09c0FA8116eE0064364] = true;
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair_) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair_ = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5'
        )))));
    }

    function setContract(address s, address n) external onlyOwner {
        stakeContract = s;
        nodeContract = n;
    }

    function setCanBuy(bool b) external onlyOwner {
        canBuy = b;
    }

    function setCool(uint256 c) external onlyOwner {
        require(c <= 3600, 'c');
        coolingTime = c;
    }

    function setExcludeFee(address a, bool b) external onlyOwner {
        isExcludedFromFees[a] = b;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        address pair = usdtPair;
        if(from != pair && to != pair) {
            super._transfer(from, to, amount);
            return;
        }
        if(isExcludedFromFees[from] || isExcludedFromFees[to]) {
            super._transfer(from, to, amount);
            return;
        }
        _subSenderBalance(from, amount);
        if(from == pair) {
            if(to != stakeContract) {
                require(canBuy, 'c');
                (uint reserveUSDT, uint reserveToken,) = IPancakePair(pair).getReserves();
                userSwaps[to].usdtAmount += getAmountIn(amount, reserveUSDT, reserveToken);
                userSwaps[to].lastBuyTime = block.timestamp;
            }else if(!canBuy) {
                _updateCanBuy(pair);
            }
            uint256 burnAmount = getBurnAmount(amount);
            uint256 hAmount = amount/100;
            if(burnAmount > 0) {
                _addReceiverBalance(from, deadAddress, burnAmount);
            }else{
                burnAmount = hAmount;
                _addReceiverBalance(from, fundAddress, burnAmount);
            }
            _addReceiverBalance(from, operateAddress, hAmount);
            _addReceiverBalance(from, nodeContract, hAmount);
            INode(nodeContract).processDividend(hAmount);
            _addReceiverBalance(from, to, amount - burnAmount - 2*hAmount);
        }else {
            if(!canBuy) {
                _updateCanBuy(pair);
            }
            if(from == stakeContract) {
                _addReceiverBalance(from, to, amount);
            }else {
                require(block.timestamp >= userSwaps[from].lastBuyTime + coolingTime, 'cool');
                uint256 fundAmount = amount*3/100;
                _addReceiverBalance(from, fundAddress, fundAmount);
                (uint reserveUSDT, uint reserveToken,) = IPancakePair(pair).getReserves();
                uint256 usdtAmount = getAmountOut(amount - fundAmount, reserveToken, reserveUSDT);
                uint256 u = userSwaps[from].usdtAmount;
                uint256 profitTax;
                if(usdtAmount <= u) {
                    userSwaps[from].usdtAmount = u - usdtAmount;
                }else if(u > 0){
                    uint256 userUSDT = (7*usdtAmount + 3*u)/10;
                    uint256 userToken = getAmountIn(userUSDT, reserveToken, reserveUSDT);
                    profitTax = amount - fundAmount - userToken;
                    userSwaps[from].usdtAmount = 0;
                }else {
                    profitTax = (amount - fundAmount)*3/10;
                }
                if(profitTax > 0) {
                    _addReceiverBalance(from, operateAddress, profitTax);
                }
                _addReceiverBalance(from, to, amount - fundAmount - profitTax);
            }
        }
    }

    function _updateCanBuy(address pair) private {
        (uint reserveUSDT, ,) = IPancakePair(pair).getReserves();
        if(reserveUSDT >= 3*10**24) {
            canBuy = true;
        }
    }

    function recycle(uint256 amount) external {
        address s = stakeContract;
        address pair = usdtPair;
        require(s == msg.sender, "r");
        super._transfer(pair, s, amount);
        uint256 fee = amount*3/100;
        if(fee < balanceOf(pair)) {
            super._transfer(pair, fundAddress, fee);
        }
        IPancakePair(pair).sync();
    }

    function addUserBuy(address addr, uint256 amount) external {
        require(msg.sender == stakeContract, "r");
        userSwaps[addr].usdtAmount += amount;
    }

    function getBurnAmount(uint256 amount) public view returns(uint256) {
        uint256 burnAmount = balanceOf(deadAddress);
        if(burnAmount >= 190*10**22) {
            return 0;
        }
        uint256 fee = amount/100;
        uint256 maxBurn = 190*10**22 - burnAmount;
        if(fee < maxBurn) {
            return fee;
        }
        return maxBurn;
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn*amountOut*10000;
        uint denominator = (reserveOut-amountOut)*9975;
        amountIn = (numerator / denominator)+1;
    }
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn*9975;
        uint numerator = amountInWithFee*reserveOut;
        uint denominator = reserveIn*10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
