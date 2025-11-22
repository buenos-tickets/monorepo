# hardhat-tutorial

Hardhat tutorial from https://hardhat.org/docs/tutorial/setup

## Contracts

`Counter.sol` and `Counter.t.sol` are from https://hardhat.org/docs/tutorial/writing-and-testing

## Build ant test

1. Build
```
$ npx hardhat build

Compiled 1 Solidity file with solc 0.8.28 (evm target: cancun)
No Solidity tests to compile
```

2. Run tests

```
$ npx hardhat test
No contracts to compile
No Solidity tests to compile

Running Solidity tests

  contracts/Counter.t.sol:CounterTest
    ✔ test_InitialValueIsZero()
    1) test_IncIncreasesByOne()
    ✔ test_IncByIncreasesByGivenAmount()


  2 passing
  1 failing

  contracts/Counter.t.sol:CounterTest
    1) test_IncIncreasesByOne()
      Error: revert: inc should increase x by 1
        at CounterTest.test_IncIncreasesByOne (contracts/Counter.t.sol:19)


Test run failed
```
