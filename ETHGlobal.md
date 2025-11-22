# Buenos Tickets

It's our ETHGlobal Buenos Aires project.

## What category does your project belong to?

Wallet/Payments

## What emoji best represents your project?

🎟️

## If you have a demonstration, link to it here!

## Short description

Fair ticket sales: limited buyers will be randomly selected after the closing time.

## Description

Booking tickets for popular shows is often highly competitive due to first-come, first-served systems, and it is also plagued by resale issues. To mitigate these problems, buyers are selected randomly. Users express their intention to purchase by paying the price until the deadline. After the deadline, buyers are randomly selected. Users who are not selected can receive a refund, and ticket sellers can collect the raised funds.

## How it's made

* Pyth - Pyth Network Entropy is used to obtain tamper-proof random numbers.
  It utilizes the commit-reveal mechanism to generate unpredictable and unmanipulatable random numbers.
  If there are more buyers than the predetermined number, lottery winners are selected by shuffling using the generated random number.
* x402 - x402 is used for fee-less transfers. Instead of a simple transfer, a signed message that calls `reserveTicket()` of the BuenosTickets smart contract is sent to x402.
* Hardhat - Hardhat is an indispensable tool that assists smart contract development.

