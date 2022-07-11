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
```npx hardhat run scripts/deploy.js```

### Rinkebyへデプロイ
```npx hardhat run scripts/deploy.js --network rinkeby```

### etherscan(Rinkeby)へverify
#### 引数なしの場合
```npx hardhat verify --contract contracts/NFT.sol:NFT --network rinkeby デプロイしたコントラクトAddress```

#### 引数ありの場合
```npx hardhat verify --constructor-args ./scripts/arguments.js --contract contracts/NFT.sol:NFT --network rinkeby デプロイしたコントラクトAddress```
```npx hardhat verify --constructor-args ./scripts/arguments.js --contract contracts/NFT.sol:NFT --network rinkeby 0x861cfD8Fe9816517a5FD7d80CFC5E15092F6d060```

### 再度verify
```npx hardhat clean```

## 注意点
deployを行うために、Contractの初期値を設定する必要がある。  
初期値は  
- deploy.jsの引数
- arguments.js
で指定する。

参考：[hardhat-etherscan](https://hardhat.org/plugins/nomiclabs-hardhat-etherscan)
