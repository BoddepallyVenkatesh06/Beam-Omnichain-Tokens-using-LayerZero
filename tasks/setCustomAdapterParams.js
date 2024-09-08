const CHAIN_ID = require("../constants/chainIds.json")

module.exports = async function (taskArgs, hre) {
    const contract = await ethers.getContract(taskArgs.contract)

    const tx = await contract.setUseCustomAdapterParams(true)

    console.log(`[${hre.network.name}] setUseCustomAdapterParams tx hash ${tx.hash}`)
    await tx.wait()
}
