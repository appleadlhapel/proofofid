// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

interface IAgentID {
    function balanceOf(address owner) external view returns (uint256);
}

interface IBadge {
    function mintBadge(address user, uint256 dayNumber, uint256 nonce, uint256 difficulty) external;
}

/// @title PoWAttestor — verifies Agent ID holder + client-side nonce PoW + optional EIP-712 attestation
/// @notice One attestation per holder per day. Challenge = keccak256(holder, dayNumber).
/// @notice This contract holds no funds, mints nothing tradeable, and cannot transfer user assets.
/// @notice DRAFT for hackathon review. Not audited. Do not use with real funds before your own review.
contract PoWAttestor {
    IAgentID public immutable agentID;
    IBadge public immutable badge;
    address public owner;
    uint256 public difficulty; // leading zero bits required

    mapping(address => uint256) public lastDoneDay;   // user => dayNumber
    mapping(address => uint256) public streakOf;
    mapping(address => uint256) public proofsOf;

    event ProofAttested(address indexed user, uint256 dayNumber, uint256 nonce, uint256 difficulty, uint256 timestamp);
    event DifficultyUpdated(uint256 newDifficulty);

    bytes32 constant EIP712_DOMAIN = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 constant ATTEST_TYPEHASH = keccak256("Attest(address user,uint256 dayNumber,uint256 nonce,uint256 difficulty)");

    error NotAgentIDHolder(address user);
    error AlreadyDone(address user, uint256 day);
    error WeakProof(bytes32 digest, uint256 needed);
    error BadSignature(address signer);
    error InvalidDifficulty(uint256 d);
    error OnlyOwner(address caller);
    error ZeroOwner();

    constructor(address _agentID, address _badge, uint256 _difficulty, address _owner) {
        if (_difficulty == 0 || _difficulty > 32) revert InvalidDifficulty(_difficulty);
        if (_owner == address(0)) revert ZeroOwner();
        agentID = IAgentID(_agentID);
        badge = IBadge(_badge);
        difficulty = _difficulty;
        owner = _owner; // explicit: a CREATE2 factory deploy would make msg.sender the factory
    }

    function challengeOf(address user, uint256 dayNumber) public pure returns (bytes32) {
        return keccak256(abi.encode(user, dayNumber));
    }

    function leadingZeroBits(bytes32 h) public pure returns (uint256 n) {
        uint256 v = uint256(h);
        if (v == 0) return 256;
        while ((v >> 255) == 0) {
            n++;
            v <<= 1;
        }
    }

    /// @param dayNumber unix day (block.timestamp / 1 days) used by the frontend
    /// @param nonce the solution found by the client
    /// @param signature optional EIP-712 signature over Attest(user,dayNumber,nonce,difficulty); empty bytes = skip sig check (holder check still applies)
    function attest(uint256 dayNumber, uint256 nonce, bytes calldata signature) external {
        if (agentID.balanceOf(msg.sender) == 0) revert NotAgentIDHolder(msg.sender);
        if (lastDoneDay[msg.sender] >= dayNumber) revert AlreadyDone(msg.sender, dayNumber);

        bytes32 digest = keccak256(abi.encode(challengeOf(msg.sender, dayNumber), nonce));
        if (leadingZeroBits(digest) < difficulty) revert WeakProof(digest, difficulty);

        if (signature.length > 0) {
            bytes32 structHash = keccak256(abi.encode(ATTEST_TYPEHASH, msg.sender, dayNumber, nonce, difficulty));
            bytes32 domainSep = keccak256(abi.encode(EIP712_DOMAIN, keccak256("ProofofID"), keccak256("1"), block.chainid, address(this)));
            bytes32 ethDigest = keccak256(abi.encodePacked("\x19\x01", domainSep, structHash));
            (bytes32 r, bytes32 s, uint8 v) = _splitSig(signature);
            // reject malleable / invalid signatures
            if (v != 27 && v != 28) revert BadSignature(address(0));
            if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) revert BadSignature(address(0));
            address signer = ecrecover(ethDigest, v, r, s);
            if (signer != msg.sender) revert BadSignature(signer);
        }

        uint256 prev = lastDoneDay[msg.sender];
        lastDoneDay[msg.sender] = dayNumber;
        streakOf[msg.sender] = (prev + 1 == dayNumber) ? streakOf[msg.sender] + 1 : 1;
        proofsOf[msg.sender] += 1;

        emit ProofAttested(msg.sender, dayNumber, nonce, difficulty, block.timestamp);
        badge.mintBadge(msg.sender, dayNumber, nonce, difficulty);
    }

    function setDifficulty(uint256 d) external {
        if (msg.sender != owner) revert OnlyOwner(msg.sender);
        if (d == 0 || d > 32) revert InvalidDifficulty(d);
        difficulty = d;
        emit DifficultyUpdated(d);
    }

    function _splitSig(bytes calldata sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "bad sig");
        assembly {
            r := calldataload(add(sig.offset, 0))
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }
    }
}
