// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {AllChainsInfo} from "../../test/common/AllChainsInfo.sol";
import {MultichainDeployer} from "../../test/common/MultichainDeployer.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract MintToken is Script, AllChainsInfo, MultichainDeployer {
    address whale;
    address to;
    ERC20 token;
    uint amount;
    string chain;

    function setUp() public {
        setRuntime(ENV_FORK);
        setupChainInfo();
        //whale = vm.envAddress("whale");
        //to = vm.envAddress("to");
        //amount = vm.envUint("AMOUNT");
        //token = ERC20(vm.envAddress("token"));
        //chain = vm.envString("chain");
        chain = "optimism";
        whale = payable(address(0xBDa75CbB9ab7d952bae0fBaF5be0985f9d96dba0));
        token = ERC20(address(0x47029bc8f5CBe3b464004E87eF9c9419a48018cd));
        to = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    }

    function run() public {
        switchTo(chain);
        dealTo(chain, whale, 0.01 ether);
        startImpersonating(whale);
        uint balance = token.balanceOf(whale);
        uint half = balance >> 1;
        token.transfer(to, half);
        stopImpersonating();
    }

    //// Function to receive Ether. msg.data must be empty
    //receive() external payable {}

    //// Fallback function is called when msg.data is not empty
    //fallback() external payable {}
}
