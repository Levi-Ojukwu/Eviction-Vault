# EvictionVault — Security Refactor

**Task:** Structural refactor + critical vulnerability mitigation

---

## Vulnerabilities Fixed

### 1. setMerkleRoot callable by anyone (CRITICAL)
Originally no access control. Anyone could replace the Merkle root mid-distribution.
Also, attacker sets a root where every address can claim the entire vault.

Fix:  Added onlyOwner modifier, so only the owner can set the merkle root.

### 2. emergencyWithdrawAll public drain (CRITICAL)
This also had no access control. Due to that, any address could drain 100% of vault funds instantly.

Fix: Added onlyOwner modifier.

### 3. receive() used tx.origin (HIGH)
Originally the balances used [tx.origin] += msg.value
Malicious contract tricks victim. tx.origin is victim but msg.sender is
          attacker's contract — credits go to the wrong address.

Fix: Replaced with msg.sender throughout.

### 4. .transfer() in withdraw() and claim() (HIGH)
The contract used payable(msg.sender).transfer(amount)
And .transfer() forwards only 2,300 gas. , smart-contract
          
Fix:  (bool success,) = payable(msg.sender).call{value: amount}("");
      require(success, "Transfer failed");

### 5. Timelock bypass — executionTime could be 0 (MEDIUM)
 require(block.timestamp >= txn.executionTime)
Problem:  When executionTime == 0 (threshold not met), this is always true.
          Any partially-confirmed transaction executes immediately.
Fix:      Added require(txn.executionTime != 0, "Timelock not started") first.

### 6. Single-hash Merkle leaf — second preimage attack (HIGH)

Problem:  OZ MerkleProof hashes node pairs the same way. An attacker can pass an
          internal tree node as a leaf, bypassing the proof entirely.
Fix:      keccak256(bytes.concat(keccak256(abi.encodePacked(msg.sender, amount))))
          Double-hashing makes leaves structurally distinct from internal nodes.
Note:     Off-chain Merkle tree generation must also double-hash leaves to match.


