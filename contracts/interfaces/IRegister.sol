// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IRegister {
    function getReferrer(address _address) external view returns (address);

    function getReferrers(address _address, uint256 _num) external view returns (address[] memory);

    function registered(address _address) external view returns (bool);

    function register(address _referral, address _user) external;
}
