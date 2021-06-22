//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpenZeppelin/access/Ownable.sol";
import "./OpenZeppelin/utils/Pausable.sol";

import "./OpenZeppelin/token/ERC721/ERC721.sol";
import "./OpenZeppelin/token/ERC721/ERC721Holder.sol";

import "./Settings.sol";
import "./ERC721TokenVault.sol";

contract ERC721VaultFactory is Ownable, Pausable {
  /// @notice the number of ERC721 vaults
  uint256 public vaultCount;

  /// @notice the mapping of vault number to vault contract
  mapping(uint256 => TokenVault) public vaults;

  /// @notice a settings contract controlled by governance
  address public settings;

  /// @notice mapping of allowed tick spacings
  mapping(uint256=>bool) public tickSpacings;

  /// @notice mapping of allowed curator fees (100 = 10%)
  mapping(uint256=>bool) public fees;

  event Mint(address indexed token, uint256 id, address vault, uint256 vaultId);

  constructor(address _settings) {
    settings = _settings;
    tickSpacings[0.1 ether] = true;
    tickSpacings[1 ether] = true;
    tickSpacings[10 ether] = true;

    fees[0] = true;
    fees[25] = true;
    fees[50] = true;
    fees[75] = true;
    fees[100] = true;
  }

  /// @notice the function to mint a new vault
  /// @param _name the desired name of the vault
  /// @param _symbol the desired sumbol of the vault
  /// @param _token the ERC721 token address fo the NFT
  /// @param _id the uint256 ID of the token
  /// @param _supply the total supply of the vault
  /// @param _tickSpacing the size in ETH of the spaces between price options
  /// @param _tickIndexMedian the desired middle possible price of the vault at creation
  /// @param _fee the curator fee for the vault
  /// @return the ID of the vault
  function mint(string memory _name, string memory _symbol, address _token, uint256 _id, uint256 _supply, uint256 _tickSpacing, uint256 _tickIndexMedian, uint256 _fee) external whenNotPaused returns(uint256) {
    require(tickSpacings[_tickSpacing], "bad spacing");
    require(fees[_fee], "bad fee");

    TokenVault vault = new TokenVault(settings, msg.sender, _token, _id, _supply, _tickSpacing, _tickIndexMedian, _fee, _name, _symbol);

    emit Mint(_token, _id, address(vault), vaultCount);

    IERC721(_token).safeTransferFrom(msg.sender, address(vault), _id);
    
    vaults[vaultCount] = vault;
    vaultCount++;

    return vaultCount - 1;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function addSpacing(uint256 _spacing) external onlyOwner {
    tickSpacings[_spacing] = true;
  }

  function addFee(uint256 _fee) external onlyOwner {
    require(_fee < 1000, "max fee");
    fees[_fee] = true;
  }

}
