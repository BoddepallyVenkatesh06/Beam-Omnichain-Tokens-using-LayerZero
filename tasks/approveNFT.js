// ERC721 and ERC1155
const TOKEN_CONFIG = require("../constants/tokenConfig")

module.exports = async function (taskArgs, hre) {
    let nftAddress = taskArgs.address
    if (!nftAddress) {
        const tokenConfig = TOKEN_CONFIG[hre.network.name][taskArgs.contract]
        nftAddress = tokenConfig && tokenConfig.address

        if (!nftAddress) {
            console.error("No NFT contract address found or passed")
            return
        }
    }

    let spender = taskArgs.spender
    if (!spender) {
        if (!taskArgs.contract) {
            console.error("Please pass in either `spender` or `contract` param")
            return
        }

        const proxyONFT = await ethers.getContract(taskArgs.contract)
        spender = proxyONFT && proxyONFT.address

        if (!spender) {
            console.error("Proxy contract not found")
            return
        }
    }

    const NFT = await ethers.getContractFactory("ERC721")
    const nft = await NFT.attach(nftAddress)

    console.log(`NFT address: ${nftAddress},\n spender to approve: ${spender}`)

    let tx = await (await nft.setApprovalForAll(spender, true)).wait()

    console.log(`approve tx success: ${tx.transactionHash}`)
}
