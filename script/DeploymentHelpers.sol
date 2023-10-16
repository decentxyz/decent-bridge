// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {CommonBase} from "forge-std/Base.sol";

contract DeploymentHelpers is CommonBase {
    function getDeployment(
        string memory filePath,
        string memory keypath
    ) public view returns (address deployment) {
        string memory fileContent = vm.readFile(filePath);
        return vm.parseJsonAddress(fileContent, keypath);
    }

    function getFromLastRun(
        string memory chainId,
        string memory keyPath
    ) public view returns (address deployment) {
        string memory basePath = "./broadcast/DeployRouter.s.sol";
        string memory filePath = string.concat(
            basePath,
            "/",
            chainId,
            "/run-latest.json"
        );
        return getDeployment(filePath, keyPath);
    }
}
