// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {OFTV2} from "solidity-examples/token/oft/v2/OFTV2.sol";

contract DcntEth is OFTV2 {
    constructor(
        address _layerZeroEndpoint
    ) OFTV2("Decent Eth", "DcntEth", 18, _layerZeroEndpoint) {}

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }




}
