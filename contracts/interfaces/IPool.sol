// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPool {
    function addRewards(address token, uint256 amount) external;
    function deposit(address user, uint256 amount) external;
    function withdraw(address user, uint256 amount) external;
}