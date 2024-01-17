pragma solidity ^0.8.0;

import {IOFTV2} from "solidity-examples/token/oft/v2/interfaces/IOFTV2.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

interface IDcntEth is IOFTV2, IERC20 {

    function setRouter(address _router) external;

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function mintByOwner(address _to, uint256 _amount) external;

    function burnByOwner(address _from, uint256 _amount) external;
}
