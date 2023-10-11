// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "solidity-examples/token/oft/v2/OFTV2.sol";

contract DcntETH is OFTV2 {
    constructor(
        address _lzEndpoint
    ) OFTV2("Decent Wrapped ETH", "DcntETH", 18, _lzEndpoint) {}

    function mint(address _to, uint _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}

struct ConfigFile {
    string arshan;
}

contract OFTSample is Test {
    DcntETH oft;
    address lzEndpiont = address(0);

    constructor() {
        console2.log("deploying new OFT contract");
        oft = new DcntETH(address(0));
        console2.log("deployed new contract at", address(oft));
        oft.mint(address(this), 1 ether);
    }

    function testIncrement() public {
        console.log("oft address", address(oft));
        console.log("oft circulating supply", oft.circulatingSupply());

        string memory fileContent = vm.readFile("./test/hello.json");
        console.log("content of file", fileContent);
        bytes memory theJson = vm.parseJson(fileContent);
        ConfigFile memory jsonAsConfigFile = abi.decode(theJson, (ConfigFile));
        console.log("bytes of json", jsonAsConfigFile.arshan);
    }
}
