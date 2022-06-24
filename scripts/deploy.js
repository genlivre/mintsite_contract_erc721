async function main() {
  const NFT = await ethers.getContractFactory("NFT")
  const nft = await NFT.deploy()
  console.log("Contract deployed to address:", nft.address)
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
