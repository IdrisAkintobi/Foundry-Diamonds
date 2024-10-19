// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC721Facet {
    function mint(address to) external;

    function mintMany(address to, uint256 amount) external;

    function burn(uint256 id) external;
}
