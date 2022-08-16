//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract NFT is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    string private _baseTokenURI;
    uint256 public prePrice = 0.0001 ether;
    uint256 public pubPrice = 0.0002 ether;

    string public contractName = "MINT SITE";
    string public contractSymbol = "MINT";

    bool public preSaleStart = false;
    bool public pubSaleStart = false;
    bool public revealed = false;

    string public BASE_EXTENSION = ".json";
    uint256 public MAX_SUPPLY = 10000;
    uint256 public constant PUBLIC_MAX_PER_TX = 10;
    uint256 public constant PRESALE_MAX_PER_WALLET = 5;

    string public notRevealedURI;
    bytes32 public merkleRoot;

    mapping(address => uint256) public whiteListClaimed;

    constructor() ERC721(contractName, contractSymbol) {}

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // public
    function pubMint(uint256 _quantity)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 cost = pubPrice * _quantity;
        mintCheck(_quantity, supply, cost);
        require(pubSaleStart, "Presale is active.");
        require(_quantity <= PUBLIC_MAX_PER_TX, "Mint amount over");

        for (uint256 i = 1; i <= _quantity; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // MerkleProof
    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function preMint(uint256 _quantity, bytes32[] calldata _merkleProof)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 cost = prePrice * _quantity;
        mintCheck(_quantity, supply, cost);
        require(preSaleStart, "Presale is not active.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        require(
            whiteListClaimed[msg.sender] + _quantity <= PRESALE_MAX_PER_WALLET,
            "Already claimed max"
        );

        for (uint256 i = 1; i <= _quantity; i++) {
            _safeMint(msg.sender, supply + i);
            whiteListClaimed[msg.sender]++;
        }
    }

    function mintCheck(
        uint256 _quantity,
        uint256 supply,
        uint256 cost
    ) private view {
        require(_quantity > 0, "Mint amount cannot be zero");
        require(supply + _quantity <= MAX_SUPPLY, "MAXSUPPLY over");
        require(msg.value >= cost, "Not enough funds");
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
        require(_exists(tokenId), "URI query for nonexistent token");

        if (revealed == false) {
            require(bytes(notRevealedURI).length > 1, "Undefined notRevealURI");
            return
                string(
                    abi.encodePacked(
                        notRevealedURI,
                        tokenId.toString(),
                        BASE_EXTENSION
                    )
                );
        }

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        tokenId.toString(),
                        BASE_EXTENSION
                    )
                )
                : "";
    }

    // only owner
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPrePrice(uint256 _price) public onlyOwner {
        prePrice = _price;
    }

    function setPubPrice(uint256 _price) public onlyOwner {
        pubPrice = _price;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // 動作
    function setPresale(bool _state) public onlyOwner {
        preSaleStart = _state;
    }

    function setPubsale(bool _state) public onlyOwner {
        pubSaleStart = _state;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
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
