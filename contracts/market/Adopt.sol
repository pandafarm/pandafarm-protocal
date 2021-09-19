//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../access/OperatorAccessControl.sol";
import "../tokenization/PandaFarm721.sol";
import "../core/DataProvider.sol";
import "../libraries/GameSportLib.sol";
import "../libraries/GameSportUserLib.sol";


contract Adopt is OperatorAccessControl, ReentrancyGuard {

    uint public mintPrice = 50000000000000000;
    mapping(uint256 => NFT) internal tokenIdCid;
    uint256[] tokenId;

    uint256[] attributes = [0, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint256[] attributesMax = [999, 180, 0, 0, 0, 0, 0, 0, 0, 20, 99999, 99999, 99999, 99999, 99999, 999, 999, 999, 99, 99];
    uint256[] genes = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    //Random number distortion salt
    uint256 internal salt = 99;

    DataProvider internal dataProvider;

    struct NFT {
        string cid;
        uint256 sex;
        bool isMint;
    }
    /**
     * @dev Initializes the contract
     */
    constructor(address dataProvider_) {
        dataProvider = DataProvider(dataProvider_);
    }

    function setMintPrice(uint mintPrice_) external isOperatorOrOwner {
        mintPrice = mintPrice_;
    }

    function withdraw() public nonReentrant onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function addTokenId(uint256[] memory _tokenId, uint256[] memory _sex, string[] memory _tokenURI)
    public isOperatorOrOwner {
        require(
            _tokenId.length == _tokenURI.length,
            "Adopt: Array token error"
        );
        require(
            _tokenId.length == _sex.length,
            "Adopt: Array sex error"
        );
        PandaFarm721 _bambooERC721 = PandaFarm721(dataProvider.getNftPandaAddress());
        for (uint256 i; i < _tokenId.length; i++) {
            if (_bambooERC721.exist(_tokenId[i])) {
                continue;
            }
            if (bytes(tokenIdCid[_tokenId[i]].cid).length > 0) {
                continue;
            }
            tokenIdCid[_tokenId[i]].isMint = false;
            tokenIdCid[_tokenId[i]].cid = _tokenURI[i];
            tokenIdCid[_tokenId[i]].sex = _sex[i];
            tokenId.push(_tokenId[i]);
        }
    }


    function claim(uint256 tokenAmount) public payable nonReentrant {
        require(msg.value == mintPrice * tokenAmount, "msg.value is incorrect");
        require(tokenAmount <= 10, "Wrong token amount. max 10");
        require(tokenAmount <= tokenId.length, "Token is not enough");

        uint256 tokenRandom = 0;
        for (uint i = 0; i < tokenAmount; i++) {
            (salt, tokenRandom) = random(salt, tokenId.length - 1);
            uint256 tokenIdClaim = tokenId[tokenRandom];
            tokenId[tokenRandom] = tokenId[tokenId.length - 1];
            tokenId.pop();
            string memory cid = tokenIdCid[tokenIdClaim].cid;
            (uint256[] memory _attributes,uint256[] memory _attributesMax) = getAttribute();

            uint256[] memory _genes = genes;
            _genes[0] = tokenIdCid[tokenIdClaim].sex;

            PandaFarm721 _bambooERC721 = PandaFarm721(dataProvider.getNftPandaAddress());
            _bambooERC721.mintTo(_msgSender(), tokenIdClaim, _attributes, _attributesMax, _genes, cid);
            tokenIdCid[tokenIdClaim].isMint = true;
        }
    }

    function getAttribute() internal returns (uint256[] memory _attr, uint256[] memory _attrMax){
        uint256[] memory _attributes = attributes;
        uint256[] memory _attributesMax = attributesMax;

        uint256 agility = 0;
        uint256 strength = 0;
        uint256 stamina = 0;
        uint256 tooth = 0;
        uint256 claw = 0;
        uint256 digestion = 0;
        uint256 sight = 0;

        (salt, agility) = random(salt, 15);
        agility += 70;

        _attributes[2] = agility;
        _attributesMax[2] = agility;

        (salt, strength) = random(salt, 15);
        strength += 70;
        _attributes[3] = strength;
        _attributesMax[3] = strength;

        (salt, stamina) = random(salt, 15);
        stamina += 70;
        _attributes[4] = stamina;
        _attributesMax[4] = stamina;

        (salt, tooth) = random(salt, 15);
        tooth += 70;
        _attributes[5] = tooth;
        _attributesMax[5] = tooth;

        (salt, claw) = random(salt, 15);
        claw += 70;
        _attributes[6] = claw;
        _attributesMax[6] = claw;

        (salt, digestion) = random(salt, 15);
        digestion += 70;
        _attributes[7] = digestion;
        _attributesMax[7] = digestion;

        (salt, sight) = random(salt, 15);
        sight += 70;
        _attributes[8] = sight;
        _attributesMax[8] = sight;

        return (_attributes, _attributesMax);
    }

    function getTokenIds() public view returns (uint256[] memory){
        return attributes;
    }

    function getProviderAddress()  public view returns (address){
        return address(dataProvider);
    }

    function getCidByTokenId(uint256 _tokenId) public view returns (string memory){
        return tokenIdCid[_tokenId].cid;
    }

    /**
     * @dev Get random number
     **/
    function random(uint256 _salt, uint256 _baseNumber)
    internal
    view
    returns (uint256, uint256)
    {
        if (_baseNumber == 0) {
            return (_salt, 0);
        }
        uint256 r = uint256(
            keccak256(
                abi.encodePacked(
                    _salt,
                    block.coinbase,
                    block.difficulty,
                    block.number,
                    block.timestamp
                )
            )
        );
        return (r, r % _baseNumber);
    }
}