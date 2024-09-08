// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// this is a MOCK
abstract contract Faucet is ERC20 {
    mapping(address => uint256) public lastClaimedAt;
    uint256 public constant FAUCET_DRIP = 100; // eth
    uint256 public constant COOLDOWN = 3600; // sec
    uint256 internal pow;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        pow = 10 ** decimals();
        _mint(msg.sender, 100000000 * pow);
    }

    function canClaim(address account) public view returns (bool) {
        return lastClaimedAt[account] + COOLDOWN < block.timestamp;
    }

    function claim() external {
        require(canClaim(msg.sender), "wallet claimed recently");

        lastClaimedAt[msg.sender] = block.timestamp;
        _mint(msg.sender, FAUCET_DRIP * pow);
    }
}

abstract contract USDFaucet is Faucet {
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}

contract USDCMock is USDFaucet {
    constructor() Faucet("USD Coin", "USDC") {}
}

contract USDTMock is USDFaucet {
    constructor() Faucet("Tether USD", "USDT") {}
}

contract BeamMock is Faucet {
    constructor() Faucet("Beam", "BEAM") {}
}
