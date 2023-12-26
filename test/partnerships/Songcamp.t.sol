// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {BaseChainSetup} from "arshans-forge-toolkit/BaseChainSetup.sol";
import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";
import {C4TEST} from "../../script/partnerships/C4TEST.sol";
import {AliceAndBobScenario} from "../common/AliceAndBobScenario.sol";
import {LoadAllChainInfo} from "arshans-forge-toolkit/LoadAllChainInfo.sol";

contract Songcamp is Test, AliceAndBobScenario {
    constructor() {}

    C4TEST nft;
    uint price;

    function setUp() public {
        nft = new C4TEST();
        nft.toggleSaleEnabled();
        console2.log("nft deployed at", address(nft));
        price = nft.mintPrice();
        setRuntime(ENV_FORGE_TEST);
        vm.deal(alice, 10 ether);
    }

    function testThis() public {
        startImpersonating(alice);
        uint numMint = 5;
        nft.multiMint{value: price * numMint}(numMint, alice);
        assertEq(nft.balanceOf(alice), numMint);
    }

    string BANNER = "\x19Ethereum Signed Message:\n32";

    function getSignature(
        uint num,
        uint256[] memory tokenIds,
        uint256[] memory songSelections,
        uint nftId,
        uint songChoiceId
    ) public returns (bytes memory, address) {
        uint256 privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address owner = vm.addr(privateKey);
        nft.safeMint{value: price * num}(owner);

        bytes32 hash = keccak256(abi.encodePacked(tokenIds, songSelections));
        console2.logBytes32(hash);

        bytes32 ethSignedHash = keccak256(abi.encodePacked(BANNER, hash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ethSignedHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        console2.logBytes(signature);
        return (signature, owner);
    }

    function skipTestTryMintCall() public {
        loadAllChainInfo();
        switchTo("zora");
        address peaceNode = 0x92Fbd2faF1E67B5A55Ce9196b4EAA3B55c23cECa;
        nft = C4TEST(0x38898cAdB5241121620A81e7BcA47eaB8a87402A);
        startImpersonating(peaceNode);
        console2.log("balance of them", peaceNode.balance);
        nft.multiMint{value: 1 ether}(100, peaceNode);
        //address(nft).call{value: 0.8 ether}(
        //    hex"526a69220000000000000000000000003547f3cf6dad2ce64b5c308ebd964822220cf5770000000000000000000000003547f3cf6dad2ce64b5c308ebd964822220cf57700000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001044aed0ae8000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        //);
    }

    function testMultiWriteToDiscSignature() public {
        uint num = 1;
        uint nftId = 1;
        uint songChoiceId = 3;
        uint256[] memory tokenIds = new uint256[](num);
        tokenIds[0] = nftId;
        uint256[] memory songSelections = new uint256[](num);
        songSelections[0] = songChoiceId; // anything between 1 to 5

        (bytes memory signature, address owner) = getSignature(
            num,
            tokenIds,
            songSelections,
            nftId,
            songChoiceId
        );

        nft.multiWriteToDiscSignature(tokenIds, songSelections, signature);

        (address writerAddress, uint256 choiceId, bool written) = nft
            .readCdMemory(nftId);
        assertEq(choiceId, songChoiceId);
        assertEq(writerAddress, address(owner));
        assertEq(written, true);
    }
}
