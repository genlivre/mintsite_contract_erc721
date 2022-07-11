const { expect, use } = require('chai')
const { ethers } = require('hardhat')
const { MerkleTree } = require('merkletreejs')
const { keccak256 } = ethers.utils

use(require('chai-as-promised'))

describe('WhitelistSale', function () {
  it('Whitelistに登録されているアカウントのみがMINTできることを確認', async () => {
    const accounts = await ethers.getSigners();
    const contract = await ethers.getContractFactory("NFT");
    const token = await contract.deploy();
    await token.deployed();

    const whitelisted = accounts.slice(0, 5)
    const notWhitelisted = accounts.slice(5, 10)

    const padBuffer = (addr) => {
      return Buffer.from(addr.substr(2).padStart(32*2, 0), 'hex')
    }

    const leaves = whitelisted.map(account => padBuffer(account.address))
    const tree = new MerkleTree(leaves, keccak256, { sort: true })
    const merkleRoot = tree.getHexRoot()
    const rootHash = tree.getRoot()

    await token.setMerkleRoot(merkleRoot)

    // 登録するmerkleRootと、登録されているmerkleRootが一致することを確認
    expect(await token.merkleRoot()).to.equal(merkleRoot);

    const checkIncludeWhitelist = (addr) => {
      const keccakAddr = padBuffer(addr);
      const hexProof = tree.getHexProof(keccakAddr);
      const result = tree.verify(hexProof, keccakAddr, rootHash);
      console.log(addr, 'included in the white list?:', result);

      return result;
    }

    const whitelistUserCheck = checkIncludeWhitelist(whitelisted[0].address);
    const notWhitelistUserCheck = checkIncludeWhitelist(notWhitelisted[0].address);

    // ホワリスアドレス・ホワリス外アドレスがきちんと認証されるかを確認
    expect(whitelistUserCheck).to.equal(true);
    expect(notWhitelistUserCheck).to.equal(false);


    // ホワリスアドレスで、whitelistMintが叩けることを確認
    const getHexProof = (addr) => {
      const keccakAddr = padBuffer(addr);
      const hexProof = tree.getHexProof(keccakAddr);
      return hexProof
    }

    const quantity = 3;
    const validMerkleProof = getHexProof(whitelisted[0].address)
    await expect(token.whitelistMint(validMerkleProof, quantity)).to.not.be.rejected
    await expect(token.whitelistMint(validMerkleProof, quantity)).to.be.rejectedWith('already claimed')

    // ホワリス外アドレスで、whitelistMintが叩けないことを確認
    const invalidMerkleProof = getHexProof(notWhitelisted[0].address)
    await expect(token.connect(notWhitelisted[0]).whitelistMint(invalidMerkleProof, quantity)).to.be.rejectedWith('invalid merkle proof')
  })
})
