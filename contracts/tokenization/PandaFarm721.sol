//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../access/MinterAccessControl.sol";

/**
 * @title PandaFarm ERC721
 *
 * @author PandaFarm
 */
contract PandaFarm721 is ERC721URIStorage, Ownable, MinterAccessControl {
    event PandaFarm721AttributeOperatorUpdated(
        address indexed _operatorAddress,
        bool indexed _flag
    );
    event PandaFarm721AttributeUpdated(
        address indexed _operatorAddress,
        uint256 indexed _tokenId
    );
    event PandaFarm721AttributeMaxUpdated(
        address indexed _operatorAddress,
        uint256 indexed _tokenId
    );
    event PandaFarm721GeneUpdated(
        address indexed _operatorAddress,
        uint256 indexed _tokenId
    );
    //Used to manipulate game attribute
    mapping(address => bool) private operators;

    //0-exp 1-size 2-agility 3-strength 4-stamina 5-tooth 6-claw
    //7-digestion 8-sight 9-weather 10-winnerBigEaterCount 11-winnerClimbTree
    //12-level 13-bak 14-bak 15-bak 16-bak 17-bak 18-bak 19-bak
    mapping(uint256 => uint256[]) private attribute;
    //attribute Max
    mapping(uint256 => uint256[]) private attributeMax;
    //0-sex(1Male,0Female) 1-gen 2-fatherId 3-matherId 4-son 5-daughter 6-bak 7-bak 8-bak 9-bak
    mapping(uint256 => uint256[]) private gene;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function exist(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function getGene(uint256 _tokenId) public view returns (uint256[] memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        uint256[] memory genes = gene[_tokenId];
        return genes;
    }

    function getGeneByIndex(uint256 _tokenId, uint256 _index)
        public
        view
        returns (uint256)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        uint256[] memory genes = gene[_tokenId];
        require(_index <= genes.length, "ERC721: gene index error");
        return genes[_index];
    }

    function getAttribute(uint256 _tokenId)
        public
        view
        returns (uint256[] memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: TokenId query for nonexistent token"
        );
        uint256[] memory attributes = attribute[_tokenId];
        return attributes;
    }

    function getAttributeByIndex(uint256 _tokenId, uint256 _index)
        public
        view
        returns (uint256)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: TokenId query for nonexistent token"
        );
        uint256[] memory attributes = attribute[_tokenId];
        require(_index <= attributes.length, "ERC721: attribute index error");
        return attributes[_index];
    }

    function setAttributeByIndex(
        uint256 _tokenId,
        uint256 _index,
        uint256 _attr
    ) public {
        require(operators[_msgSender()], "ERC721: attribute address error");
        require(_index < 20, "ERC721: index>20");
        require(_attr > 0, "ERC721: attribute is null");
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        require(
            validGameAttribute(_tokenId, _index, _attr),
            "ERC721: attribute data error"
        );

        uint256[] storage attributes = attribute[_tokenId];
        require(_index <= attributes.length, "ERC721: index error");
        attributes[_index] = _attr;

        emit PandaFarm721AttributeUpdated(_msgSender(), _tokenId);
    }

    function setAttribute(uint256 _tokenId, uint256[] memory _attr) public {
        require(operators[_msgSender()], "ERC721: attribute address error");
        require(_attr.length > 0, "ERC721: attribute is null");
        require(
            validGameAttributes(_attr, attributeMax[_tokenId]),
            "ERC721Metadata: attribute data error"
        );
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        attribute[_tokenId] = _attr;
        emit PandaFarm721AttributeUpdated(_msgSender(), _tokenId);
    }

    function setGeneByIndex(
        uint256 _tokenId,
        uint256 _index,
        uint256 _gene
    ) public {
        require(operators[_msgSender()], "ERC721: attribute address error");
        require(_index < 10, "ERC721: index>10");
        require(_gene > 0, "ERC721: gene is null");
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256[] storage genes = gene[_tokenId];
        require(_index <= genes.length, "ERC721: index error");
        genes[_index] = _gene;

        emit PandaFarm721GeneUpdated(_msgSender(), _tokenId);
    }
    
    function setGene(uint256 _tokenId, uint256[] memory _gene) public {
        require(operators[_msgSender()], "ERC721: gene address error");
        require(_gene.length > 0, "ERC721: gene is null");
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        gene[_tokenId] = _gene;
        emit PandaFarm721GeneUpdated(_msgSender(), _tokenId);
    }

    function getAttributeMax(uint256 _tokenId)
        public
        view
        returns (uint256[] memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: TokenId query for nonexistent token"
        );
        uint256[] memory attMax = attributeMax[_tokenId];
        return attMax;
    }

    function getAttributeMaxByIndex(uint256 _tokenId, uint256 _index)
        public
        view
        returns (uint256)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: TokenId query for nonexistent token"
        );
        uint256[] memory attMax = attributeMax[_tokenId];
        require(_index <= attMax.length, "ERC721: attribute max index error");
        return attMax[_index];
    }

    function setAttributeMaxByIndex(
        uint256 _tokenId,
        uint256 _index,
        uint256 _attrMax
    ) public {
        require(operators[_msgSender()], "ERC721: attribute address error");
        require(_index < 20, "ERC721: index>15");
        require(_attrMax > 0, "ERC721: attribute is null");
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256[] storage attMax = attributeMax[_tokenId];
        require(_index <= attMax.length, "ERC721: index error");
        attMax[_index] = _attrMax;

        emit PandaFarm721AttributeMaxUpdated(_msgSender(), _tokenId);
    }

    function setAttributeMax(uint256 _tokenId, uint256[] memory _attrMax)
        public
    {
        require(operators[_msgSender()], "ERC721: attribute address error");
        require(_attrMax.length > 0, "ERC721: attribute is null");
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        attributeMax[_tokenId] = _attrMax;
        emit PandaFarm721AttributeMaxUpdated(_msgSender(), _tokenId);
    }

    /**
     * @dev Mint a NFT to a address
     * @param _to address
     * @param _tokenId the tokenId of NFT
     * @param _attributes the attributes of NFT
     * @param _tokenURI the tokenURI of NFT
     **/
    function mintTo(
        address _to,
        uint256 _tokenId,
        uint256[] memory _attributes,
        uint256[] memory _attributesMax,
        uint256[] memory _genes,
        string memory _tokenURI
    ) public isMinterOrOwner {
        _mint(_to, _tokenId, _attributes, _attributesMax, _genes, _tokenURI);
    }

    /**
     * @dev Mint a NFT to msgSender
     * @param _tokenId the tokenId of NFT
     * @param _attributes the attributes of NFT
     * @param _tokenURI the tokenURI of NFT
     **/
    function mint(
        uint256 _tokenId,
        uint256[] memory _attributes,
        uint256[] memory _attributesMax,
        uint256[] memory _genes,
        string memory _tokenURI
    ) public isMinterOrOwner {
        _mint(
            _msgSender(),
            _tokenId,
            _attributes,
            _attributesMax,
            _genes,
            _tokenURI
        );
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public isMinterOrOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    function _mint(
        address _to,
        uint256 _tokenId,
        uint256[] memory _attributes,
        uint256[] memory _attributesMax,
        uint256[] memory _genes,
        string memory _tokenURI
    ) internal {
        require(
            validGameAttributes(_attributes, _attributesMax),
            "ERC721Metadata: attribute data error"
        );
        super._mint(_to, _tokenId);
        if (bytes(_tokenURI).length > 0) {
            _setTokenURI(_tokenId, _tokenURI);
        }
        attribute[_tokenId] = _attributes;
        attributeMax[_tokenId] = _attributesMax;
        gene[_tokenId] = _genes;
    }

    /**
     * @dev Set a NFT operator
     * @param _operatorAddress the tokenId of NFT
     * @param _flag the attributes of NFT
     **/
    function setOperator(address _operatorAddress, bool _flag)
        public
        onlyOwner
    {
        operators[_operatorAddress] = _flag;
        emit PandaFarm721AttributeOperatorUpdated(_operatorAddress, _flag);
    }

    /**
     * @dev Get a NFT operator
     * @param _operatorAddress the tokenId of NFT
     **/
    function getOperator(address _operatorAddress) public view returns (bool) {
        return operators[_operatorAddress];
    }

    function validGameAttributes(
        uint256[] memory _attributes,
        uint256[] memory _attributesMax
    ) public pure returns (bool) {
        for (uint256 i = 0; i < _attributes.length; i++) {
            if (_attributes[i] > _attributesMax[i]) {
                return false;
            }
        }
        return true;
    }

    function validGameAttribute(
        uint256 _tokenId,
        uint256 _index,
        uint256 _attribute
    ) public view returns (bool) {
        uint256[] memory attMax = attributeMax[_tokenId];
        if (_attribute > attMax[_index]) {
            return false;
        }
        return true;
    }
}
