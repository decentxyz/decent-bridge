// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console, console2} from "forge-std/Test.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {OFTV2} from "solidity-examples/token/oft/v2/OFTV2.sol";
import {WETH} from "solmate/tokens/WETH.sol";

struct EndpointAddresses {
    address ethereum;
    address bsc;
    address avalanche;
    address polygon;
    address arbitrum;
    address optimism;
    address fantom;
    address goerli;
    address bscTestnet;
    address fuji;
    address mumbai;
    address arbitrumGoerli;
    address optimismGoerli;
    address fantomTestnet;
    address meterTestnet;
    address zksyncTestnet;
}

contract JSONReader is CommonBase {
    function readJson(string memory filepath) public returns (bytes memory content) {
        string memory fileContent = vm.readFile(filepath);
        return vm.parseJson(fileContent);
    }
}

contract TestConfig is CommonBase {
    JSONReader jsonReader = new JSONReader();

    function readLzEndpoint() public returns (string memory endpoint) {
        bytes memory content = jsonReader.readJson(
            "./constants/layezeroEndpoints.json"
        );
        EndpointAddresses memory jsonAsConfigFile = abi.decode(
            content,
            (EndpointAddresses)
        );
        return jsonAsConfigFile.ethereum;
    }
}

contract DecentEthRouterTest is Test {
    WETH weth;
    address lzEndpiont = address(0);

    constructor() {
        weth = new WETH();
        console2.log("deployed WETH contract ", address(weth));
        //const endpointAddr = LZ_ENDPOINTS[hre.network.name]
    }

    function testIncrement() public {
        console2.log("hi", address(weth));
    }
}
