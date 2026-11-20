// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title ProofBadge — soulbound ERC-721 proof-of-work badge
/// @notice Transfers and approvals are intentionally disabled. No token economics.
/// @notice DRAFT for hackathon review. Not audited.
contract ProofBadge is ERC721 {
    address public attestor;
    address public owner;
    string public baseURIValue;

    error OnlyAttestor();
    error OnlyOwner();
    error Soulbound();
    error ZeroOwner();
    mapping(address => uint256) public tokenOf; // user => tokenId (one badge per holder)
    mapping(uint256 => uint256) public lastDay;
    mapping(uint256 => uint256) public lastNonce;
    uint256 private _nextId = 1;

    event BadgeMinted(address indexed user, uint256 tokenId, uint256 dayNumber, uint256 nonce);
    event BadgeUpdated(address indexed user, uint256 tokenId, uint256 dayNumber, uint256 nonce);

    /// @param initialOwner the EOA that owns the badge (admin: setAttestor once, setBaseURI).
    /// @dev Must be explicit: when deployed via a CREATE2 factory, msg.sender is the
    /// factory, not the deployer — passing the owner keeps admin rights with the deployer.
    constructor(address initialOwner) ERC721("ProofofID Proof Badge", "POF") {
        if (initialOwner == address(0)) revert ZeroOwner();
        attestor = initialOwner;
        owner = initialOwner;
    }

    /// @notice One-time wiring: point minting rights at the PoWAttestor. Owner-only, callable once.
    function setAttestor(address a) external {
        if (msg.sender != owner) revert OnlyOwner();
        if (attestor != owner) revert OnlyAttestor(); // already wired
        attestor = a;
    }

    function mintBadge(address user, uint256 dayNumber, uint256 nonce, uint256 /*difficulty*/) external {
        if (msg.sender != attestor) revert OnlyAttestor();
        uint256 id = tokenOf[user];
        if (id == 0) {
            id = _nextId++;
            tokenOf[user] = id;
            _safeMint(user, id);
            emit BadgeMinted(user, id, dayNumber, nonce);
        } else {
            emit BadgeUpdated(user, id, dayNumber, nonce);
        }
        lastDay[id] = dayNumber;
        lastNonce[id] = nonce;
    }

    function setBaseURI(string calldata uri) external {
        if (msg.sender != owner) revert OnlyOwner();
        baseURIValue = uri;
    }

    function _baseURI() internal view override returns (string memory) { return baseURIValue; }

    // Soulbound: all transfers and approvals revert (OpenZeppelin v5 hook)
    function _update(address to, uint256 tokenId, address auth)
        internal
        override
        returns (address)
    {
        if (to != address(0) && auth != address(0)) revert Soulbound();
        return super._update(to, tokenId, auth);
    }

    function approve(address, uint256) public pure override { revert Soulbound(); }
    function setApprovalForAll(address, bool) public pure override { revert Soulbound(); }
}
