// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/Counter.sol";
import {CommonBase} from "forge-std/Base.sol";
import {DecentEthRouter} from "src/DecentEthRouter.sol";

//https://layerzero.gitbook.io/docs/technical-reference/testnet/testnet-addresses

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

contract DeployRouter is Script {
    mapping(string => address) wethLookup;

    constructor() {
    }

    function setUp() public {}

    function run() public {
        string memory ftm = vm.rpcUrl("ftm-testnet");
        string memory fuji = vm.rpcUrl("fuji");
        uint16 FTM_LZ_ID = 10112;
        uint16 FUJI_LZ_ID = 10106;
        TestConfig testConfig = new TestConfig();
        console2.log("ftm", ftm, "fuji", fuji);

        // deploy router ftm
        vm.createSelectFork(vm.rpcUrl("ftm-testnet"));
        vm.startBroadcast();

        address ftmWeth = 0x07b9c47452c41e8e00f98ac4c075f5c443281d2a;
        DecentEthRouter ftmRouter = new DecentEthRouter(ftmWeth);
        address ftmLz = testConfig.readLzEndpoint("fantom-testnet");
        ftmRouter.deployDcntEth(ftmLz);

        vm.stopBroadcast();

        // deploy router fuji
        vm.createSelectFork(vm.rpcUrl("fuji"));
        vm.startBroadcast();

        address fujiWeth = 0x1d308089a2d1ced3f1ce36b1fcaf815b07217be3;
        DecentEthRouter fujiRouter = new DecentEthRouter(fujiWeth);
        address fujiLz = testConfig.readLzEndpoint("fuji");
        fujiRouter.deployDcntEth(fujiLz);

        // broadcast
        fujiRouter.addDestinationBridge(FTM_LZ_ID, address(ftmRouter));
        vm.stopBroadcast();

        vm.createSelectFork(vm.rpcUrl("ftm-testnet"));
        vm.startBroadcast();
        ftmRouter.addDestinationBridge(FUJI_LZ_ID, address(fujiRouter));
        vm.stopBroadcast();

        ////address weth = address(0x07B9c47452C41e8E00f98aC4c075F5c443281d2A);
        //Chain memory c = getChain(4002);
        //console2.log("chain", c.name);
        //console2.log("alias", c.chainAlias);
        //console2.log("id", c.chainId);
        //DecentEthRouter router = new DecentEthRouter(payable(weth));
    }
}
