# ERC721 Token Deploy(ミントサイトでの利用を想定)

## 準備
### npmのインストール
```npm install```

### hardhatプロジェクトの作成(既にhardhatプロジェクトを作成済みの場合は不要)
```npx hardhat```

# hardhat compile
```npx hardhat compile```

## テストの実行
```npx hardhat test```

## コントラクトのデプロイ
### localへのデプロイ
```npx hardhat run scripts/NFT.js```

### Rinkebyへデプロイ
```npx hardhat run scripts/deploy.js --network rinkeby```

### etherscan(Rinkeby)へverify
```npx hardhat verify --contract contracts/NFT.sol:NFT --network rinkeby デプロイしたコントラクトAddress```

### 再度verify
```npx hardhat clean```
