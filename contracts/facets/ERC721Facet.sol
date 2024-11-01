// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { ERC721 } from "../tokens/ERC721.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IERC721Facet } from "../interfaces/IERC721Facet.sol";

contract ERC721Facet is ERC721, IERC721Facet {
    function mint(address to) external {
        LibDiamond.TokenStorage storage ts = LibDiamond.tokenStorage();
        uint256 id = ts.tokenCounter++;
        _mint(to, id);
    }

    function mintMany(address to, uint256 amount) external {
        LibDiamond.TokenStorage storage ts = LibDiamond.tokenStorage();

        for (uint256 i = 0; i < amount; i++) {
            uint256 id = ts.tokenCounter++;
            _mint(to, id);
        }
    }

    function burn(uint256 id) external {
        LibDiamond.TokenStorage storage ts = LibDiamond.tokenStorage();
        require(msg.sender == ts.tokenOwner[id], ERC721InvalidOwner(msg.sender));
        _burn(id);
    }
}
