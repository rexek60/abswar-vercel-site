# ABSWAR Abstract Mainnet Launch

## Before Deployment

1. Run the frontend build and the backend checks.
2. Compile the contract with ZKsync VM-compatible bytecode:
   `npm run contract:compile`
3. Create a dedicated deployer wallet. Do not commit its private key and do not use a wallet that stores unrelated funds.
4. Store the key with Hardhat:
   `npx hardhat vars set DEPLOYER_PRIVATE_KEY`
5. Deploy to Abstract testnet first:
   `npm run contract:deploy:testnet`
6. Verify the deployed source:
   `npx hardhat verify --network abstractTestnet <contract-address>`
7. Test login signing, country selection, attacks, one purchase, duplicate purchase rejection, and admin actions on testnet.

## Mainnet Deployment

1. Fund the dedicated deployer wallet with only the ETH needed for deployment.
2. Deploy:
   `npm run contract:deploy:mainnet`
3. Verify:
   `npx hardhat verify --network abstractMainnet <contract-address>`
4. Put the verified mainnet address into the frontend `CHAINS.mainnet.contractAddress`.
5. In Railway set:
   `AUTH_SECRET`, `ABSWAR_NETWORK=mainnet`, `ABSWAR_RPC_URL=https://api.mainnet.abs.xyz`,
   `ABSWAR_CONTRACT_ADDRESS=<verified-mainnet-address>`, `ALLOW_DEMO_PURCHASES=false`.
6. Switch the frontend default network from `testnet` to `mainnet`.
7. Deploy backend first, then frontend, then run a low-value purchase smoke test.

## Notes

- `buyAmmo()` keeps the same selector, `0x499eb3de`.
- The backend only credits ammo after checking the receipt, sender, target contract, method, value, event, chain, and replay table.
- Keep PostgreSQL enabled on mainnet. Purchase replay protection is persistent in the `purchases` table.
