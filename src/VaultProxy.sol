//SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./VaultStorage.sol";
import "./OpenZeppelin/token/ERC721/ERC721Holder.sol";

interface IVaultFactory {
    function logic() external returns (address);
    function settings() external returns (address);

    function tokenParams()
        external
        returns (
            string memory name,
            string memory symbol,
            uint256 supply
        );

    function vaultParams()
        external
        returns (
            address curator,
            address token,
            uint256 id,
            uint256 price,
            uint256 fee
        );
}

contract VaultProxy is VaultStorage, ERC721Holder {
    // we need to be a bit fancy here due to stack too deep errors
    constructor() {
        {
            logic = IVaultFactory(msg.sender).logic();
            settings = IVaultFactory(msg.sender).settings();
        }

        {
            (
                name, 
                symbol, 
                totalSupply
            ) = IVaultFactory(msg.sender).tokenParams();
        }
        
        uint256 _price;
        {
            (
                curator,
                token,
                id,
                _price,
                fee
            ) = IVaultFactory(msg.sender).vaultParams();
        }

        {
            // Initialize mutable storage.
            auctionLength = 7 days;
            auctionState = State.inactive;
            lastClaimed = block.timestamp;
            votingTokens = _price == 0 ? 0 : totalSupply;
            reserveTotal = _price * totalSupply;
            userPrices[curator] = _price;
            balanceOf[curator] = totalSupply;
        }
    }

    fallback() external payable {
        address _impl = logic;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }

    receive() external payable {}
}