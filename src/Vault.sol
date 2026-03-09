// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ModifierProtection.sol";

contract Vault is ModifierProtection {
    mapping (address => uint256) public balances;
    uint256 public totalVaultValue;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);

    function deposit () external payable {
        require (msg.sender != address(0), "Address zero detected");

        require (msg.value > 0, "Deposit must be greater than 0");

        balances[msg.sender] += msg.value;

        totalVaultValue += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external whenNotPaused {
        require (msg.sender != address(0), "Address zero detected");

        require (amount > 0, "Withdrawal must be greater than 0");

        require (balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        totalVaultValue -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");

        require (success, "Withdrawal failed");

        emit Withdrawal(msg.sender, amount);
    }

    receive() external payable {
        require (msg.value > 0, "Deposit must be greater than 0");

        balances[msg.sender] += msg.value;

        totalVaultValue += msg.value;

        emit Deposit(msg.sender, msg.value);
    } 
}