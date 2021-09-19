//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../access/OperatorAccessControl.sol";
import "../libraries/UtilLib.sol";

/**
* @title DataProvider contract
* @author PandaFarm
**/
contract DataProvider is OperatorAccessControl {

    //Erc20 contract address of the platform
    address private tokenBambooAddress;
    //Erc20 contract address of the
    address private tokenBambooShootAddress;
    //NFT contract address of the panda
    address private nftPandaAddress;
    //NFT contract address of the land
    address private nftLandAddress;
    //Incentive mining contract
    address private gameMiningRewardAddress;
    //Incentive mining contract
    address private oracleAddress;
    //Platform Fee Address
    address private platformFeeAddress;

    event DataProviderAddressUpdated(address indexed _addr, uint256 _type);

    function setGameMiningRewardAddress(address _addr) public isOperatorOrOwner {
        gameMiningRewardAddress = _addr;
        emit DataProviderAddressUpdated(_addr, 1);
    }

    function getGameMiningRewardAddress() public view returns (address) {
        return gameMiningRewardAddress;
    }

    function setTokenBambooAddress(address _addr) public isOperatorOrOwner {
        tokenBambooAddress = _addr;
        emit DataProviderAddressUpdated(_addr, 2);
    }

    function getTokenBambooAddress() public view returns (address) {
        return tokenBambooAddress;
    }

    function setTokenBambooShootAddress(address _addr) public isOperatorOrOwner {
        tokenBambooShootAddress = _addr;
        emit DataProviderAddressUpdated(_addr, 3);
    }

    function getTokenBambooShootAddress() public view returns (address) {
        return tokenBambooShootAddress;
    }

    function setNftPandaAddress(address _addr) public isOperatorOrOwner {
        nftPandaAddress = _addr;
        emit DataProviderAddressUpdated(_addr, 4);
    }

    function getNftPandaAddress() public view returns (address) {
        return nftPandaAddress;
    }


    function setNftLandAddress(address _addr) public isOperatorOrOwner {
        nftLandAddress = _addr;
        emit DataProviderAddressUpdated(_addr, 5);
    }

    function getNftLandAddress() public view returns (address) {
        return nftLandAddress;
    }

    function setOracleAddress(address _addr) public isOperatorOrOwner {
        oracleAddress = _addr;
        emit DataProviderAddressUpdated(_addr, 6);
    }

    function getOracleAddress() public view returns (address) {
        return oracleAddress;
    }

    function setPlatformFeeAddress(address _addr) public isOperatorOrOwner {
        platformFeeAddress = _addr;
        emit DataProviderAddressUpdated(_addr, 7);
    }

    function getPlatformFeeAddress() public view returns (address) {
        return platformFeeAddress;
    }

}
