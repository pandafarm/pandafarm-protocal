//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../access/OperatorAccessControl.sol";
import "../tokenization/PandaFarm721.sol";
import "../tokenization/BambooERC20.sol";
import "../core/DataProvider.sol";
import "../libraries/GameSportLib.sol";
import "../libraries/GameSportUserLib.sol";
import "../libraries/GameMiningRewardLib.sol";
import "./BaseSportV1.sol";
import "./GameMiningRewardConfigV1.sol";


contract SportBigEaterV1 is BaseSportV1 {

    using GameSportUserLib for GameSportUserLib.GameSportUserData;
    using GameSportLib for GameSportLib.SportUserData;
    using GameSportLib for GameSportLib.SportData;
    using GameMiningRewardLib for GameMiningRewardLib.RewardData;

    event SportBigEaterAttributeUpdated(
        uint256 tokenId,
        uint256 exp,
        uint256 size,
        uint256 stamina,
        uint256 tooth,
        uint256 digestion);


    event SportBigEaterJoin(
        address indexed userAddress,
        uint256 tokenId,
        bool result);

    /**z
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name_,
        address dataProvider_,
        bool isActive_,
        uint256 ticketAmount_,
        uint maxJoinTimePerUnitTime_,
        uint256 maxNFTCount_
    ) BaseSportV1(name_, dataProvider_, isActive_, ticketAmount_, maxJoinTimePerUnitTime_, maxNFTCount_){
    }

    function _deal(
        GameSportLib.SportData storage _sportDataInfo,
        GameSportLib.SportUserData storage _sportUserData,
        uint256 _amount,
        uint256 _tokenId
    ) internal virtual override returns (uint256) {
        PandaFarm721 _bambooERC721 = PandaFarm721(dataProvider.getNftPandaAddress());
        //Get the NFT game attribute and judge whether there is competition
        uint256[] memory _attribute = _bambooERC721.getAttribute(_tokenId);
        uint256[] memory _attributeMax = _bambooERC721.getAttributeMax(_tokenId);

        _dealAttribute(_sportUserData, _tokenId, _attribute, _attributeMax, _bambooERC721);

        uint256 _goal = _calculateGoal(_attribute);

        _sportDataInfo.participateUser.push(_tokenId);
        _sportDataInfo.currentRaceBalance = _sportDataInfo.currentRaceBalance + _amount;
        _sportDataInfo.currentNFTCount = _sportDataInfo.currentNFTCount + 1;

        //first=99,second=90,third=80, goal=100 => first=100,second=99,third=90
        if (_goal > _sportDataInfo.firstGoal) {
            _sportDataInfo.thirdGoal = _sportDataInfo.secondGoal;
            _sportDataInfo.thirdTokenId = _sportDataInfo.secondTokenId;
            _sportDataInfo.secondGoal = _sportDataInfo.firstGoal;
            _sportDataInfo.secondTokenId = _sportDataInfo.firstTokenId;
            _sportDataInfo.firstGoal = _goal;
            _sportDataInfo.firstTokenId = _tokenId;
        } else if (_goal <= _sportDataInfo.firstGoal && _goal > _sportDataInfo.secondGoal) {
            //first=99,second=90,third=80, goal=99||goal=91||90 => first=99,second=99||91||90,third=90
            _sportDataInfo.thirdGoal = _sportDataInfo.secondGoal;
            _sportDataInfo.thirdTokenId = _sportDataInfo.secondTokenId;
            _sportDataInfo.secondGoal = _goal;
            _sportDataInfo.secondTokenId = _tokenId;
        } else if (_goal <= _sportDataInfo.secondGoal && _goal > _sportDataInfo.thirdGoal) {
            //first=99,second=90,third=80, goal=90||goal=91 => first=99,second=90,third=90||91
            _sportDataInfo.thirdGoal = _goal;
            _sportDataInfo.thirdTokenId = _tokenId;
        }
        return _goal;
    }

    /**
    * Calculate the user's game factor according to the user's game attributes
    */
    function _calculateGoal(uint256[] memory _attribute) internal returns (uint256){
        //0-exp 1-size 32-agility 3-strength 4-stamina 5-tooth 6-claw 7-digestion 8-sight 9-weather 10-winnerCount 11-bak
        //goal=(tooth*0.3+digestion*0.3+stamina*0.2+exp*0.2)*random(0.95,1.1)
        uint256 _tooth = _attribute[5] * 3 / 10;
        uint256 _digestion = _attribute[7] * 3 / 10;
        uint256 _stamina = _attribute[4] * 2 / 10;
        uint256 _exp = _attribute[0] * 2 / 10;
        //cal goal
        uint256 _goal = (_tooth + _digestion + _stamina + _exp);
        uint256 _randomGoal = 0;
        (salt, _randomGoal) = random(salt, 10);
        if (_randomGoal < 5) {
            _goal = _goal * (100 - _randomGoal) / 100;
        } else {
            _goal = _goal * (100 + _randomGoal) / 100;
        }
        return _goal;
    }


    function _dealAttribute(
        GameSportLib.SportUserData storage _sportUserData,
        uint256 _tokenId,
        uint256[] memory _attribute,
        uint256[] memory _attributeMax,
        PandaFarm721 _bambooERC721
    ) internal {
        //The result cannot be higher than the current NFT attribute upper limit value
        uint256 exp = _attribute[0];
        exp ++;
        if (exp >= _attributeMax[0]) {
            exp = _attributeMax[0];
        }
        _attribute[0] = exp;
        uint256 staminaRandom = 0;
        uint256 toothRandom = 0;
        uint256 digestionRandom = 0;
        uint256 sizeRandom = 0;
        (staminaRandom, _attribute[4]) = _calculateAttribute(_attribute[4], _attributeMax[4], 3, false);
        (toothRandom, _attribute[5]) = _calculateAttribute(_attribute[5], _attributeMax[5], 3, false);
        (digestionRandom, _attribute[7]) = _calculateAttribute(_attribute[7], _attributeMax[7], 3, false);
        (sizeRandom, _attribute[1]) = _calculateAttribute(_attribute[1], _attributeMax[4], 3, true);

        _sportUserData.attribute.push(1);
        _sportUserData.attribute.push(staminaRandom);
        _sportUserData.attribute.push(toothRandom);
        _sportUserData.attribute.push(digestionRandom);
        _sportUserData.attribute.push(sizeRandom);
        _bambooERC721.setAttribute(_tokenId, _attribute);

        emit SportBigEaterAttributeUpdated(_tokenId, 1, sizeRandom, staminaRandom, toothRandom, digestionRandom);
    }


    function _liquidate(GameSportLib.SportData storage _sportDataInfo) internal virtual override {

        uint256 firstTokenId = _sportDataInfo.firstTokenId;
        uint256 secondTokenId = _sportDataInfo.secondTokenId;
        uint256 thirdTokenId = _sportDataInfo.thirdTokenId;

        //Get the championship game attribute
        PandaFarm721 _PandaFarm721 = PandaFarm721(dataProvider.getNftPandaAddress());
        uint[] memory _attribute = _PandaFarm721.getAttribute(firstTokenId);
        _PandaFarm721.setAttributeByIndex(thirdTokenId, 10, _attribute[10] + 1);

        GameMiningRewardConfigV1 gameMiningRewardConfigV1 = GameMiningRewardConfigV1(dataProvider.getGameMiningRewardAddress());
        gameMiningRewardConfigV1.sendReward(address(this));

        IERC20 _bambooERC20 = IERC20(dataProvider.getTokenBambooAddress());
        uint256 currentRaceBalance = _bambooERC20.balanceOf(address(this));

        //Reward the third place
        uint firstBalance = currentRaceBalance * 50 / 100;
        uint sendBalance = currentRaceBalance * 30 / 100;
        uint thirdBalance = currentRaceBalance * 10 / 100;

        _sendAward(firstBalance, globalTokenId[firstTokenId].userAddress);
        _sendAward(sendBalance, globalTokenId[secondTokenId].userAddress);
        _sendAward(thirdBalance, globalTokenId[thirdTokenId].userAddress);

        _sportDataInfo.isComplete = true;
        currentSportBlockHeight += 1;

        sportData[currentSportBlockHeight].initSport(currentSportBlockHeight, _bambooERC20.balanceOf(address(this)));

        emit Liquidate(_sportDataInfo.startBlockHeight,
            globalTokenId[firstTokenId].userAddress,
            globalTokenId[firstTokenId].tokenId,
            firstBalance,
            1);
        emit Liquidate(_sportDataInfo.startBlockHeight,
            globalTokenId[secondTokenId].userAddress,
            globalTokenId[secondTokenId].tokenId,
            sendBalance,
            2);
        emit Liquidate(_sportDataInfo.startBlockHeight,
            globalTokenId[thirdTokenId].userAddress,
            globalTokenId[thirdTokenId].tokenId,
            thirdBalance,
            3);
    }

}