# How to use Pyth Network Entropy

Based on https://docs.pyth.network/entropy/generate-random-numbers/evm, create a contract.
When the contract requests a random number, the random number provider will call `entropyCallback()` within the same contract later.
The callback function parameters are:
* `sequenceNumber` - The request ID received when requesting the random number
* `provider` - The address of the random number provider (unused)
* `randomNumber` - The random number (refer to https://docs.pyth.network/entropy/best-practices#generating-random-values-within-a-specific-range to limit the range)

Reference:
* List of supported networks: https://docs.pyth.network/entropy/contract-addresses
  * NOTE: ethereum-mainnet and ethereum-sepolia are not supported.
* Random number request fee (i.e., amount transferred when calling external contract): https://docs.pyth.network/entropy/current-fees

