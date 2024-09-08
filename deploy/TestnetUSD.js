module.exports = async function ({ deployments, getNamedAccounts }) {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()
    console.log(`>>> your address: ${deployer}`)

    console.log(`deploying mock USDC...`)
    await deploy("USDCMock", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: 1,
    })

    console.log(`deploying mock USDT...`)
    await deploy("USDTMock", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: 1,
    })
}

module.exports.tags = ["TestnetUSD"]
