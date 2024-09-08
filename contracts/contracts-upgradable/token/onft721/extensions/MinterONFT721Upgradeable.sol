// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./ExtendedONFT721Upgradeable.sol";

contract MinterONFT721Upgradeable is ExtendedONFT721Upgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /********************************************
     *** Public functions
     ********************************************/

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        uint96 _royaltyBasePoints,
        uint256 _minGasToTransfer,
        address _lzEndpoint
    ) public virtual override initializer {
        __MinterONFT721Upgradeable_init(_name, _symbol, _baseUri, _royaltyBasePoints, _minGasToTransfer, _lzEndpoint);
    }

    function __MinterONFT721Upgradeable_init(
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

        __MinterONFT721Upgradeable_init_unchained();
    }

    function __MinterONFT721Upgradeable_init_unchained() internal onlyInitializing {
        _setupRole(MINTER_ROLE, _msgSender());
    }

    /**
     * @dev Public minting method, Minter-role only.
     */
    function mint(address to, uint256 tokenId) public virtual onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Multi-recipient minting.
     */
    function mintMulti(address[] memory recipients, uint256[] memory tokenIds) public virtual onlyRole(MINTER_ROLE) {
        require(recipients.length > 0 && recipients.length == tokenIds.length, "ERC721: input length mismatch");

        for (uint16 i = 0; i < tokenIds.length; i++) {
            _safeMint(recipients[i], tokenIds[i], "");
        }
    }

    /**
     * @dev Batch-Mint (same recipient).
     */
    function mintBatch(address to, uint256[] memory tokenIds) public virtual onlyRole(MINTER_ROLE) {
        require(tokenIds.length > 0, "ERC721: tokenIds can't be empty");

        for (uint16 i = 0; i < tokenIds.length; i++) {
            _safeMint(to, tokenIds[i], "");
        }
    }
}
