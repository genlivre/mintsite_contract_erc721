const { expect, use } = require('chai')
const { ethers } = require('hardhat')
const { MerkleTree } = require('merkletreejs')
const keccak256 = require('keccak256')

use(require('chai-as-promised'))

describe('baseURI', function () {
  it('baseURIが更新されることを確認', async () => {
    const [account] = await ethers.getSigners();
    const contract = await ethers.getContractFactory("NFT");
    const token = await contract.deploy();
    await token.deployed();

    // 未MINT時のエラー検証
    await expect(
      token.tokenURI(1)
    ).to.be.rejectedWith('URI query for nonexistent token');

    // パブリックセール開始を設定
    await token.setPubsale(true)
    expect(await token.pubSaleStart()).to.equal(true);

    // pubMintが叩けることを確認
    const quantity = 1;
    const pubPrice = await token.pubPrice();

    expect(
      token.pubMint(quantity, {
        value: pubPrice,
      })
    );

    // notRevealURI未定義時のエラーを検証
    await expect(
      token.tokenURI(1)
    ).to.be.rejectedWith('Undefined notRevealURI');


    // URIを設定
    const baseURI = 'https://example.com/'
    const notRevealedURI = 'https://example.com/not-revealed/'
    await token.setBaseURI(baseURI)
    await token.setNotRevealedURI(notRevealedURI)


    // リビール前のtokenURIを検証
    const tokenId = 1
    let tokenURI = await token.tokenURI(tokenId)

    expect(tokenURI).to.equal(`${notRevealedURI}${tokenId}.json`)

    // リビール後のtokenURIを検証
    await token.reveal()
    tokenURI = await token.tokenURI(tokenId)
    expect(tokenURI).to.equal(`${baseURI}${tokenId}.json`)
  })
});

describe('WhitelistSale', function () {
  it('Whitelistに登録されているアカウントのみがMINTできることを確認', async () => {
    const accounts = await ethers.getSigners();
    const contract = await ethers.getContractFactory("NFT");
    const token = await contract.deploy();
    await token.deployed();

    const whitelisted = accounts.slice(0, 5)
    const notWhitelisted = accounts.slice(5, 10)

    const leaves = whitelisted.map(account => keccak256(account.address))
    const tree = new MerkleTree(leaves, keccak256, { sort: true })
    const merkleRoot = tree.getHexRoot()
    const rootHash = tree.getRoot()

    await token.setMerkleRoot(merkleRoot)

    // 登録するmerkleRootと、登録されているmerkleRootが一致することを確認
    expect(await token.merkleRoot()).to.equal(merkleRoot);

    const checkIncludeWhitelist = (addr) => {
      const keccakAddr = keccak256(addr);
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

    // プレセール開始を設定
    await token.setPresale(true)
    expect(await token.preSaleStart()).to.equal(true);

    // ホワリスアドレスで、preMintが叩けることを確認
    const getHexProof = (addr) => {
      const keccakAddr = keccak256(addr);
      const hexProof = tree.getHexProof(keccakAddr);
      return hexProof
    }

    const quantity = 1;
    const prePrice = await token.prePrice();
    const validMerkleProof = getHexProof(whitelisted[0].address);

    expect(
      token.preMint(quantity, validMerkleProof, {
        value: prePrice,
      })
    );

    // ホワリス外アドレスで、preMintが叩けないことを確認
    const invalidMerkleProof = getHexProof(notWhitelisted[0].address);
    await expect(
      token.connect(notWhitelisted[0]).preMint(quantity, invalidMerkleProof, {
        value: prePrice,
      })
    ).to.be.rejectedWith('Invalid Merkle Proof');
  })
})
