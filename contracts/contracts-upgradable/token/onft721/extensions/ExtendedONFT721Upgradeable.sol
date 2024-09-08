// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "../ONFT721Upgradeable.sol";

contract ExtendedONFT721Upgradeable is
    OwnableUpgradeable,
    AccessControlUpgradeable,
    ERC721Upgradeable,
    ERC721RoyaltyUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    ONFT721Upgradeable,
    Proxied
{
    using StringsUpgradeable for uint256;

    string internal baseTokenURI;

    /********************************************
     *** Initializers
     ********************************************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        uint96 _royaltyBasePoints,
        uint256 _minGasToTransfer,
        address _lzEndpoint
    ) public virtual initializer {
        __ExtendedONFT721Upgradeable_init(_name, _symbol, _baseUri, _royaltyBasePoints, _minGasToTransfer, _lzEndpoint);
    }

    function __ExtendedONFT721Upgradeable_init(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        uint96 _royaltyBasePoints,
        uint256 _minGasToTransfer,
        address _lzEndpoint
    ) internal onlyInitializing {
        __ERC721_init_unchained(_name, _symbol);

        __Ownable_init_unchained();
        __LzAppUpgradeable_init_unchained(_lzEndpoint);
        __ONFT721CoreUpgradeable_init_unchained(_minGasToTransfer);

        __ExtendedONFT721Upgradeable_init_unchained(_baseUri, _royaltyBasePoints);
    }

    function __ExtendedONFT721Upgradeable_init_unchained(string memory _baseUri, uint96 _royaltyBasePoints) internal onlyInitializing {
        baseTokenURI = _baseUri;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setDefaultRoyalty(_msgSender(), _royaltyBasePoints);
    }

    /********************************************
     *** Public functions
     ********************************************/

    /**
     * @dev Multi-recipient transfer.
     */
    function transferMulti(address from, address[] memory recipients, uint256[] memory tokenIds) public virtual {
        require(recipients.length > 0 && recipients.length == tokenIds.length, "ERC721: input length mismatch");

        for (uint16 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(from, recipients[i], tokenIds[i], "");
        }
    }

    /**
     * @dev Batch-Transfer (same recipient).
     */
    function transferBatch(address from, address to, uint256[] memory tokenIds) public virtual {
        require(tokenIds.length > 0, "ERC721: tokenIds can't be empty");

        for (uint16 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(from, to, tokenIds[i], "");
        }
    }

    /**
     * @dev Set new token metadata base URI.
     */
    function setBaseURI(string memory _baseUri) public virtual onlyOwner {
        baseTokenURI = _baseUri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}. Override attaches ".json" extension to URI.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ONFT721Upgradeable, ERC721RoyaltyUpgradeable, ERC721EnumerableUpgradeable, ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /********************************************
     *** Internal functions
     ********************************************/

    /**
     * @dev Updateable base token URI override.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev See {ERC721-_burn}.
     */
    function _burn(uint256 tokenId) internal virtual override(ERC721RoyaltyUpgradeable, ERC721Upgradeable) {
        super._burn(tokenId);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721EnumerableUpgradeable, ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint[49] private __gap;
}
