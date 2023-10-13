// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console, console2} from "forge-std/Test.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {OFTV2} from "solidity-examples/token/oft/v2/OFTV2.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";
import {DcntEth} from "src/DcntEth.sol";

contract TestConfig is CommonBase {
    function readLzEndpoint(
        string memory key
    ) public view returns (address endpoint) {
        string memory filePath = "./constants/layerzeroEndpoints.json";
        string memory fileContent = vm.readFile(filePath);
        string memory addressStr = vm.parseJsonString(
            fileContent,
            string.concat(".", key)
        );
        return address(bytes20(bytes(addressStr)));
    }
}

contract DecentEthRouterTest is Test {
    WETH weth = new WETH();
    TestConfig testConfig = new TestConfig();
    address lzEndpoint = testConfig.readLzEndpoint("avalanche");
    DcntEth dcntEth = new DcntEth(lzEndpoint);
    DecentEthRouter router = new DecentEthRouter(payable(address(weth)));

    function setUp() public {
        console2.log("deployed WETH contract ", address(weth));
        console2.log("lzEndpoint", lzEndpoint);
        router.deployDcntEth(lzEndpoint);
        console2.log("deployed decentETH contract", address(router.dcntEth()));
        //address endpointAddr = LZ_ENDPOINTS[hre.network.name]
    }

    function testIncrement() public view {
        //console2.log("hi", address(weth));
        //string memory value = vm.parseJsonString("{\"arshan\":\"hello\"}", ".arshan");
        //console2.log("value", value);
    }
}
