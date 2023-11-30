// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";
import {BetterDeployer} from "../../common/BetterDeployer.sol";
import {Carrot} from "../../common/Veggies.sol";

contract BetterDeployerTest is Test, Carrot {
    function testBetterDeployer() public {
        BetterDeployer deployer = new BetterDeployer("deployments", "");
        Carrot carrot = Carrot(
            deployer.deploy("mycarrot", "Veggies.sol:Carrot", "")
        );
        Carrot anotherCarrot = Carrot(
            deployer.deploy("theircarrot", "Veggies.sol:Carrot", "")
        );
        deployer.dump();
    }
}
