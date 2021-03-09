//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpenZeppelin/access/Ownable.sol";
import "./OpenZeppelin/token/ERC721/ERC721.sol";
import "./OpenZeppelin/token/ERC721/ERC721Holder.sol";

import "./ERC721TokenVault.sol";

contract VaultFactory is Ownable {
  /// @notice the number of ERC721 vaults
  uint256 public vaultCount;

  /// @notice the mapping of vault number to vault contract
  mapping(uint256 => TokenVault) public vaults;

  /// @notice a settings contract controlled by governance
  address public settings;

  event Mint(address token, uint256 id, uint256 price);

  constructor(address _settings) {
    settings = _settings;
  }

  /// @notice the function to mint a new vault
  /// @param _name the desired name of the vault
  /// @param _symbol the desired sumbol of the vault
  /// @param _token the ERC721 token address fo the NFT
  /// @param _id the uint256 ID of the token
  /// @param _listPrice the initial price of the NFT
  /// @return the ID of the vault
  function mint(string memory _name, string memory _symbol, address _token, uint256 _id, uint256 _supply, uint256 _listPrice, uint256 _fee) external returns(uint256){
    TokenVault vault = new TokenVault(settings, msg.sender, _token, _id, _supply, _listPrice, _fee, _name, _symbol);

    IERC721(_token).safeTransferFrom(msg.sender, address(vault), _id);
    
    vaults[vaultCount] = vault;
    vaultCount++;

    return vaultCount - 1;
  }

}
