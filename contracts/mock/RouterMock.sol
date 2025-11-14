// SPDX-License-Identifier: UNLICENSED
import {UniswapV2Router02} from "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";

contract RouterMock is UniswapV2Router02 {
    constructor(address _factory, address _WETH) UniswapV2Router02(_factory, _WETH) public {}
}
