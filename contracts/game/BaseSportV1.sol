//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../access/OperatorAccessControl.sol";

import "../tokenization/PandaFarm721.sol";
import "../core/DataProvider.sol";
import "../libraries/GameSportLib.sol";
import "../libraries/GameSportUserLib.sol";



abstract contract BaseSportV1 is OperatorAccessControl {

    using GameSportUserLib for GameSportUserLib.GameSportUserData;
    using GameSportLib for GameSportLib.SportUserData;
    using GameSportLib for GameSportLib.SportData;

    event BaseConfigUpdated(bool flag,
        uint256 maxNFTCount,
        uint256 maxJoinTimePerUnitTime,
        uint256 maxPerUnitTime,
        uint256 ticketAmount);


    event Liquidate(uint256 sportBlockHeigth,
        address indexed userAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 point);


    event SportInit(uint256 blockHeigth,
        uint256 tokenId,
        uint256 amount,
        uint256 point);

    event DataProviderUpdated(address indexed addr);

    DataProvider internal dataProvider;

    //Token name
    string internal _name;
    //isActive = true means the race has been activated and properly configured
    bool public isActive;
    //Total number of NFTs participated
    uint256 internal totalNFTCount;
    //Total assets of all participating tickets
    uint256 internal totalBalance;
    //Maximum number of NFTs per game
    uint256 internal maxNFTCount = 4;
    //Number of game per unit time
    uint256 internal maxJoinTimePerUnitTime = 6;
    //Number of unit time. 3s/block(1min=20block)
    uint256 internal maxPerUnitTime = 20 * 60 * 6;

    //Random number distortion salt
    uint256 internal salt = 99;
    //Number of tickets to be paid for each parameter competition
    uint256 internal ticketAmount;
    //Block height corresponding to the current game
    uint256 internal currentSportBlockHeight = 0;

    //Mapping of game data
    mapping(uint256 => GameSportLib.SportData) internal sportData;
    //Game user data mapping
    mapping(uint256 => mapping(uint256 => GameSportLib.SportUserData)) internal sportUserData;
    //User data corresponding to the game
    mapping(uint256 => GameSportUserLib.GameSportUserData) internal globalTokenId;
    /**
     * @dev Initializes the contract
     */
    constructor(
        string memory name_,
        address dataProvider_,
        bool isActive_,
        uint256 ticketAmount_,
        uint maxJoinTimePerUnitTime_,
        uint256 maxNFTCount_
    ) {
        _name = name_;
        isActive = isActive_;
        ticketAmount = ticketAmount_;
        maxJoinTimePerUnitTime = maxJoinTimePerUnitTime_;
        maxNFTCount = maxNFTCount_;
        dataProvider = DataProvider(dataProvider_);
    }


    /**
     * @dev Join the game
     * @param _tokenId NFT tokenId
     * @param _amount  Ticket amount
     */
    function join(
        // uint256 _sportBlock,
        uint256 _tokenId,
        uint256 _amount
    ) public returns (uint256[] memory attribute,uint256 currentSportBlockHeight_) {
        require(currentSportBlockHeight < block.number, "Game: the current game data is not ready,please waiting next block");
        require(_amount >= currentSportBlockHeight, "Game: currentSportBlockHeight is error");
        require(_amount >= ticketAmount, "Game: the ticket amount is not enough");
        require(address(_msgSender()) != address(0), "Game: address provider is 0x");
        //Check the basic attributes of NFT
        PandaFarm721 _bambooERC721 = PandaFarm721(dataProvider.getNftPandaAddress());
        require(_bambooERC721.ownerOf(_tokenId) == _msgSender(), "Game: tokenId owner error");
        IERC20 _bambooERC20 = IERC20(dataProvider.getTokenBambooAddress());
        //If this is the first time to initialize the game pool
        if (currentSportBlockHeight == 0) {
        // if (_sportBlock == 0 && currentSportBlockHeight == 0) {
            currentSportBlockHeight = block.number;
            sportData[currentSportBlockHeight].initSport(currentSportBlockHeight, _bambooERC20.balanceOf(address(this)));
        }
        //  else {
        //     require(sportData[_sportBlock].startBlockHeight > 0, "Game: The corresponding game pool does not exist");
        // }
        GameSportLib.SportData storage sportDataInfo = sportData[currentSportBlockHeight];
        require(isActive, "Game: current game contract is not active");
        require(sportDataInfo.participateUser.length < maxNFTCount, "Game: currentNFTCount is greater than max");
        require(sportUserData[currentSportBlockHeight][_tokenId].userAddress == address(0), "Game: current tokenId is join current game,please wait for the next");

        if (globalTokenId[_tokenId].userAddress == address(0)) {
            globalTokenId[_tokenId].initUserGlobal(_msgSender(), _tokenId, block.number, 0);
        } else {
            //Determine whether the user block data needs to be reset
            if (block.number - globalTokenId[_tokenId].lastBlockHeight > maxPerUnitTime) {
                globalTokenId[_tokenId].lastBlockHeight = block.number;
                globalTokenId[_tokenId].joinTime = 0;
            } else {
                //If the user's block data is valid and the number of join reaches the limit
                require(globalTokenId[_tokenId].joinTime < maxJoinTimePerUnitTime,
                    "Game: Number of tickets to be paid for each game");
                globalTokenId[_tokenId].joinTime++;
            }
        }

        //Erc20 token is transferred to the current contract. If it fails, there may be no authorization
        _bambooERC20.transferFrom(_msgSender(), address(this), _amount);
        GameSportLib.SportUserData storage sportUserDataTmp = sportUserData[currentSportBlockHeight][_tokenId];
        sportUserDataTmp.userAddress = _msgSender();
        sportUserDataTmp.tokenId = _tokenId;
        sportUserDataTmp.blockHeight = block.number;
        uint256 _goal = _deal(sportDataInfo, sportUserDataTmp,_amount, _tokenId);
        sportUserDataTmp.goal = _goal;


        //Update global information
        totalBalance += _amount;
        totalNFTCount++;

        //If the number of participating NFTs is met, liquidation will begin
        if (sportDataInfo.currentNFTCount >= maxNFTCount) {
            _liquidate(sportDataInfo);
        }
        return (sportUserDataTmp.attribute,currentSportBlockHeight);
    }

    /**
     * @dev Get the corresponding tokenId address in the specified game
     * @param _sportBlock Block height corresponding to the current game
     * @param _tokenId NFT tokenId
     */
    function getUserAddress(uint256 _sportBlock, uint256 _tokenId) public view returns (address){
        return sportUserData[_sportBlock][_tokenId].userAddress;
    }

    /**
     * @dev Get the corresponding tokenId attribute in the specified game
     * @param _sportBlock Block height corresponding to the current game
     * @param _tokenId NFT tokenId
     */
    function getUserAttribute(uint256 _sportBlock, uint256 _tokenId) public view returns (uint256[] memory attribute){
        return sportUserData[_sportBlock][_tokenId].attribute;
    }

    /**
     * @dev Get global configuration and current game properties
     **/
    function getConfig() public view
    returns (bool isActive_,
        uint256 maxNFTCount_,
        uint256 maxJoinTimePerUnitTime_,
        uint256 maxPerUnitTime_,
        uint256 ticketAmount_,
        uint256 lastGameBalance_,
        uint256 currentRaceBalance_,
        uint256 currentNFTCount_,
        uint256 firstTokenId_,
        uint256 secondTokenId_,
        uint256 thirdTokenId_,
        uint256 blockHeight_,
        uint256 currentSportBlockHeight_
    ){
        GameSportLib.SportData storage sportDataInfo = sportData[currentSportBlockHeight];
        return (isActive,
        maxNFTCount,
        maxJoinTimePerUnitTime,
        maxPerUnitTime,
        ticketAmount,
        sportDataInfo.lastGameBalance,
        sportDataInfo.currentRaceBalance,
        sportDataInfo.currentNFTCount,
        sportDataInfo.firstTokenId,
        sportDataInfo.secondTokenId,
        sportDataInfo.thirdTokenId,
        block.number,
        currentSportBlockHeight
        );
    }

    /**
     * @dev Get the user data participating in the game
     * @param _sportBlock  identification of the game
     */

    function getParticipateUser(uint256 _sportBlock) public view
    returns (uint256[] memory participateUser_){
        GameSportLib.SportData storage sportDataInfo = sportData[_sportBlock];
        return (sportDataInfo.participateUser);
    }



    /**
     * @dev Set global configuration
     * @param _flag isActive = true means the race has been activated and properly configured
     * @param _maxNFTCount Maximum number of NFTs per game
     * @param _maxJoinTimePerUnitTime  Number of game per unit time
     * @param _ticketAmount  Number of tickets to be paid for each parameter competition
     **/
    function setConfig(
        bool _flag,
        uint256 _maxNFTCount,
        uint256 _maxJoinTimePerUnitTime,
        uint256 _maxPerUnitTime,
        uint256 _ticketAmount
    ) public onlyOwner {
        isActive = _flag;
        maxNFTCount = _maxNFTCount;
        maxJoinTimePerUnitTime = _maxJoinTimePerUnitTime;
        maxPerUnitTime = _maxPerUnitTime;
        ticketAmount = _ticketAmount;
        emit BaseConfigUpdated(isActive, maxNFTCount, maxJoinTimePerUnitTime, maxPerUnitTime, ticketAmount);
    }

    function setDataProvider(address _addr) public isOperatorOrOwner {
        dataProvider = DataProvider(_addr);
        emit DataProviderUpdated(_addr);
    }

    function getDataProvider() public view returns (address) {
        return address(dataProvider);
    }

    /**
     * @dev Internal rewards
     * @param _awardBalance Internal reward balance
     * @param _userAddress user address
     */
    function _sendAward(
        uint256 _awardBalance,
        address _userAddress
    ) internal {
        IERC20 _bambooERC20 = IERC20(dataProvider.getTokenBambooAddress());
        _bambooERC20.transfer(_userAddress, _awardBalance);
    }

    /**
     * @dev Get random number
     **/
    function random(uint256 _salt, uint256 _baseNumber)
    internal
    view
    returns (uint256, uint256)
    {
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

    function _calculateAttribute(uint256 _originalValue, uint256 _maxValue, uint _len, bool _add)
    internal returns (uint256 _returnValue, uint256 _randomData){
        uint randomData;
        //Calculate random number
        (salt, randomData) = random(salt, _len);
        if (_add) {
            uint256 result = _originalValue + randomData;
            //The result cannot be higher than the current NFT attribute upper limit value
            if (result > _maxValue) {
                return (randomData, _maxValue);
            } else {
                return (randomData, result);
            }
        }
        else {
            //The result cannot be less than 0
            if (_originalValue > randomData) {
                return (randomData, _originalValue - randomData);
            } else {
                return (0, 0);
            }
        }
    }

    /**
     * @dev Liquidation
     * @param _sportDataInfo Mapping of game data
     */
    function _liquidate(GameSportLib.SportData storage _sportDataInfo) internal virtual {}

    /**
     * @dev Process user attribute calculation ranking
     * @param _sportDataInfo Mapping of game data
     */
    function _deal(GameSportLib.SportData storage _sportDataInfo,
        GameSportLib.SportUserData storage _sportUserData,
        uint256 _amount,
        uint256 _tokenId) internal virtual returns (uint256);

}