// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import "forge-std/Script.sol";
import "../src/PoWAttestor.sol";
import "../src/ProofBadge.sol";

/// @notice Deploy ProofBadge -> PoWAttestor -> wire badge.setAttestor(attestor).
/// @dev Usage (testnet):
///   forge script script/Deploy.s.sol --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 \
///     --private-key $DEPLOYER_KEY --broadcast
/// Mainnet:
///   forge script script/Deploy.s.sol --rpc-url https://bsc-dataseed.binance.org \
///     --private-key $DEPLOYER_KEY --broadcast --verify
/// Agent ID registry (mainnet, verified): 0x60b9262456de011f7d15a54cdd8c48baaa8b022f
contract Deploy is Script {
    address constant AGENT_ID_MAINNET = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;
    uint256 constant DIFFICULTY = 16; // starting point; adjustable by owner

    function run() external {
        vm.startBroadcast();
        ProofBadge badge = new ProofBadge(msg.sender);
        PoWAttestor attestor = new PoWAttestor(AGENT_ID_MAINNET, address(badge), DIFFICULTY, msg.sender);
        badge.setAttestor(address(attestor));
        vm.stopBroadcast();
        console.log("ProofBadge:     ", address(badge));
        console.log("PoWAttestor:    ", address(attestor));
        console.log("Agent ID (ext): ", AGENT_ID_MAINNET);
        console.log("Difficulty:     ", DIFFICULTY);
    }
}
