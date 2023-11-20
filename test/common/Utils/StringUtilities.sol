// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "solidity-stringutils/strings.sol";

contract StringUtilities {
    using strings for *;

    function split(
        string memory inputStr,
        string memory delimiter
    ) internal pure returns (string[] memory) {
        strings.slice memory sliced = inputStr.toSlice();
        strings.slice memory delim = delimiter.toSlice();
        uint count = inputStr.toSlice().count(delim) + 1;
        string[] memory parts = new string[](count);
        for (uint i = 0; i < count; i++) {
            parts[i] = sliced.split(delim).toString();
        }
        return parts;
    }
}
