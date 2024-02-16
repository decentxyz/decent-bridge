// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {BaseOFTV2, OFTV2} from "solidity-examples/token/oft/v2/OFTV2.sol";
import {AccessControl, Roles} from "./utils/Roles.sol";

contract DcntEth is OFTV2, Roles {
    address public router;

    modifier onlyRouter() {
        require(msg.sender == router);
        _;
    }

    constructor(
        address _layerZeroEndpoint
    ) OFTV2("Decent Eth", "DcntEth", 18, _layerZeroEndpoint) Roles(msg.sender) {}

    /**
     * @param _router the decentEthRouter associated with this eth
     */
    function setRouter(address _router) public onlyAdmin {
        router = _router;
    }

    function mint(address _to, uint256 _amount) public onlyRouter {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyRouter {
        _burn(_from, _amount);
    }

    function mintByAdmin(address _to, uint256 _amount) public onlyAdmin {
        _mint(_to, _amount);
    }

    function burnByAdmin(address _from, uint256 _amount) public onlyAdmin {
        _burn(_from, _amount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(BaseOFTV2, AccessControl) returns (bool) {
        return BaseOFTV2.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
}
