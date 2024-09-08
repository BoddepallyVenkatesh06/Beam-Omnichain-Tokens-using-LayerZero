const CHAIN_ID = require("../constants/chainIds.json")

module.exports = async function ({ tokenId, targetNetwork, contract, amount }, hre) {
    const signers = await ethers.getSigners()
    const owner = signers[0]
    const toAddress = owner.address
    // get remote chain id
    const remoteChainId = CHAIN_ID[targetNetwork]

    // get local contract
    const onft = await ethers.getContract(contract)

    // quote fee with default adapterParams
    const adapterParams = ethers.utils.solidityPack(["uint16", "uint256"], [1, 200000]) // default adapterParams example

    const fees = await onft.estimateSendFee(remoteChainId, toAddress, tokenId, amount, false, adapterParams)
    const nativeFee = fees[0]
    console.log(`native fees (wei): ${nativeFee}`)

    const tx = await onft.sendFrom(
        owner.address, // 'from' address to send tokens
        remoteChainId, // remote LayerZero chainId
        toAddress, // 'to' address to send tokens
        tokenId, // tokenId to send
        amount, // qty of ERC1155
        owner.address, // refund address (if too much message fee is sent, it gets refunded)
        ethers.constants.AddressZero, // address(0x0) if not paying in ZRO (LayerZero Token)
        adapterParams, // flexible bytes array to indicate messaging adapter services
        { value: nativeFee }
    )
    console.log(`✅ [${hre.network.name}] sendFrom tx: ${tx.hash}`)
    await tx.wait()
}
