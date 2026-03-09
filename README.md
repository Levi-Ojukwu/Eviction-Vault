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
Original: require(block.timestamp >= txn.executionTime)
Problem:  When executionTime == 0 (threshold not met), this is always true.
          Any partially-confirmed transaction executes immediately.
Fix:      Added require(txn.executionTime != 0, "Timelock not started") first.

### 6. Single-hash Merkle leaf — second preimage attack (HIGH)
This was NOT fixed in the provided refactor.
Original: keccak256(abi.encodePacked(msg.sender, amount))
Problem:  OZ MerkleProof hashes node pairs the same way. An attacker can pass an
          internal tree node as a leaf, bypassing the proof entirely.
Fix:      keccak256(bytes.concat(keccak256(abi.encodePacked(msg.sender, amount))))
          Double-hashing makes leaves structurally distinct from internal nodes.
Note:     Off-chain Merkle tree generation must also double-hash leaves to match.

---

## Additional Fixes Not in Provided Solution

| Issue                                          | Fix                                          |
|------------------------------------------------|----------------------------------------------|
| threshold > ownerCount allowed in constructor  | require(_threshold <= _owners.length)        |
| Duplicate owners not checked in constructor    | require(!isOwner[owner], "Duplicate owner")  |
| Constructor ETH untracked in balances[]        | Credits balances[msg.sender] for msg.value   |
| totalVaultValue not decremented in claim()     | Deducted before external call (CEI)          |
| pause not enforced in submitTransaction()      | Added whenNotPaused                          |
| pause not enforced in confirmTransaction()     | Added whenNotPaused                          |
| MerkleProof.recover() does not exist           | Function removed; use OZ ECDSA if needed     |
| ownerCount not tracked after split             | Added ownerCount to SecurityModifiers        |

---

## Security Patterns Used

Checks-Effects-Interactions (CEI):
  All state changes happen before external calls.
  No ReentrancyGuard needed — the pattern itself prevents reentrancy.

Modifier centralisation:
  onlyOwner and whenNotPaused defined once in SecurityModifiers,
  inherited by all modules — no copy-paste drift possible.

Double-hash Merkle leaves:
  Prevents second preimage attacks against OZ MerkleProof library.

.call() over .transfer():
  Future-proof ETH forwarding compatible with smart-contract receivers.

