// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EvictionVault.sol";

contract EvictionVaultTest is Test {

    EvictionVault public vault;

    address public owner1 = makeAddr("owner1");
    address public owner2 = makeAddr("owner2");
    address public owner3 = makeAddr("owner3");
    address public user   = makeAddr("user");

    uint256 public constant THRESHOLD    = 2;
    uint256 public constant INITIAL_ETH  = 10 ether;

    function setUp() public {
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        vm.deal(address(this), 100 ether);
        vm.deal(user,           10 ether);
        vm.deal(owner1,         10 ether);

        vault = new EvictionVault{value: INITIAL_ETH}(owners, THRESHOLD);
    }


    function test_DepositAndWithdraw_HappyPath() public {

        uint256 depositAmount   = 1 ether;
        uint256 userBalanceBefore = user.balance;

        vm.prank(user);
        vault.deposit{value: depositAmount}();

        assertEq(vault.balances(user), depositAmount);
        assertEq(vault.totalVaultValue(), INITIAL_ETH + depositAmount);

        vm.prank(user);
        vault.withdraw(depositAmount);

        assertEq(vault.balances(user), 0);
        assertEq(user.balance, userBalanceBefore);
    }


    function test_PauseAndUnpause_BlocksWithdraw() public {

        vm.prank(user);
        vault.deposit{value: 1 ether}();

        vm.prank(owner1);
        vault.pause();
        assertTrue(vault.paused());

        vm.prank(user);
        vm.expectRevert("Contract is paused");
        vault.withdraw(1 ether);

        vm.prank(owner1);
        vault.unpause();
        assertFalse(vault.paused());

        vm.prank(user);
        vault.withdraw(1 ether);
        assertEq(vault.balances(user), 0);
    }


    function test_MultiSig_FullFlow() public {

        address payable recipient = payable(makeAddr("recipient"));

        vm.prank(owner1);
        vault.submitTransaction(recipient, 1 ether, "");

        vm.prank(owner2);
        vault.confirmTransaction(0);

        (,,,, uint256 confirmations,, uint256 execTime) = vault.transactions(0);

        assertEq(confirmations, 2);
        assertGt(execTime, 0);

        vm.warp(execTime + 1);

        uint256 recipientBefore = recipient.balance;
        vault.executeTransaction(0);

        assertEq(recipient.balance, recipientBefore + 1 ether);
        (,,, bool executedAfter,,,) = vault.transactions(0);
        assertTrue(executedAfter);
    }

   
    function test_SetMerkleRoot_OnlyOwner() public {

        bytes32 root = keccak256("test-root");

        vm.prank(user);
        vm.expectRevert("Not an owner");
        vault.setMerkleRoot(root);

        vm.prank(owner1);
        vault.setMerkleRoot(root);
        assertEq(vault.merkleRoot(), root);
    }


    // function test_MerkleClaim_ValidProof() public {

    //     uint256 claimAmount = 1 ether;

    //     bytes32 leaf0 = keccak256(bytes.concat(keccak256(abi.encodePacked(user,   claimAmount))));
    //     bytes32 leaf1 = keccak256(bytes.concat(keccak256(abi.encodePacked(owner3, 2 ether))));

    //     bytes32 root;
    //     bytes32[] memory proof = new bytes32[](1);

    //     if (leaf0 < leaf1) {
    //         root     = keccak256(abi.encodePacked(leaf0, leaf1));
    //         proof[0] = leaf1;
    //     } else {
    //         root     = keccak256(abi.encodePacked(leaf1, leaf0));
    //         proof[0] = leaf1;
    //     }

    //     vm.prank(owner1);
    //     vault.setMerkleRoot(root);

    //     uint256 userBefore       = user.balance;
    //     uint256 vaultValueBefore = vault.totalVaultValue();

    //     vm.prank(user);
    //     vault.claim(proof, claimAmount);

    //     assertEq(user.balance, userBefore + claimAmount);
    //     assertTrue(vault.claimed(user));
    //     assertEq(vault.totalVaultValue(), vaultValueBefore - claimAmount);

    //     // Replay must fail
    //     vm.prank(user);
    //     vm.expectRevert("Already claimed");
    //     vault.claim(proof, claimAmount);
    // }

  
    // function test_EmergencyWithdrawAll_OnlyOwner() public {

    //     vm.prank(user);
    //     vm.expectRevert("Not an owner");
    //     vault.emergencyWithdrawAll();

    //     uint256 owner1Before = owner1.balance;
    //     uint256 vaultBalance = address(vault).balance;

    //     vm.prank(owner1);
    //     vault.emergencyWithdrawAll();

    //     assertEq(address(vault).balance, 0);
    //     assertEq(vault.totalVaultValue(), 0);
    //     assertEq(owner1.balance, owner1Before + vaultBalance);
    // }
}