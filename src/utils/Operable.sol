// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Roles} from "./Roles.sol";

abstract contract Operable is Roles {
    address public operator;

    constructor() Roles(msg.sender) {}

    /**
     * @dev Limit access to the approved operator.
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator");
        _;
    }

    /**
     * @dev Sets the approved operator.
     * @param _operator The address of the operator.
     */
    function setOperator(address _operator) public onlyAdmin {
        operator = payable(_operator);
    }
}
