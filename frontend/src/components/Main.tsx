/* eslint-disable spaced-comment */
/// <reference types="react-scripts" />
import { useEthers } from "@usedapp/core"
import helperConfig from "../helper-config.json"
import networkMapping from "../chain-info/deployments/map.json"
import { constants } from "ethers"
import brownieConfig from "../brownie-config.json"
import shit from "../shit.png"
import eth from "../eth.png"
import dai from "../dai.png"
import { YourWallet } from "./yourWallet"
import { makeStyles } from "@material-ui/core"

export type Token = {
    image: string
    address: string
    name: string
}

const useStyles = makeStyles((theme: any) => ({
    title: {
        color: theme.palette.common.white,
        textAlign: "center",
        padding: theme.spacing(4)
    }
}))

export const Main = () => {
    const classes = useStyles()
    const { chainId, error } = useEthers()
    let hConfig: {[key: string]: string} = helperConfig
    let stringChainId = String(chainId)
    const networkName = chainId ? hConfig[stringChainId] : "dev"
    const shitTokenAddress = chainId ? networkMapping[stringChainId]["ShitToken"][0] : constants.AddressZero
    const wethTokenAddress = chainId ? brownieConfig["networks"][networkName]["weth_token"] : constants.AddressZero 
    const fauTokenAddress = chainId ? brownieConfig["networks"][networkName]["fau_token"] : constants.AddressZero

    const supportedTokens: Array<Token> = [
        {
            image: shit,
            address: shitTokenAddress,
            name: "SHIT"
        },
        {
            image: eth,
            address: wethTokenAddress,
            name: "WETH"
        },
        {
            image: dai,
            address: fauTokenAddress,
            name: "DAI"
        }
    ]

    return (<>
        <h2 className={classes.title}>Token Farm App</h2>
        <YourWallet supportedTokens={supportedTokens} />
    </>)
}