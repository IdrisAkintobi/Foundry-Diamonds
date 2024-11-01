// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.27;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IERC721 } from "../interfaces/IERC721.sol";
import { IERC165 } from "../interfaces/IERC165.sol";
import { ERC721Utils } from "../Utils/ERC721Utils.sol";
import { IERC721Receiver } from "../interfaces/IERC721Receiver.sol";

abstract contract ERC721 is IERC721 {
    error ERC721InvalidOperator(address operator);
    error ERC721InvalidSender(address sender);
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);
    error ERC721InsufficientApproval(address operator, uint256 tokenId);
    error ERC721InvalidApprover(address approver);
    error ERC721InvalidOwner(address owner);
    error ERC721NonexistentToken(uint256 tokenId);
    error ERC721UnsafeRecipient(address recipient);
    error ERC721TokenAlreadyMinted(uint256 tokenId);

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function ownerOf(uint256 id) external view returns (address owner) {
        LibDiamond.TokenStorage storage ts = LibDiamond.tokenStorage();
        owner = ts.tokenOwner[id];
        require(owner != address(0), ERC721NonexistentToken(id));
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), ERC721InvalidOwner(owner));
        LibDiamond.TokenStorage storage ts = LibDiamond.tokenStorage();
        return ts.tokenBalance[owner];
    }

    function setApprovalForAll(address operator, bool approved) external {
        LibDiamond.TokenStorage storage ts = LibDiamond.tokenStorage();
        ts.operatorApproval[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        LibDiamond.TokenStorage storage ts = LibDiamond.tokenStorage();
        return ts.operatorApproval[owner][operator];
    }

    function approve(address spender, uint256 id) external {
        LibDiamond.TokenStorage storage ts = LibDiamond.tokenStorage();
        address owner = ts.tokenOwner[id];
        require(msg.sender == owner || ts.operatorApproval[owner][msg.sender], ERC721InvalidApprover(spender));

        ts.tokenApproval[id] = spender;

        emit Approval(owner, spender, id);
    }

    function getApproved(uint256 id) external view returns (address) {
        LibDiamond.TokenStorage storage ts = LibDiamond.tokenStorage();
        require(ts.tokenOwner[id] != address(0), ERC721NonexistentToken(id));
        return ts.tokenApproval[id];
    }

    function _isApprovedOrOwner(address owner, address spender, uint256 id) internal view returns (bool) {
        LibDiamond.TokenStorage storage ts = LibDiamond.tokenStorage();
        return (spender == owner || ts.operatorApproval[owner][spender] || spender == ts.tokenApproval[id]);
    }

    function transferFrom(address from, address to, uint256 id) public {
        LibDiamond.TokenStorage storage ts = LibDiamond.tokenStorage();
        require(from == ts.tokenOwner[id], ERC721IncorrectOwner(msg.sender, id, from));
        require(to != address(0), LibDiamond.NoZeroAddress());

        require(_isApprovedOrOwner(from, msg.sender, id), ERC721InsufficientApproval(msg.sender, id));

        ts.tokenBalance[from]--;
        ts.tokenBalance[to]++;
        ts.tokenOwner[id] = to;

        delete ts.tokenApproval[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) external {
        transferFrom(from, to, id);

        require(
            to.code.length == 0
                || IERC721Receiver(to).onERC721Received(msg.sender, from, id, "")
                    == IERC721Receiver.onERC721Received.selector,
            ERC721UnsafeRecipient(to)
        );
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external {
        transferFrom(from, to, id);

        require(
            to.code.length == 0
                || IERC721Receiver(to).onERC721Received(msg.sender, from, id, data)
                    == IERC721Receiver.onERC721Received.selector,
            ERC721UnsafeRecipient(to)
        );
    }

    function _mint(address to, uint256 id) internal {
        require(to != address(0), LibDiamond.NoZeroAddress());
        LibDiamond.TokenStorage storage ts = LibDiamond.tokenStorage();
        require(ts.tokenOwner[id] == address(0), ERC721TokenAlreadyMinted(id));

        ts.tokenBalance[to]++;
        ts.tokenOwner[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal {
        LibDiamond.TokenStorage storage ts = LibDiamond.tokenStorage();
        address owner = ts.tokenOwner[id];
        require(owner != address(0), ERC721NonexistentToken(id));

        ts.tokenBalance[owner] -= 1;

        delete ts.tokenOwner[id];
        delete ts.tokenApproval[id];

        emit Transfer(owner, address(0), id);
    }
}
