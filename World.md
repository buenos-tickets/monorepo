# How to use World ID Verifier (ID Kit)

Register the application in the [Worldcoin Developer Portal](https://developer.worldcoin.org/login) beforehand.

Steps: Verification request → Redirect to World App → Obtain proof object → Verify the proof using an on-chain or off-chain (cloud) verifier

On-chain verification is possible on other chains. However, the contract's state root must always be synchronized (bridged).
Besides World Chain, the World Foundation operates contracts on the following chains: ethereum-mainnet, ethereum-sepolia, optimism-mainnet, optimism-sepolia, polygon-mainnet, and base-sepolia ([source](https://docs.world.org/world-id/reference/contract-deployments))

We intended to use World for "proof of human", but we dropped the idea due to the rule excluding probabilistic elements.

