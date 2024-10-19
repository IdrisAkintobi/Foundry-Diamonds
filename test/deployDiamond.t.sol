// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { IDiamondCut } from "../contracts/interfaces/IDiamondCut.sol";
import { DiamondCutFacet } from "../contracts/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "../contracts/facets/DiamondLoupeFacet.sol";
import { OwnershipFacet } from "../contracts/facets/OwnershipFacet.sol";
import { ERC721Facet } from "../contracts/facets/ERC721Facet.sol";
import { Diamond } from "../contracts/Diamond.sol";
import { MerkleFacet } from "../contracts/facets/MerkleFacet.sol";
import { DiamondUtils } from "./helpers/DiamondUtils.sol";

contract DiamondDeployer is DiamondUtils, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    ERC721Facet erc721F;
    MerkleFacet mklr;

    // bytes32 merkleRoot = getMerkleTreeRoot();
    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet), "Diamond NFT", "DNFT", getMerkleTreeRoot());
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

    function testDeployDiamond() public view {
        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    function testMerkleRootGeneration() public {
        bytes32 root = getMerkleTreeRoot();
        assertTrue(root.length == 32, "Root byte32");
    }

    function testMerkleRootUpdate() public {
        bytes32 newRoot = getMerkleTreeRoot();
        bytes memory _calldata = abi.encodeWithSelector(0x4783f0ef, newRoot);
        (bool success,) = (address(diamond)).call(_calldata);
        assertTrue(success);
    }

    function testAirdropClaim() public {
        address claimant = 0x440Bcc7a1CF465EAFaBaE301D1D7739cbFe09dDA;
        uint8 amount = 1;
        bytes memory merkleProof = getMerkleTreeProof("0x440Bcc7a1CF465EAFaBaE301D1D7739cbFe09dDA", "1");
        vm.prank(claimant);
        bytes32[] memory proofBytes = bytesToBytes32Array(merkleProof);
        bytes memory _calldata = abi.encodeWithSelector(MerkleFacet.claim.selector, amount, proofBytes);
        (bool success,) = (address(diamond)).call(_calldata);
        assertTrue(success);
    }

    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override { }
}
