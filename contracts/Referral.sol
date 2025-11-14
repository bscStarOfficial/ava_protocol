// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IReferral.sol";
import "./abstract/Owned.sol";

/**
 * @title Referral Contract
 * @dev Manages a referral system where users can be linked to their referrers,
 * creating a hierarchical structure. It tracks direct referrals and allows
 * traversal up the referral chain.
 */
contract Referral is IReferral, Owned {
    address public rootAddress;
    address public stakingContract;

    // Mapping from a user to their referrer.
    mapping(address => address) private _referrals;

    // Mapping from a referrer to their list of direct children.
    mapping(address => address[]) private _children;

    /**
     * @dev Sets the root address of the referral tree.
     * The root is considered its own referrer to allow the first level of referrals.
     */
    constructor(address _root) Owned(msg.sender) {
        require(_root != address(0), "Root address cannot be zero");
        rootAddress = _root;
        _referrals[_root] = _root; // Root is its own parent to satisfy isBindReferral for the first level.
        emit BindReferral(_root, _root);
    }

    modifier onlyStaking() {
        require(msg.sender == stakingContract, "Caller is not the staking contract");
        _;
    }

    /**
     * @dev Sets the Staking contract address that is allowed to bind referrals.
     */
    function setStakingContract(address _stakingContract) external onlyOwner {
        require(_stakingContract != address(0), "Staking contract cannot be zero");
        stakingContract = _stakingContract;
    }

    /**
     * @dev Returns the root address of the referral system.
     */
    function getRootAddress() external view override returns (address) {
        return rootAddress;
    }

    /**
     * @dev Gets the referrer of a given address.
     * @param _address The address to query.
     * @return The referrer's address, or address(0) if none.
     */
    function getReferral(address _address) external view override returns (address) {
        return _referrals[_address];
    }

    /**
     * @dev Checks if an address is part of the referral system.
     * @param _address The address to check.
     * @return True if the address has a referrer, false otherwise.
     */
    function isBindReferral(address _address) external view override returns (bool) {
        return _referrals[_address] != address(0);
    }

    /**
     * @dev Gets the number of direct referrals for a given address.
     * @param _address The address to query.
     * @return The count of direct referrals.
     */
    function getReferralCount(address _address) external view override returns (uint256) {
        return _children[_address].length;
    }

    /**
     * @dev Retrieves the referral chain for a user, up to a specified number of levels.
     * @param _address The user's address.
     * @param _num The maximum number of upline referrals to retrieve.
     * @return An array of addresses representing the referral chain, from direct parent upwards.
     */
    function getReferrals(address _address, uint256 _num) external view override returns (address[] memory) {
        address[] memory path = new address[](_num);
        uint256 count = 0;
        address currentParent = _referrals[_address];

        // Traverse up the referral chain.
        // The condition `currentParent != _address` prevents an infinite loop if an address is its own referrer (like the root).
        while (currentParent != address(0) && currentParent != _address && count < _num) {
            path[count] = currentParent;
            count++;
            if (currentParent == rootAddress) {
                break;
            }
            currentParent = _referrals[currentParent];
        }

        // Copy the results into a correctly sized array.
        address[] memory result = new address[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = path[i];
        }
        return result;
    }

    /**
     * @dev Binds a user to a referrer.
     * This function is expected to be called by another contract (e.g., Staking contract)
     * which performs its own checks.
     * @param _referral The referrer's address.
     * @param _user The user's address to be bound.
     */
    function bindReferral(address _referral, address _user) external override onlyStaking {
        require(_user != address(0), "User is zero address");
        require(_referral != address(0), "Referral is zero address");
        require(_user != _referral, "User and referral cannot be the same");
        require(_referrals[_user] == address(0), "User already has a referral");
        require(_referrals[_referral] != address(0), "Referral is not bound");

        _referrals[_user] = _referral;
        _children[_referral].push(_user);

        emit BindReferral(_user, _referral);
    }
}
