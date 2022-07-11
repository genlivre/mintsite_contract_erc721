//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI = "";
    string public baseExtension = ".json";
    uint256 public price = 0 ether;
    uint256 public maxSupply = 10000;
    uint256 public mintLimit = 10;
    bool public saleStart = false;
    bool public revealed = false;
    string public notRevealedUri;
    string public contractName = "MINT SITE";
    string public contractSymbol = "MINT";
    bytes32 public merkleRoot;
    mapping(address => uint256) public minted;
    mapping(address => bool) public claimed;

    constructor() ERC721(contractName, contractSymbol) {}

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 quantity) public payable {
        uint256 supply = totalSupply();
        require(saleStart);
        require(quantity > 0);
        require(quantity <= mintLimit);
        require(supply + quantity <= maxSupply);

        if (msg.sender != owner()) {
            require(msg.value >= price * quantity);
        }

        for (uint256 i = 1; i <= quantity; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // MerkleProof
    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function whitelistMint(bytes32[] calldata merkleProof, uint256 quantity)
        public
        payable
    {
        require(claimed[msg.sender] == false, "already claimed");
        claimed[msg.sender] = true;
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                toBytes32(msg.sender)
            ) == true,
            "invalid merkle proof"
        );

        uint256 supply = totalSupply();
        for (uint256 i = 1; i <= quantity; i++) {
            _mint(msg.sender, supply + i);
        }
    }

    function walletOfOwner(address _address)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_address);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_address, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    // only owner
    // 値を設定
    function setContractDatum(
        string memory _cn,
        string memory _symbol,
        string memory _notRevealedURI,
        string memory _newBaseURI,
        uint256 _maxSupply,
        uint256 _mintLimit,
        uint256 _price
    ) public onlyOwner {
        contractName = _cn;
        contractSymbol = _symbol;
        notRevealedUri = _notRevealedURI;
        baseURI = _newBaseURI;
        maxSupply = _maxSupply;
        mintLimit = _mintLimit;
        price = _price;
    }

    function setContractName(string memory _cn) public onlyOwner {
        contractName = _cn;
    }

    function setContractSymbol(string memory _symbol) public onlyOwner {
        contractSymbol = _symbol;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMintLimit(uint256 _mintLimit) public onlyOwner {
        mintLimit = _mintLimit;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // 動作
    function switchSaleStart(bool _state) external onlyOwner {
        saleStart = _state;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function withdrawRevenueShare() external onlyOwner {
        uint256 sendAmount = address(this).balance;

        address creator = payable(owner());
        address servicer = payable(0x9134b4d5c9450839A4E9862D6d171fc3c5355480);

        bool success;

        (success, ) = creator.call{value: ((sendAmount * 9000) / 10000)}("");
        require(success, "Failed to withdraw Ether");

        (success, ) = servicer.call{value: ((sendAmount * 1000) / 10000)}("");
        require(success, "Failed to withdraw Ether");
    }
}
