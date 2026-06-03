# ABSWAR Rank NFT Launch

Rank NFT code is implemented, but real mainnet minting must be enabled in this order.

## 1. Create signer wallet

Create a fresh wallet used only for NFT claim signatures.

- Put the public address into Hardhat vars as `RANK_NFT_SIGNER_ADDRESS`.
- Put the private key only in Railway as `RANK_NFT_SIGNER_PRIVATE_KEY`.
- Never commit the private key to GitHub.

## 2. Deploy contract

```bash
npm run rank-nft:deploy:mainnet
```

The deployed address is `RANK_NFT_CONTRACT_ADDRESS`.

## 3. Configure Railway backend

Set these variables on the backend service:

```env
RANK_NFT_CONTRACT_ADDRESS=0x...
RANK_NFT_SIGNER_PRIVATE_KEY=0x...
RANK_NFT_CLAIM_TTL_MS=600000
```

After deploy, `/health` should show:

```json
"rankNft": { "enabled": true }
```

## 4. Frontend behavior

The site already shows the Rank NFT panel. If the backend is not configured, claim buttons stay disabled as "HAZIRLANIYOR".

When configured:

1. Player reaches a rank contribution threshold.
2. Player clicks `TALEP ET`.
3. Backend signs the claim.
4. Player mints from their own wallet.
5. The badge becomes owned.

NFTs are soulbound prestige badges and give no extra game power.
