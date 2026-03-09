// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./ModifierProtection.sol";

contract Multisig is ModifierProtection {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 submissionTime;
        uint256 executionTime;
    }

    uint256 public threshold;
    uint256 public txCount;

    uint256 public constant TIMELOCK_DURATION = 1 hours;

    mapping(uint256 => mapping(address => bool)) public confirmed;
    mapping(uint256 => Transaction) public transactions;

    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId); 

    function submitTransaction(address _to, uint256 _value, bytes calldata _data) external onlyOwner {
        
        uint256 id = txCount++;

        transactions[id] = Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: 0
        });

        confirmed[id][msg.sender] = true;

        emit Submission(id);
    }

    function confirmTransaction(uint256 txId) external onlyOwner {

        Transaction storage txn = transactions[txId];

        require(!txn.executed, "Already executed");

        require(!confirmed[txId][msg.sender], "Already confirmed");

        confirmed[txId][msg.sender] = true;

        txn.confirmations++;

        if (txn.confirmations >= threshold) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }

        emit Confirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external {

        Transaction storage txn = transactions[txId];

        require(txn.confirmations >= threshold, "Not enough confirmations");

        require(!txn.executed, "Already executed");

        require(txn.executionTime != 0, "Timelock not started");
        
        require(block.timestamp >= txn.executionTime, "Timelock active");

        txn.executed = true;

        (bool success,) = txn.to.call{value: txn.value}(txn.data);
        require(success, "Execution failed");

        emit Execution(txId);
    }
}