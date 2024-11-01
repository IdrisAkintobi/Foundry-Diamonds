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
import { Script, console } from "forge-std/Script.sol";

contract DiamondDeployerScript is DiamondUtils {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    ERC721Facet erc721F;
    MerkleFacet mklr;

    bytes32 merkleRoot;
    address owner;

    function setUp() public {
        merkleRoot = getMerkleTreeRoot();
        owner = vm.envAddress("INITIAL_OWNER");
    }

    function run() public {
        // Start the broadcast
        vm.startBroadcast();
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(dCutFacet), "Diamond NFT", "DNFT", merkleRoot);
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        erc721F = new ERC721Facet();
        mklr = new MerkleFacet();

        //upgrade diamond with facets
        //build cut struct
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](4);

        cut[0] = (
            IDiamondCut.FacetCut({
                facetAddress: address(dLoupe),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            IDiamondCut.FacetCut({
                facetAddress: address(ownerF),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            IDiamondCut.FacetCut({
                facetAddress: address(erc721F),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: generateSelectors("ERC721Facet")
            })
        );

        cut[3] = (
            IDiamondCut.FacetCut({
                facetAddress: address(mklr),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: generateSelectors("MerkleFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        // Stop broadcasting
        vm.stopBroadcast();

        console.log("Diamond deployed to:", address(diamond));
    }
}
