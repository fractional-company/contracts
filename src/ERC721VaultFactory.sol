//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpenZeppelin/utils/Strings.sol";
import "./OpenZeppelin/token/ERC721/ERC721.sol";
import "./OpenZeppelin/token/ERC721/ERC721Holder.sol";

import "./ERC721TokenVault.sol";

contract VaultFactory {
  using Strings for *;

  uint256 public vaultCount;
  mapping(uint256 => TokenVault) public vaults;

  address payable public gov;
  address payable public pendingGov;
  uint256 public fee;

  event Mint(address token, uint256 id, uint256 price);
  event UpdateGov(address oldGov, address newGov);
  event AcceptGov(address gov);

  constructor() {
    gov = payable(msg.sender);
  }

  function mint(address _token, uint256 _id, uint256 _reservePrice) external {
    string memory name = IERC721Metadata(_token).name();
    string memory id = _id.toString();
    name = string(abi.encodePacked("Nibble - ", name, ":",  id));
    TokenVault vault = new TokenVault(address(this), fee, _token, _id, msg.sender, _reservePrice, name, "NBBL");

    IERC721(_token).safeTransferFrom(msg.sender, address(vault), _id);
    
    vaults[vaultCount] = vault;
    vaultCount++;
  }

  function updateGov(address payable _gov) external {
    require(msg.sender == gov, "update:not gov");
    pendingGov = _gov;

    emit UpdateGov(gov, pendingGov);
  }

  function acceptGov() external {
    require(msg.sender == pendingGov, "accept:not new gov");
    gov = pendingGov;
    pendingGov = payable(address(0));

    emit AcceptGov(gov);
  }

  function setFee(uint256 _fee) external {
    // Max gov fee is 10%
    require(_fee <= 100, "fee:fee is too high");
    require(msg.sender == gov, "fee:not gov");
    fee = _fee;
  }

}
