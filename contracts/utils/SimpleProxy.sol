// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Proxy.sol";

contract SimpleProxy is Proxy {
    constructor(address newImplementation) payable {
        // This is the keccak-256 hash of "eip1967.proxy.implementation" 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        assembly { // solium-disable-line
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, newImplementation)
        }
    }
    function _implementation() internal view virtual override returns (address) {
        address contractLogic;
        assembly { // solium-disable-line
            contractLogic := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
        return contractLogic;
    }

    function implementation() public view returns (address) {
        return _implementation();
    }
}
