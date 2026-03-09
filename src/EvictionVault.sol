// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Vault.sol";
import "./MultiSig.sol";
import "./Merkle.sol";

contract EvictionVault is Vault, Multisig, Merkle {

    constructor(address[] memory _owners, uint256 _threshold) payable {

        require(_owners.length > 0, "No owners");
        require(_threshold > 0, "Invalid threshold");

        threshold = _threshold;

        for (uint i = 0; i < _owners.length; i++) {

            address owner = _owners[i];

            require(owner != address(0), "Invalid owner");

            isOwner[owner] = true;
        }

        totalVaultValue = msg.value;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function emergencyWithdrawAll() external onlyOwner {

        uint256 balance = address(this).balance;

        (bool success,) = payable(msg.sender).call{value: balance}("");
        require(success, "Transfer failed");

        totalVaultValue = 0;
    }
}