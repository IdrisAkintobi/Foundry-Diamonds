// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { console } from "forge-std/console.sol";

import { IERC721Facet } from "../interfaces/IERC721Facet.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { MerkleProof } from "../libraries/MerkleProof.sol";
import { IMerkleFacet } from "../interfaces/IMerkleFacet.sol";

contract MerkleFacet is IMerkleFacet {
    error AIRDROP_CLAIMED();
    error INVALID_PRO0F();
    error TRANSFER_FAILED();
    error UNAUTHORIZED();

    event Claimed(address indexed claimant, uint256 amount);
    event MerkleRootUpdated(bytes32 indexed oldRoot, bytes32 indexed newRoot);

    function claim(uint256 amount, bytes32[] calldata merkleProof) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        if (ds.claimed[msg.sender]) revert AIRDROP_CLAIMED();
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, amount))));
        require(MerkleProof.verifyCalldata(merkleProof, ds.merkleRoot, node), INVALID_PRO0F());

        ds.claimed[msg.sender] = true;
        address tokenAddress = ds.selectorToFacetAndPosition[IERC721Facet.mintMany.selector].facetAddress;
        IERC721Facet(tokenAddress).mintMany(msg.sender, amount);

        emit Claimed(msg.sender, amount);
    }

    function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes32 oldRoot = ds.merkleRoot;
        if (newRoot != oldRoot) {
            LibDiamond.setMerkleRoot(newRoot);
        }
        emit MerkleRootUpdated(oldRoot, newRoot);
    }

    modifier onlyOwner() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.contractOwner, UNAUTHORIZED());
        _;
    }
}
