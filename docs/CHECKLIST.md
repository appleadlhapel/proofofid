# Build / test / deploy / verify / submit checklist

## Selesai (file lokal, belum deploy)
- [x] Kontrak ditulis + tested: PoWAttestor + ProofBadge soulbound
- [x] Frontend satu file: wallet, PoW worker, EIP-712, share link
- [x] docs/DEPLOY.md + docs/SOCIAL.md siap pakai
- [ ] Review preview lokal frontend sebelum deploy (python http.server)

## Contracts (foundry)
- [x] forge build
- [x] forge test (test holder flow, non-holder revert, double-claim revert, weak-proof revert, bad-signature revert, soulbound transfer revert) — hasil: 13 passed
- [ ] Deploy on BSC testnet (97), verify on BscScan testnet
- [ ] Frontend wired to testnet addresses; full flow tested end-to-end

## Mainnet
- [ ] Deploy PoWAttestor + ProofBadge on BSC mainnet (56) with a deployer wallet YOU control and fund (gas only)
- [ ] Verify both on BscScan, source open-source
- [ ] Paste addresses into README + frontend

## Growth (counts toward Pioneer + 30-address Innovation gate)
- [ ] Claim Agent ID in Binance App (Wallet > banner) for your own test wallet
- [ ] Invite 30+ distinct Agent ID holders to call attest() during 18 Nov-9 Dec 2026
- [ ] Optional X posts with #BinanceWalletHackathon #AgenticWallet + official survey

## Submission (before 2026-12-09 08:00 UTC)
- [ ] One project only. Submit: name, website, contract addresses, Agent ID usage description
- [ ] README final: owner permissions documented, safety notes, demo steps
- [ ] Demo video recorded

## Never
- [ ] Never share seed phrases, private keys, pairing codes, or API secrets
- [ ] Never promise returns or "passive income"
- [ ] Never use "Binance"/"BNB" in the project name, token name, or domain
