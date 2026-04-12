// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAaveV4Pool {
    function deposit(address asset, uint256 amount, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external;
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract CheckMatezVault is ReentrancyGuard {
    using ECDSA for bytes32;

    address public oracleAddress;
    mapping(bytes32 => bool) public usedSignatures;
    IAaveV4Pool public aavePool;
    IWETH public weth;

    event FastTrackUnlock(uint256 indexed tokenId, uint256 nonce);
    event OracleAddressUpdated(address indexed newOracle);
    event YieldHarvested(uint256 amount);

    constructor(address _oracleAddress, address _aavePool, address _weth) {
        oracleAddress = _oracleAddress;
        aavePool = IAaveV4Pool(_aavePool);
        weth = IWETH(_weth);
    }

    function triggerFastTrackUnlock(uint256 tokenId, uint256 nonce, bytes calldata signature) external {
        bytes32 message = keccak256(abi.encodePacked(tokenId, nonce));
        require(!usedSignatures[message], "Signature already used");
        require(verifySignature(message, signature), "Invalid signature");

        usedSignatures[message] = true;
        emit FastTrackUnlock(tokenId, nonce);
    }

    function verifySignature(bytes32 message, bytes calldata signature) public view returns (bool) {
        return oracleAddress == message.toEthSignedMessageHash().recover(signature);
    }

    function setOracleAddress(address newOracle) external { // Add access control (e.g. only owner)
        oracleAddress = newOracle;
        emit OracleAddressUpdated(newOracle);
    }

    function canWithdraw() external view returns (bool) {
        // Implement withdrawal logic
        return true; // Placeholder
    }

    function harvestYield() external nonReentrant {
        // Logic to harvest yield from the Aave pool
        uint256 balance = address(this).balance;
        if (balance > 0) {
            aavePool.deposit{value: balance}(address(weth), balance, 0);
            emit YieldHarvested(balance);
        }
    }

    receive() external payable {
        if (msg.value > 0) {
            weth.deposit{value: msg.value}();
        }
    }
}