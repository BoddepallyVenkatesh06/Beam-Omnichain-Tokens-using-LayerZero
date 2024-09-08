const TOKEN_CONFIG = require("../constants/tokenConfig")

module.exports = async function (taskArgs, hre) {
    let erc20Address = taskArgs.address
    if (!erc20Address) {
        const tokenConfig = TOKEN_CONFIG[hre.network.name][taskArgs.contract]
        erc20Address = tokenConfig.address

        if (!erc20Address) {
            console.error("No ERC20 contract address found or passed")
            return
        }
    }

    let spender = taskArgs.spender
    if (!spender) {
        if (!taskArgs.contract) {
            console.error("Please pass in either `spender` or `contract` param")
            return
        }

        const proxyOFT = await ethers.getContract(taskArgs.contract)
        spender = proxyOFT.address
    }

    const ERC20 = await ethers.getContractFactory("ERC20")
    const erc20 = await ERC20.attach(erc20Address)

    console.log(`ERC20 address: ${erc20Address},\n spender to approve: ${spender}`)

    let tx = await (await erc20.approve(spender, "115792089237316195423570985008687907853269984665640564039457584007913129639935")).wait()

    console.log(`approve tx success: ${tx.transactionHash}`)
}
