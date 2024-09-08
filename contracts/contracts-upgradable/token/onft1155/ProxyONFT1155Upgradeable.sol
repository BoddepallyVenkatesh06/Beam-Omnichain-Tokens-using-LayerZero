// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "./ONFT1155CoreUpgradeable.sol";

contract ProxyONFT1155Upgradeable is Initializable, ONFT1155CoreUpgradeable, IERC1155ReceiverUpgradeable, Proxied {
    using ERC165CheckerUpgradeable for address;

    IERC1155Upgradeable public token;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _lzEndpoint, address _proxyToken) public virtual initializer {
        __ProxyONFT1155Upgradeable_init(_lzEndpoint, _proxyToken);
    }

    function __ProxyONFT1155Upgradeable_init(address _lzEndpoint, address _proxyToken) internal onlyInitializing {
        __Ownable_init_unchained();
        __LzAppUpgradeable_init_unchained(_lzEndpoint);

        __ProxyONFT1155Upgradeable_init_unchained(_proxyToken);
    }

    function __ProxyONFT1155Upgradeable_init_unchained(address _proxyToken) internal onlyInitializing {
        require(_proxyToken.supportsInterface(type(IERC1155Upgradeable).interfaceId), "ProxyONFT1155Upgradeable: invalid ERC1155 token");
        token = IERC1155Upgradeable(_proxyToken);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ONFT1155CoreUpgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _debitFrom(address _from, uint16, bytes memory, uint[] memory _tokenIds, uint[] memory _amounts) internal virtual override {
        require(_from == _msgSender(), "ProxyONFT1155: owner is not send caller");
        token.safeBatchTransferFrom(_from, address(this), _tokenIds, _amounts, "");
    }

    function _creditTo(uint16, address _toAddress, uint[] memory _tokenIds, uint[] memory _amounts) internal virtual override {
        token.safeBatchTransferFrom(address(this), _toAddress, _tokenIds, _amounts, "");
    }

    function onERC1155Received(address _operator, address, uint, uint, bytes memory) public virtual override returns (bytes4) {
        // only allow `this` to tranfser token from others
        if (_operator != address(this)) return bytes4(0);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address _operator,
        address,
        uint[] memory,
        uint[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        // only allow `this` to tranfser token from others
        if (_operator != address(this)) return bytes4(0);
        return this.onERC1155BatchReceived.selector;
    }

    uint[49] private __gap;
}
