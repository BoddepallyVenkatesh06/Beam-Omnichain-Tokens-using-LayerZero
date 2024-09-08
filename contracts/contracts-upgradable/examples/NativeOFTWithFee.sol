// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../token/oft/v2/fee/NativeOFTWithFeeUpgradeable.sol";
import "../token/oft/v2/fee/ProxyOFTWithFeeUpgradeable.sol";
import "../token/oft/v2/fee/OFTWithFeeUpgradeable.sol";
import "../token/oft/v2/fee/OFTWithFeePermitUpgradeable.sol";

contract BeamProxyOFT is ProxyOFTWithFeeUpgradeable {}

contract BeamNativeOFT is NativeOFTWithFeeUpgradeable {}

contract BeamOFT is OFTWithFeeUpgradeable {}

contract AvaxOFT is OFTWithFeeUpgradeable {}

contract AvaxNativeOFT is NativeOFTWithFeeUpgradeable {}

contract EthereumOFT is OFTWithFeePermitUpgradeable {}

contract EthereumNativeOFT is NativeOFTWithFeeUpgradeable {}
