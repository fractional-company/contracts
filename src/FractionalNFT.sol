//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpenZeppelin/utils/Address.sol";
import "./OpenZeppelin/token/ERC20/IERC20.sol";
import "./OpenZeppelin/introspection/ERC165.sol";
import "./OpenZeppelin/token/ERC1155/IERC1155.sol";
import "./OpenZeppelin/token/ERC1155/IERC1155Receiver.sol";
import "./OpenZeppelin/upgradeable/proxy/utils/Initializable.sol";

// Fractional NFT tokens that trade as both ERC20 and ERC1155 tokens
contract FractionalNFT is IERC20, IERC1155, ERC165, Initializable {
    using Address for address;

    string public name;
    string public symbol;
    uint8 constant public decimals = 18;

    address owner;

    // ERC20 storage
    uint256 internal supply;
    mapping (address => uint256) internal balance;
    mapping (address => mapping (address => uint256)) public override allowance;

    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        name = name_;
        symbol = symbol_;
    }

    function totalSupply() public override view returns(uint256) {
        return supply;
    }

    function balanceOf(address user) public override view returns(uint256) {
        return balance[user];
    }

    function balanceOf(address user, uint256 id) public override view returns(uint256) {
        return id == 0 ? balance[user] : 0;
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) external override view returns(uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function setApprovalForAll(address spender, bool approved) external override {
        if (approved) {
            allowance[msg.sender][spender] = type(uint256).max;
        } else {
            allowance[msg.sender][spender] = 0;
        }
    }

    function isApprovedForAll(address account, address operator) external override view returns (bool) {
        return allowance[account][operator] == type(uint256).max;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        require(to != address(0), "ERC20: sending address 0");
        _beforeTokenTransfer(msg.sender, to, amount);
        balance[msg.sender] -= amount;
        balance[to] += amount;
        emit Transfer(msg.sender, to, amount);
        emit TransferSingle(msg.sender, msg.sender, to, 0, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "ERC20: sending address 0");
        _beforeTokenTransfer(from, to, amount);
        if (from != msg.sender && allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }
        balance[from] -= amount;
        balance[to] += amount;
        emit Transfer(from, to, amount);
        emit TransferSingle(msg.sender, from, to, 0, amount);
        return true;
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external override {
        require(id == 0);
        transferFrom(from, to, amount);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external override {
        require(ids.length == 1, "ERC1155: only 1 valid id");
        require(ids[0] == 0, "ERC1155 only 0 valid id");
        require(amounts.length == ids.length, "ERC1155: amounts and ids length mismatch");

        transferFrom(from, to, amounts[0]);
    }

    function _mint(address to, uint256 amount) internal returns (bool) {
        _beforeTokenTransfer(address(0), to, amount);
        balance[to] += amount;
        supply += amount;
        emit Transfer(address(0), to, amount);
        emit TransferSingle(msg.sender, address(0), to, 0, amount);
        return true;
    }

    function _burn(address from, uint256 amount) internal {
        _beforeTokenTransfer(from, address(0), amount);
        balance[from] -= amount;
        supply -= amount;
        emit Transfer(from, address(0), amount);
        emit TransferSingle(msg.sender, from, address(0), 0, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}