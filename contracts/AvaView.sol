// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {UD60x18, ud} from "@prb/math/src/UD60x18.sol";

contract AvaView {
    uint256[3] public rates = [1000000034670200000, 1000000069236900000, 1000000138062200000];

    struct Record {
        uint32 id;
        uint40 stakeTime;
        uint128 amount;
        bool status;
        uint8 stakeIndex;
        uint40 unStakeTime; // Reward at the time of unstake
    }

    function caclItem(Record memory record) public view returns (uint256 reward){
        UD60x18 stake_amount = ud(record.amount);
        uint40 stake_time = record.stakeTime;
        uint end_time = record.unStakeTime > 0 ? record.unStakeTime : block.timestamp;
        uint40 stake_period = (uint40(end_time) - stake_time);
        stake_period = Math.min(stake_period, 30 days);
        if (stake_period == 0) reward = UD60x18.unwrap(stake_amount);
        else
            reward = UD60x18.unwrap(
                stake_amount.mul(ud(rates[record.stakeIndex]).powu(stake_period))
            );
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
