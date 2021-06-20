require('babel-register')
require('babel-polyfill')
require('dotenv').config()
const HDWalletProvider = require('@truffle/hdwallet-provider')
const privateKey = process.env.PRIVATE_KEY || ''
console.log(
  `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`,
  privateKey.split(','),
)
module.exports = {
  networks: {
    development: {
      host: '127.0.0.1',
      port: 7545,
      network_id: '*', // Match any network id
    },

    ropsten: {
      provider: () =>
        new HDWalletProvider(
          {
            privateKeys: privateKey.split(','),
            providerOrUrl: `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`,
            numberOfAddresses: 1,
            shareNonce: true,

          }, // Url to an Ethereum Node
        ),

      gas: 5000000,
      networkCheckTimeout: 100000,
      gasPrice: 5000000000, // 5 gwei
      network_id: 3,
    },
  },
  contracts_directory: './src/contracts/',
  contracts_build_directory: './src/abis/',
  compilers: {
    solc: {
      version: '0.8.5',
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
}
