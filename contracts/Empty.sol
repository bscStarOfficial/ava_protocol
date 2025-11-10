// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IManager.sol";

// 空合约，提前部署设置ExcludedFromFee, 后续升级
contract Empty is Initializable, UUPSUpgradeable {
    IManager public manager;

    function initialize(IManager _manager) initializer public {
        __UUPSUpgradeable_init();
        manager = _manager;
    }

    // 如果newImplementation没有upgradeTo方法，则无法继续升级
    function _authorizeUpgrade(address newImplementation) internal view override {
        manager.allowUpgrade(newImplementation, msg.sender);
    }
}
