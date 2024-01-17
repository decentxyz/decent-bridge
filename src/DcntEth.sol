// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {OFTV2} from "solidity-examples/token/oft/v2/OFTV2.sol";

contract DcntEth is OFTV2 {
    address public router;

    modifier onlyRouter() {
        require(msg.sender == router);
        _;
    }

    constructor(
        address _layerZeroEndpoint
    ) OFTV2("Decent Eth", "DcntEth", 18, _layerZeroEndpoint) {}

    /**
     * @param _router the decentEthRouter associated with this eth
     */
    function setRouter(address _router) public {
        router = _router;
    }

    function mint(address _to, uint256 _amount) public onlyRouter {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyRouter {
        _burn(_from, _amount);
    }

    function mintByOwner(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burnByOwner(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }
}
