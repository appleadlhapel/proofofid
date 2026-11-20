// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import "forge-std/Test.sol";
import "../src/PoWAttestor.sol";
import "../src/ProofBadge.sol";
import "./mocks/MockAgentID.sol";

contract PoWAttestorTest is Test {
    MockAgentID mockID;
    ProofBadge badge;
    PoWAttestor attestor;

    uint256 pkAlice = 0xA11CE11CE11CE11CE11CE11CE11CE11CE11CE11CE11CE11CE11CE11CE11CE;
    uint256 pkBob = 0xB0BB0BB0BB0BB0BB0BB0BB0BB0BB0BB0BB0BB0BB0BB0BB0BB0BB0BB0BF;
    address alice;
    address bob;

    uint256 constant DIFF = 6; // low for tests

    function setUp() public {
        vm.warp(1_700_000_000); // realistic timestamp so dayNumber > 0
        mockID = new MockAgentID();
        badge = new ProofBadge(address(this));
        attestor = new PoWAttestor(address(mockID), address(badge), DIFF, address(this));
        badge.setAttestor(address(attestor)); // one-time wiring
        alice = vm.addr(pkAlice);
        bob = vm.addr(pkBob);
        mockID.mint(alice);
        mockID.mint(bob);
    }

    function solve(address user, uint256 day) internal view returns (uint256 nonce) {
        bytes32 ch = attestor.challengeOf(user, day);
        nonce = 0;
        while (true) {
            if (attestor.leadingZeroBits(keccak256(abi.encode(ch, nonce))) >= DIFF) return nonce;
            nonce++;
        }
    }

    function test_leadingZeroBits_allZero() public view {
        assertEq(attestor.leadingZeroBits(bytes32(0)), 256);
    }

    function test_leadingZeroBits_known() public view {
        bytes32 h = bytes32(uint256(2**252)); // 0x1 followed by zeros -> 3 leading zero bits
        assertGe(attestor.leadingZeroBits(h), 3);
        bytes32 h2 = bytes32(uint256(2**255)); // 0x8 followed by zeros -> 0 leading zero bits
        assertEq(attestor.leadingZeroBits(h2), 0);
    }

    function test_attest_nonHolderReverts() public {
        address stranger = address(0x57A9);
        uint256 day = block.timestamp / 1 days;
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(PoWAttestor.NotAgentIDHolder.selector, stranger));
        attestor.attest(day, 0, "");
    }

    function test_attest_weakProofReverts() public {
        uint256 day = block.timestamp / 1 days;
        bytes32 ch = attestor.challengeOf(alice, day);
        uint256 weak;
        for (weak = 0; weak < 10000; weak++) {
            if (attestor.leadingZeroBits(keccak256(abi.encode(ch, weak))) < DIFF) break;
        }
        bytes32 weakDigest = keccak256(abi.encode(ch, weak));
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(PoWAttestor.WeakProof.selector, weakDigest, DIFF));
        attestor.attest(day, weak, "");
    }

    function test_happyPath_mintsBadge() public {
        uint256 day = block.timestamp / 1 days;
        uint256 nonce = solve(alice, day);
        vm.prank(alice);
        attestor.attest(day, nonce, "");
        assertEq(attestor.proofsOf(alice), 1);
        assertEq(attestor.streakOf(alice), 1);
        assertEq(attestor.lastDoneDay(alice), day);
        uint256 id = badge.tokenOf(alice);
        assertTrue(id != 0);
        assertEq(badge.ownerOf(id), alice);
    }

    function test_doubleClaimReverts() public {
        uint256 day = block.timestamp / 1 days;
        uint256 nonce = solve(alice, day);
        vm.startPrank(alice);
        attestor.attest(day, nonce, "");
        vm.expectRevert(abi.encodeWithSelector(PoWAttestor.AlreadyDone.selector, alice, day));
        attestor.attest(day, nonce, "");
        vm.stopPrank();
    }

    function test_streakIncrementsNextDay() public {
        uint256 day = block.timestamp / 1 days;
        uint256 n1 = solve(alice, day);
        vm.prank(alice);
        attestor.attest(day, n1, "");
        uint256 n2 = solve(alice, day + 1);
        vm.prank(alice);
        attestor.attest(day + 1, n2, "");
        assertEq(attestor.streakOf(alice), 2);
        assertEq(attestor.proofsOf(alice), 2);
    }

    function test_badge_soulbound() public {
        uint256 day = block.timestamp / 1 days;
        uint256 n1 = solve(alice, day);
        vm.prank(alice);
        attestor.attest(day, n1, "");
        uint256 id = badge.tokenOf(alice);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ProofBadge.Soulbound.selector));
        badge.transferFrom(alice, bob, id);
    }

    function test_badge_onlyAttestorMints() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(ProofBadge.OnlyAttestor.selector));
        badge.mintBadge(bob, 1, 1, DIFF);
    }

    function test_eip712_validSigAccepted() public {
        uint256 day = block.timestamp / 1 days;
        uint256 nonce = solve(alice, day);
        // sign via vm.sign over the same digest the contract recomputes
        bytes32 structHash = keccak256(abi.encode(
            keccak256("Attest(address user,uint256 dayNumber,uint256 nonce,uint256 difficulty)"),
            alice, day, nonce, DIFF
        ));
        bytes32 domainSep = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("ProofofID"), keccak256("1"), block.chainid, address(attestor)
        ));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSep, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pkAlice, digest);
        bytes memory sig = abi.encodePacked(r, s, v); // vm.sign already returns 27/28

        vm.prank(alice);
        attestor.attest(day, nonce, sig);
        assertEq(attestor.proofsOf(alice), 1);
    }

    function test_eip712_wrongSignerReverts() public {
        uint256 day = block.timestamp / 1 days;
        uint256 nonce = solve(alice, day);
        bytes32 structHash = keccak256(abi.encode(
            keccak256("Attest(address user,uint256 dayNumber,uint256 nonce,uint256 difficulty)"),
            alice, day, nonce, DIFF
        ));
        bytes32 domainSep = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("ProofofID"), keccak256("1"), block.chainid, address(attestor)
        ));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSep, structHash));
        // bob signs an attestation alice tries to submit
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pkBob, digest);
        bytes memory sig = abi.encodePacked(r, s, v);
        vm.prank(alice);
        vm.expectRevert();
        attestor.attest(day, nonce, sig);
    }

    function test_setDifficulty_onlyOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        attestor.setDifficulty(9);
        attestor.setDifficulty(9);
        assertEq(attestor.difficulty(), 9);
    }

    function test_constructor_rejectsBadDifficulty() public {
        vm.expectRevert(abi.encodeWithSelector(PoWAttestor.InvalidDifficulty.selector, 0));
        new PoWAttestor(address(mockID), address(badge), 0, address(this));
        vm.expectRevert(abi.encodeWithSelector(PoWAttestor.InvalidDifficulty.selector, 33));
        new PoWAttestor(address(mockID), address(badge), 33, address(this));
    }

    function test_factoryDeploy_ownerIsNotFactory() public {
        // Simulate a CREATE2 factory deploy: msg.sender is the factory, but the
        // explicit owner param must keep admin rights with the real deployer.
        address factory = address(0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7);
        vm.prank(factory);
        ProofBadge fb = new ProofBadge(address(this));
        assertEq(fb.owner(), address(this));
        assertEq(fb.attestor(), address(this));
        // wiring still works from the real owner (would be dead if owner were the factory)
        fb.setAttestor(address(attestor));
        assertEq(fb.attestor(), address(attestor));

        vm.prank(factory);
        PoWAttestor fa = new PoWAttestor(address(mockID), address(fb), DIFF, address(this));
        assertEq(fa.owner(), address(this));
        fa.setDifficulty(9); // owner call succeeds
        assertEq(fa.difficulty(), 9);
        vm.prank(alice);
        vm.expectRevert();
        fa.setDifficulty(10);
    }
}
