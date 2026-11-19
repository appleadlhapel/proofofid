# ProofofID

A free, non-custodial dApp on BNB Chain that issues a non-transferable Proof-of-Work badge to Binance Agent ID holders. Each day a holder proves real client-side computation (nonce PoW), signs an EIP-712 attestation, and anchors it on-chain through `PoWAttestor`. Agent ID is the identity gate: the contract checks `AgentID.balanceOf(msg.sender) > 0` before any attestation is accepted. Active daily check-ins earn eligibility for a future $NOR distribution (see `docs/TOKENOMICS.md`; $NOR is not deployed yet).

Built for the Agent ID Hackathon (Binance Wallet x BNB Chain): https://www.binance.com/en/support/announcement/detail/95f5dbe0ea674a48a739b59e046648bf

## Status (jujur)

- Terverifikasi: 14/14 unit test Foundry lolos (`forge test`), kontrak terkompilasi dengan solc 0.8.31, optimizer 200 runs, evm osaka.
- Sudah dilakukan: deploy mainnet (ProofBadge `0x1c4c510B43Ef96189A4b0777202D1E85367Ba717`, PoWAttestor `0x80F0c0Dd369C073E8C780c55B7F86Cb622474992`), verifikasi BscScan (Sourcify exact_match + Etherscan V2 API confirmed), hosting GitHub Pages https://appleadlhapel.github.io/proofofid/, attest() live terbukti (badge #1 untuk argh.ai).
- BELUM dilakukan: 30+ interaksi Agent ID, video demo, submit formulir.
- Belum diaudit. Jangan sebut "audited"/"perfect". Ini draft yang sudah diuji unit test.
- Detail lengkap: `docs/DEPLOY.md` (langkah ready-to-run) dan `docs/CHECKLIST.md`.

## Why

"PoW proves an agent ran. Agent ID proves who it belongs to." ProofofID turns that into a portable, soulbound proof-of-work record with no live token yet and no promises: $NOR is a planned future reward for active daily check-ins (see `docs/TOKENOMICS.md`), with no price or return promised.

## How it works

1. Connect a wallet. The dApp checks Agent ID balance via `0x60b9262456de011f7d15a54cdd8c48baaa8b022f` (SPACE ID Agent ID, ERC-721, non-transferable).
2. Get today's challenge: `keccak256(your address, day number)`.
3. Solve nonce PoW in your browser (difficulty stored on-chain, starting point 16 leading zero bits).
4. Sign an EIP-712 attestation (supported by Agentic Wallet; plain-text signing is not).
5. Call `attest()` on-chain. The contract re-verifies the PoW, marks the day done, bumps your streak, and mints/updates your soulbound badge.

## Contracts

- `contracts/src/PoWAttestor.sol` — verifies Agent ID holder status, PoW solution, optional EIP-712 signature; streaks and day tracking; emits `ProofAttested`.
- `contracts/src/ProofBadge.sol` — soulbound ERC-721 (OpenZeppelin v5). Transfers and approvals revert.
- Owner permissions (documented per hackathon rules): `setDifficulty` (attestor), `setBaseURI` + one-time `setAttestor` wiring (badge). No mint function outside `attest()`, no pause, no fund custody, no live token yet (see $NOR tokenomics in `docs/TOKENOMICS.md`).
- Tests: `contracts/test/PoWAttestor.t.sol` (14 tests, mock Agent ID). Deploy script: `contracts/script/Deploy.s.sol`.

## Run

```bash
cd contracts
forge install OpenZeppelin/openzeppelin-contracts --no-git
forge install foundry-rs/forge-std --no-git
forge build && forge test        # harus 14 passed
# deploy + verify: lihat docs/DEPLOY.md (testnet dulu, lalu mainnet)
cd ../frontend
# isi CONFIG.attestor/CONFIG.badge di index.html setelah deploy
python3 -m http.server 8000     # atau npx vercel deploy --prod
```

## Safety

- This app never asks for seed phrases, private keys, pairing codes, or QR logins. It never moves your funds. It has no live token yet and promises no returns; $NOR is a planned future reward for active daily check-ins, with no price or return promised.
- Agentic Wallet users: custom contract calls require Developer Mode (Binance App only, time-boxed, separate daily limit). EIP-712 signing works without it.
- Agent ID lookup of other people is intentionally NOT provided.

## Hackathon mapping

- Pioneer (on-chain activity): every real `attest()` call from an Agent ID holder counts; one per day per address keeps it organic.
- Innovation (depth 30% / practicality 25% / completion 25% / innovation 20%): Agent ID is the contract-level gate and identity record; the product solves a real agent-accountability need; 2 contracts + 1-page dApp shipped live; PoW x identity is a new primitive.
- Community Promotion (2,000 USDC, terpisah): postingan X dengan hashtag resmi. Template di `docs/SOCIAL.md`.

## Verified vs stubbed

- Terverifikasi dari sumber resmi: aturan hackathon + daftar reward (60,000 USDC; Pioneer 29k; Innovation 29k dengan syarat 30+ alamat; Community 2,000), alamat kontrak Agent ID `0x60b9262456de011f7d15a54cdd8c48baaa8b022f` + cek `balanceOf > 0`, Agentic Wallet hanya EIP-712 + Developer Mode untuk custom call, sumber: pengumuman Binance https://www.binance.com/en/support/announcement/detail/95f5dbe0ea674a48a739b59e046648bf dan https://web3.binance.com/en/dev-docs/products/agentic-wallet/introduction
- Stub/demo: frontend mode demo (tombol submit tidak kirim tx sampai `CONFIG.attestor` diisi) sudah tidak berlaku — CONFIG sudah terisi alamat live dan `deployed: true`; belum ada leaderboard/indexer. URL publik: https://appleadlhapel.github.io/proofofid/
