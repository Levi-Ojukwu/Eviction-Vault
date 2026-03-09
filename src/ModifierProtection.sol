// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ModifierProtection {
    mapping (address => bool) public isOwner;
    bool public paused;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier whenNotPaused {
        require(!paused, "Contract is paused");
        _;
    }
}