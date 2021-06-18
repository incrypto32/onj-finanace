const Token = artifacts.require("Token");
const OnjiBank = artifacts.require("OnjiBank");

module.exports = async function(deployer) {
	//deploy Token
	await deployer.deploy(Token)

	//assign token into variable to get it's address
	const token = await Token.deployed()
	
	//pass token address for dBank contract(for future minting)
	await deployer.deploy(OnjiBank, token.address)

	//assign dBank contract into variable to get it's address
	const onjiBank = await OnjiBank.deployed()

	//change token's owner/minter from deployer to dBank
	await token.passMinterRole(onjiBank.address)
};