// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OpenZeppelin/token/ERC721/IERC721.sol";
import "./OpenZeppelin/token/ERC721/IERC721Metadata.sol";
import "./OpenZeppelin/token/ERC721/IERC721Receiver.sol";
import "./OpenZeppelin/introspection/ERC165.sol";
import "./OpenZeppelin/utils/Strings.sol";

contract FNFT is ERC165, IERC721, IERC721Metadata {
    using Strings for uint256;

    mapping(address => bool) private _ownerMinted;

    string public override name;
    string public override symbol;
    address public immutable vault;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI = "https://uri.fractional.art/";

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        vault = msg.sender;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
    }

    modifier onlyVault() {
        require(msg.sender == vault);
        _;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _ownerMinted[owner] ? 1 : 0;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return uint256ToAddress(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = baseURI();

        return string(abi.encodePacked(base, addressToUint256(address(this)).toString(), "/", tokenId.toString()));
    }

    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /// unsupported functions

    function approve(address to, uint256 tokenId) public virtual override {
        require(true == false);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        return address(0);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(true == false);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return false;
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(true == false);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(true == false);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(true == false);
    }

    /// supported functions

    function mint(address to) external onlyVault {
        _mint(to);
    }

    function burn(address from) external onlyVault {
        _burn(from);
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerMinted[uint256ToAddress(tokenId)];
    }

    function _mint(address to) internal virtual {
        _ownerMinted[to] = true;
        emit Transfer(address(0), to, addressToUint256(to));
    }

    function _burn(address from) internal virtual {
        _ownerMinted[from] = false;
        emit Transfer(from, address(0), addressToUint256(from));
    }

    function addressToUint256(address x) public pure returns(uint256) {
        return uint256(uint160(address(x)));
    }
    
    function uint256ToAddress(uint256 x) public pure returns(address) {
        return address(uint160(x));
    }
}
