// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "../fee/BaseOFTWithFeeUpgradeable.sol";

/**
 * "NativeMinter" Avalanche Subnet precompile interface
 * https://docs.avax.network/build/subnet/upgrade/customize-a-subnet#minting-native-coins
 */

interface INativeMinter {
    // Mint [amount] number of native coins and send to [addr]
    function mintNativeCoin(address addr, uint256 amount) external;
}

/**
 * This contract is based on "NativeOFTV2" and "ProxyOFTV2", and takes advantage of
 * the "NativeMinter" Avalanche Subnet precompile to mint and burn native currency
 * on-the-fly instead of locking it up.
 */

contract NativeProxyOFTWithFeeUpgradeable is Initializable, BaseOFTWithFeeUpgradeable, PausableUpgradeable, Proxied {
    uint internal ld2sdRate;
    uint internal supply;
    INativeMinter internal constant nativeMinter = INativeMinter(address(0x0200000000000000000000000000000000000001));
    address public constant BURN_ADDRESS = 0x0100000000000000000000000000000000000000;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint8 _nativeDecimals, uint8 _sharedDecimals, address _lzEndpoint) public initializer {
        __Ownable_init_unchained();
        __LzAppUpgradeable_init_unchained(_lzEndpoint);
        __OFTCoreV2Upgradeable_init_unchained(_sharedDecimals);
        __Pausable_init_unchained();

        require(_sharedDecimals <= _nativeDecimals, "NativeProxyOFTWithFee: sharedDecimals must be <= nativeDecimals");
        ld2sdRate = 10 ** (_nativeDecimals - _sharedDecimals);
    }

    /************************************************************************
     * public functions
     ************************************************************************/
    // allow 0x0 to burn fee instead
    function setFeeOwner(address _feeOwner) public virtual override onlyOwner {
        feeOwner = _feeOwner;
        emit SetFeeOwner(_feeOwner);
    }

    // pausable
    function pause(bool _enable) public virtual onlyOwner {
        if (_enable) {
            _pause();
        } else {
            _unpause();
        }
    }

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint _amount,
        uint _minAmount,
        LzCallParams calldata _callParams
    ) public payable virtual override whenNotPaused {
        return super.sendFrom(_from, _dstChainId, _toAddress, _amount, _minAmount, _callParams);
    }

    function sendAndCall(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint _amount,
        uint _minAmount,
        bytes calldata _payload,
        uint64 _dstGasForCall,
        LzCallParams calldata _callParams
    ) public payable virtual override whenNotPaused {
        return super.sendAndCall(_from, _dstChainId, _toAddress, _amount, _minAmount, _payload, _dstGasForCall, _callParams);
    }

    function token() public view virtual override returns (address) {
        return address(0);
    }

    function circulatingSupply() public view virtual override returns (uint) {
        return supply;
    }

    /************************************************************************
     * internal functions
     ************************************************************************/
    function _send(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual override returns (uint amount) {
        _checkAdapterParams(_dstChainId, PT_SEND, _adapterParams, NO_EXTRA_GAS);

        (amount, ) = _removeDust(_amount);
        require(amount > 0, "NativeProxyOFTWithFee: amount too small");
        uint messageFee = _debitFromNative(amount);

        bytes memory lzPayload = _encodeSendPayload(_toAddress, _ld2sd(amount));
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, messageFee);

        emit SendToChain(_dstChainId, _from, _toAddress, amount);
    }

    function _sendAndCall(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint _amount,
        bytes memory _payload,
        uint64 _dstGasForCall,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual override returns (uint amount) {
        _checkAdapterParams(_dstChainId, PT_SEND_AND_CALL, _adapterParams, _dstGasForCall);

        (amount, ) = _removeDust(_amount);
        require(amount > 0, "NativeProxyOFTWithFee: amount too small");
        uint messageFee = _debitFromNative(amount);

        // encode the msg.sender into the payload instead of _from
        bytes memory lzPayload = _encodeSendAndCallPayload(msg.sender, _toAddress, _ld2sd(amount), _payload, _dstGasForCall);
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, messageFee);

        emit SendToChain(_dstChainId, _from, _toAddress, amount);
    }

    function _debitFromNative(uint _amount) internal virtual whenNotPaused returns (uint messageFee) {
        require(msg.value >= _amount, "NativeProxyOFTWithFee: Insufficient msg.value");
        // update the messageFee to take out the token amount
        messageFee = msg.value - _amount;

        // burn native tokens
        _burnNative(_amount);

        return messageFee;
    }

    function _debitFrom(address, uint16, bytes32, uint _amount) internal virtual override whenNotPaused returns (uint) {
        return _debitFromNative(_amount);
    }

    function _creditTo(uint16, address _toAddress, uint _amount) internal virtual override whenNotPaused returns (uint) {
        // mint native tokens
        _mintNative(_toAddress, _amount);

        return _amount;
    }

    // native currency transfer
    function _transferFrom(address, address _to, uint _amount) internal virtual override whenNotPaused returns (uint) {
        require(msg.value >= _amount, "NativeProxyOFTWithFee: Insufficient msg.value");

        (bool success, ) = address(_to).call{value: _amount}("");

        require(success, "NativeProxyOFTWithFee: Transferring native tokens failed");

        return _amount;
    }

    // mints native currency (gas tokens) by calling Avalanche's NativeMinter precompile
    function _mintNative(address _toAddress, uint _amount) internal virtual whenNotPaused {
        uint newBalance = msg.sender.balance + _amount;
        nativeMinter.mintNativeCoin(_toAddress, _amount);

        require(msg.sender.balance == newBalance, "NativeProxyOFTWithFee: Minting native tokens failed");

        // update tracker
        supply = supply + _amount;
    }

    // burn native tokens sent with tx
    function _burnNative(uint _amount) internal virtual {
        _transferFrom(address(0), BURN_ADDRESS, _amount);

        // update tracker
        supply = supply > _amount ? supply - _amount : 0;
    }

    function _ld2sdRate() internal view virtual override returns (uint) {
        return ld2sdRate;
    }
}
