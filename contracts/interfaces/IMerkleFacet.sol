// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IMerkleFacet {
    function claim(uint256 amount, bytes32[] calldata merkleProof) external;

    function updateMerkleRoot(bytes32 newRoot) external;
}
