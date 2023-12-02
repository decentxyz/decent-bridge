// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";
import {BetterDeployer} from "../../common/BetterDeployer.sol";
import {Carrot} from "../../common/Veggies.sol";

contract BetterDeployerTest is Test, Carrot {
    function testBetterDeployerMustDumpDeploymentsCorrectly() public {
        string memory deployFolder = "deployments";
        string memory deployFile = "myDeployments.json";

        BetterDeployer deployer1 = new BetterDeployer(deployFolder, deployFile);
        Carrot carrot = Carrot(
            deployer1.deploy("mycarrot", "Veggies.sol:Carrot", "")
        );
        Carrot anotherCarrot = Carrot(
            deployer1.deploy("theircarrot", "Veggies.sol:Carrot", "")
        );
        deployer1.dump();
        assertTrue(vm.isFile(deployer1.deployFilePath()));
        BetterDeployer deployer2 = new BetterDeployer(deployFolder, deployFile);

        address carrot1 = deployer2.get("mycarrot");
        assertEq(carrot1, address(carrot));

        address nonexistent = deployer2.get("mycarrot1");
    }
}
