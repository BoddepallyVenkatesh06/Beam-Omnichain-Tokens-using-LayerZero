// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "../ONFT1155.sol";

contract ExtendedONFT1155 is Ownable, AccessControl, ERC1155, ERC1155Supply, ERC1155Burnable, ERC2981, ONFT1155 {
    string public name;
    string public symbol;

    /********************************************
     *** Constructor
     ********************************************/

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint96 _royaltyBasePoints,
        address _lzEndpoint
    ) ONFT1155(_uri, _lzEndpoint) {
        name = _name;
        symbol = _symbol;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setDefaultRoyalty(_msgSender(), _royaltyBasePoints);
    }

    /********************************************
     *** Public functions
     ********************************************/
    /**
     * @dev Sets a new token metadata URI.
     */
    function setURI(string memory _uri) external virtual onlyOwner {
        _setURI(_uri);
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external virtual onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external virtual onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Transfer to multiple recipients.
     */
    function multiTransferFrom(address from, address[] memory tos, uint256 id, uint256 amount, bytes memory data) public virtual {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ExtendedONFT1155: caller is not token owner or approved");

        for (uint256 i = 0; i < tos.length; ++i) {
            _safeTransferFrom(from, tos[i], id, amount, data);
        }
    }

    /**
     * @dev Batch transfer to multiple recipients.
     */
    function multiBatchTransferFrom(
        address from,
        address[] memory tos,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ExtendedONFT1155: caller is not token owner or approved");

        for (uint256 i = 0; i < tos.length; ++i) {
            _safeBatchTransferFrom(from, tos[i], ids, amounts, data);
        }
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}. Includes check for token existence.
     */
    function uri(uint256 id) public view virtual override returns (string memory) {
        require(exists(id), "ExtendedONFT1155: Token ID doesn't exist");

        return super.uri(id);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981, ONFT1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /********************************************
     *** Internal functions
     ********************************************/

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint[48] private __gap;
}
