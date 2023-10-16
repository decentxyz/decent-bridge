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
    DcntEth dcntEth;
    DecentEthRouter router = new DecentEthRouter(payable(address(weth)));

    function setUp() public {
        console2.log("deployed WETH contract ", address(weth));
        console2.log("lzEndpoint", lzEndpoint);
        router.deployDcntEth(lzEndpoint);
        dcntEth = router.dcntEth();
        console2.log("deployed decentETH contract", address(router.dcntEth()));
    }

    function testShouldBeAbletoDepositWeth() public {
        router.addLiquidityEth{value: 10}();
        assertEq(weth.balanceOf(address(router)), 10);
        assertEq(dcntEth.balanceOf(address(router)), 10);

        router.removeLiquidityEth(5);
        assertEq(weth.balanceOf(address(router)), 5);
        assertEq(dcntEth.balanceOf(address(router)), 5);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
