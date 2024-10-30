// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { Script } from "forge-std/Script.sol";
import "solidity-stringutils/strings.sol";

abstract contract DiamondUtils is Script {
    using strings for *;

    function getMerkleTreeRoot() internal returns (bytes32 root) {
        string[] memory inputs = new string[](4);
        inputs[0] = "bun";
        inputs[1] = "run";
        inputs[2] = "./script/helpers/merkle-script.ts";
        inputs[3] = "getMerkleTreeRoot";

        bytes memory res = vm.ffi(inputs);

        require(res.length == 32, "merkle root must be bytes32");

        assembly {
            root := mload(add(res, 32))
        }
    }

    function getMerkleTreeProof(string memory _address, string memory amount) internal returns (bytes memory proof) {
        string[] memory inputs = new string[](6);
        inputs[0] = "bun";
        inputs[1] = "run";
        inputs[2] = "./script/helpers/merkle-script.ts";
        inputs[3] = "generateMerkleProof";
        inputs[4] = _address;
        inputs[5] = amount;

        bytes memory res = vm.ffi(inputs);
        proof = res;
    }

    function bytesToBytes32Array(bytes memory data) public pure returns (bytes32[] memory) {
        require(data.length % 32 == 0, "Input length must be a multiple of 32 bytes");

        uint256 totalSegments = data.length / 32; // Number of bytes32 segments
        bytes32[] memory result = new bytes32[](totalSegments);

        for (uint256 i = 0; i < totalSegments; i++) {
            bytes32 segment;
            assembly {
                // Load the data segment into the `segment` variable
                segment := mload(add(data, add(32, mul(i, 32))))
            }
            result[i] = segment;
        }

        return result;
    }

    function generateSelectors(string memory _facetName) internal returns (bytes4[] memory selectors) {
        //get string of contract methods
        string[] memory cmd = new string[](4);
        cmd[0] = "forge";
        cmd[1] = "inspect";
        cmd[2] = _facetName;
        cmd[3] = "methods";
        bytes memory res = vm.ffi(cmd);
        string memory st = string(res);

        // extract function signatures and take first 4 bytes of keccak
        strings.slice memory s = st.toSlice();

        // Skip TRACE lines if any
        strings.slice memory nl = "\n".toSlice();
        strings.slice memory trace = "TRACE".toSlice();
        while (s.contains(trace)) {
            s.split(nl);
        }

        strings.slice memory colon = ":".toSlice();
        strings.slice memory comma = ",".toSlice();
        strings.slice memory dbquote = '"'.toSlice();
        selectors = new bytes4[]((s.count(colon)));

        for (uint256 i = 0; i < selectors.length; i++) {
            s.split(dbquote); // advance to next doublequote
            // split at colon, extract string up to next doublequote for methodname
            strings.slice memory method = s.split(colon).until(dbquote);
            selectors[i] = bytes4(method.keccak());
            s.split(comma).until(dbquote); // advance s to the next comma
        }
        return selectors;
    }
}
