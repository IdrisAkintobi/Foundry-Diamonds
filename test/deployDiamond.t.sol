// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { IDiamondCut } from "../contracts/interfaces/IDiamondCut.sol";
import { DiamondCutFacet } from "../contracts/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "../contracts/facets/DiamondLoupeFacet.sol";
import { OwnershipFacet } from "../contracts/facets/OwnershipFacet.sol";
import { ERC721Facet } from "../contracts/facets/ERC721Facet.sol";
import { Diamond } from "../contracts/Diamond.sol";
import { MerkleFacet } from "../contracts/facets/MerkleFacet.sol";
import { DiamondUtils } from "../script/helpers/DiamondUtils.sol";
import { Test, console } from "forge-std/Test.sol";

contract DiamondDeployer is DiamondUtils, IDiamondCut, Test {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    ERC721Facet erc721F;
    MerkleFacet mklr;

    bytes32 merkleRoot;

    function setUp() public {
        merkleRoot = getMerkleTreeRoot();

        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet), "Diamond NFT", "DNFT", merkleRoot);
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        erc721F = new ERC721Facet();
        mklr = new MerkleFacet();

        //upgrade diamond with facets
        //build cut struct
        FacetCut[] memory cut = new FacetCut[](4);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(erc721F),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("ERC721Facet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(mklr),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("MerkleFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");
    }

    function test_DeployDiamond() public view {
        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    function test_MerkleRootGeneration() public {
        bytes32 root = getMerkleTreeRoot();
        assertTrue(root.length == 32, "Root byte32");
    }

    function test_MerkleRootUpdate() public {
        bytes32 newRoot = getMerkleTreeRoot();
        bytes memory _calldata = abi.encodeWithSelector(0x4783f0ef, newRoot);
        (bool success,) = (address(diamond)).call(_calldata);
        assertTrue(success);
    }

    function test_AirdropClaim() public {
        address claimant = 0x440Bcc7a1CF465EAFaBaE301D1D7739cbFe09dDA;
        uint8 amount = 1;
        bytes memory merkleProof = getMerkleTreeProof("0x440Bcc7a1CF465EAFaBaE301D1D7739cbFe09dDA", "1");
        vm.prank(claimant);
        bytes32[] memory proofBytes = bytesToBytes32Array(merkleProof);
        bytes memory _calldata = abi.encodeWithSelector(MerkleFacet.claim.selector, amount, proofBytes);
        (bool success,) = (address(diamond)).call(_calldata);
        assertTrue(success);
    }

    function test_MultipleAirdropClaim() public {
        address claimant = 0x020cA66C30beC2c4Fe3861a94E4DB4A498A35872;
        uint8 amount = 3;
        bytes memory merkleProof = getMerkleTreeProof("0x020cA66C30beC2c4Fe3861a94E4DB4A498A35872", "3");
        vm.prank(claimant);
        bytes32[] memory proofBytes = bytesToBytes32Array(merkleProof);
        bytes memory _calldata = abi.encodeWithSelector(MerkleFacet.claim.selector, amount, proofBytes);
        (bool success,) = (address(diamond)).call(_calldata);
        assertTrue(success);
    }

    function testFail_AirdropClaim() public {
        address claimant = 0x020cA66C30beC2c4Fe3861a94E4DB4A498A35872;
        uint8 amount = 9;
        bytes memory merkleProof = getMerkleTreeProof("0x020cA66C30beC2c4Fe3861a94E4DB4A498A35872", "9");
        vm.prank(claimant);
        bytes32[] memory proofBytes = bytesToBytes32Array(merkleProof);
        bytes memory _calldata = abi.encodeWithSelector(MerkleFacet.claim.selector, amount, proofBytes);
        (bool success,) = (address(diamond)).call(_calldata);
        assertTrue(success);
    }

    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override { }
}
