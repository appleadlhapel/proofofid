# $NOR Tokenomics — ProofofID

> Status: **DRAFT NUMBERS, DECIDED TIMING** (2026-11-19). User decided 2026-11-19 ~15:56 WIB: **deploy $NOR after the hackathon judging window**, not before.
> $NOR does **not** exist yet: no contract deployed, no address, no trading.
> Nothing here promises a price, a return, or a yield.

## Token

- Name: $NOR — the ProofofID activity token.
- Standard: ERC-20 on BNB Chain (to be deployed after the hackathon judging window).
- Total supply: **1,000,000,000 NOR** (1B, fixed at deploy, no further minting).

## Distribution

| Allocation | Share | Amount | Notes |
|---|---|---|---|
| Community rewards (daily check-in) | 50% | 500,000,000 | Emitted over time from on-chain check-in proofs |
| Team & contributors | 20% | 200,000,000 | 12-month cliff, then 24-month linear vesting |
| Ecosystem & treasury | 15% | 150,000,000 | Grants, integrations, partnerships |
| Liquidity | 10% | 100,000,000 | DEX liquidity at TGE |
| Hackathon & early airdrop | 5% | 50,000,000 | Early supporters and hackathon community |

## How to earn $NOR — daily check-in

- **1 successful daily check-in (`attest()`) = 10 NOR** (base rate).
- **Streak bonus:** 7+ day streak earns 15 NOR per day (x1.5); 30+ day streak earns 20 NOR per day (x2).
- Earnings are tracked from **on-chain data that already exists**: `proofsOf` (total check-ins) and `streakOf` (current streak) in `PoWAttestor`. No contract change is needed to start earning.
- Conversion to $NOR happens at TGE through a **snapshot + claim**: a future claim contract (e.g. merkle distributor) lets each holder claim what they earned. Claim window and TGE date are announced later.

## Rules

- 1 check-in per Agent ID per day — enforced on-chain by `PoWAttestor` (one attestation per day).
- Agent ID gate: only Agent ID holders can attest, so 1 Agent ID = 1 badge = 1 reward track. No multi-wallet farming beyond holding multiple Agent IDs.
- Badge stays soulbound and non-transferable. $NOR itself is a normal ERC-20 once deployed.

## What $NOR is not

- Not an investment, not a yield product, not a promise of profit.
- No price is promised. No return is promised. The reward is eligibility for a future distribution, sized by verifiable on-chain activity.
- If the distribution never happens, check-ins still leave the holder with the soulbound badge and streak record.

## Open decisions (user to confirm)

1. Total supply: 1,000,000,000 NOR (proposed).
2. Base rate: 10 NOR per daily check-in; streak multipliers x1.5 / x2 (proposed).
3. Deploy timing: **DECIDED 2026-11-19 — after hackathon judging.** Keeps the judged contracts untouched and avoids any "promised returns" reading during review.
