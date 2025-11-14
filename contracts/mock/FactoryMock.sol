// SPDX-License-Identifier: UNLICENSED
import {UniswapV2Factory} from "@uniswap/v2-core/contracts/UniswapV2Factory.sol";


contract RouterMock is UniswapV2Factory {
    constructor(address _feeToSetter) UniswapV2Factory(_feeToSetter) public {}
}
