// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract Roles is AccessControl {
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin");
        _;
    }
}
