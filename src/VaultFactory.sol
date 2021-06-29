//SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./OpenZeppelin/token/ERC721/IERC721.sol";
import "./OpenZeppelin/access/Ownable.sol";
import "./OpenZeppelin/utils/Pausable.sol";
import "./VaultProxy.sol";
import "./VaultLogic.sol";
import "./VaultStorage.sol";

contract VaultFactory is Ownable, Pausable {

  struct TokenParameters{
    string name;
    string symbol;
    uint256 supply;
  }

  struct VaultParameters {
    address curator;
    address token;
    uint256 id;
    uint256 price;
    uint256 fee;
  }

  TokenParameters public tokenParams;
  VaultParameters public vaultParams;

  address public immutable logic;
  address public immutable settings;

  event Mint(address indexed token, uint256 id, uint256 price, address vault);

  constructor(address _logic, address _settings) {
    logic = _logic;
    settings = _settings;
  }

  /// @notice the function to mint a new vault
  /// @param _name the desired name of the vault
  /// @param _symbol the desired sumbol of the vault
  /// @param _token the ERC721 token address fo the NFT
  /// @param _id the uint256 ID of the token
  /// @param _supply the total supply of the ERC20 token
  /// @param _listPrice the initial price of the NFT
  /// @param _fee the desired curator fee for the vault
  /// @return proxy the address of the vault
  function mint(string memory _name, string memory _symbol, address _token, uint256 _id, uint256 _supply, uint256 _listPrice, uint256 _fee) external whenNotPaused returns(address proxy) {
    tokenParams = TokenParameters({
      name: _name,
      symbol: _symbol,
      supply: _supply
    });

    vaultParams = VaultParameters({
      curator: msg.sender,
      token: _token,
      id: _id,
      price: _listPrice,
      fee: _fee
    });

    proxy = address(new VaultProxy());

    delete tokenParams;
    delete vaultParams;

    IERC721(_token).safeTransferFrom(msg.sender, proxy, _id);

    emit Mint(_token, _id, _listPrice, proxy);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

}
