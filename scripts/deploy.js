async function main() {
  const NFT = await ethers.getContractFactory("NFT")
  const nft = await NFT.deploy('MINTSITE TESR', 'MT', 'https://example.com/', 'https://example.com/revealed/')
  console.log("Contract deployed to address:", nft.address)
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
