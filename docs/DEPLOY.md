# Panduan deploy ProofofID (dari file lokal ke URL publik)

STATUS: kontrak sudah ditulis + 13 test lolos. Belum di-deploy, belum ada URL publik.
File di workspace ini adalah sumbernya; deploy adalah langkah manual yang butuh wallet + BNB kamu sendiri.

## Prasyarat (sekali)
1. Pasang Foundry: `curl -L https://foundry.paradigm.xyz | bash && foundryup`
2. Pasang dependency project ini:
   ```
   cd agentid-pow/contracts
   forge install OpenZeppelin/openzeppelin-contracts --no-git
   forge install foundry-rs/forge-std --no-git
   ```
   (kalau `lib/` sudah terisi, langkah ini boleh dilewati.)
3. Wallet deployer yang KAMU pegang, isi sedikit BNB untuk gas (testnet dulu).

## 1) Test lokal
```
forge build
forge test -vv
```
Harus: 13 passed, 0 failed. (Test memakai MockAgentID; testnet/mainnet memakai alamat Agent ID asli.)

## 2) Deploy ke BSC testnet (97)
```
forge script script/Deploy.s.sol \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 \
  --private-key $DEPLOYER_KEY --broadcast
```
Script melakukan: ProofBadge -> PoWAttestor -> badge.setAttestor(attestor).
Catat kedua alamat dari output.

Verifikasi di BscScan testnet (satu perintah, pakai API key BscScan):
```
forge verify-contract $BADGE_ADDRESS src/ProofBadge.sol:ProofBadge \
  --chain 97 --verifier etherscan --etherscan-api-key $BSCAN_KEY
forge verify-contract $ATTESTOR_ADDRESS src/PoWAttestor.sol:PoWAttestor \
  --chain 97 --verifier etherscan --etherscan-api-key $BSCAN_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address,uint256)" 0x60b9262456de011f7d15a54cdd8c48baaa8b022f $BADGE_ADDRESS 16)
```
(Pastikan source code open-source / verified di BscScan sebelum submit: itu syarat resmi.)

## 3) Uji flow end-to-end di testnet
1. Klaim Agent ID di Binance App (Wallet > banner Agent ID) untuk wallet uji.
2. Serve frontend lokal: `python3 -m http.server 8000` di folder `agentid-pow/frontend/`, buka `http://localhost:8000`.
3. Isi `CONFIG.attestor` di `frontend/index.html` dengan alamat testnet dulu bila mau versi testnet, lalu jalan: hubungkan wallet > cek Agent ID > mining > sign EIP-712 > submit.
4. Cek event `ProofAttested` dan badge soulbound (tokenId) di BscScan testnet.

CATATAN: alamat Agent ID di script adalah alamat MAINNET. Di testnet tidak ada Agent ID asli,
jadi langkah cek holder akan gagal di testnet kecuali kamu override sementara `AGENT_ID_MAINNET`
dengan mock. Itu normal: uji logika di testnet dengan mock, deploy kontrak final di mainnet.

## 4) Deploy ke mainnet (56)
```
forge script script/Deploy.s.sol \
  --rpc-url https://bsc-dataseed.binance.org \
  --private-key $DEPLOYER_KEY --broadcast --verify
```
Lalu isi `CONFIG.attestor` + `CONFIG.badge` di `frontend/index.html` dengan alamat mainnet,
dan `CONFIG.og:url` dengan URL frontend publikmu.

## 5) Host frontend (pilihan paling cepat)
File frontend adalah satu file HTML statis. Pilihan gratis:
- Vercel: `npx vercel deploy --prod` dari folder `agentid-pow/frontend/`
- Netlify: drag-drop foldernya di app.netlify.com
- GitHub Pages: push folder ke repo, aktifkan Pages

Setelah ada URL, paste URL ke SUBMISSION.md dan pakai untuk submit resmi.

## 6) Ambil 30+ alamat Agent ID beneran (syarat Innovation Award)
Kontrakmu dihitung hanya dari alamat yang SUBMIT di formulir. Jadi:
1. Klaim Agent ID sendiri di Binance App.
2. Ajak 30+ holder lain (maksimal: postingan X dengan hashtag resmi, lihat docs/SOCIAL.md).
3. Masing-masing cukup 1x `attest()` dalam window 18 Nov - 9 Des 2026 08:00 UTC.
4. Simpan tx hash contoh untuk bukti di form.

## Yang TIDAK dilakukan di paket ini (sengaja)
- Tidak ada deploy, tanda tangan, kirim transaksi, atau pembayaran dari sini.
- Tidak ada token tradable, tidak ada custody dana, tidak ada klaim "audited/perfect".
- Kontrak adalah draft yang sudah diuji unit test, belum diaudit pihak ketiga.
