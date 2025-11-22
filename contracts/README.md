# Buenos Tickets Contract


We are going to use Pyth network to generate a random number.

### Methods

- setupSale (invoked by Seller)
- receive (TBD for ERC20) (invoked by User via x402)
- finalizeSale (invoked by Seller)
- callback (callback invoked by Pyth network)
- refund (invoked by user))
- settlement (invoked by Seller)

### Workflow

1. Setup a ticket sale (`setupSale`)
   - Admin setup a ticket sale with following parameters
   - endBlock: Block number when the sales ends
   - Price of the ticket in USDC: for example 0.01 USDC
   - Number of ticket for sale: for example 
 
2. User can reserve a ticket by depositing 0.01 USDC (`reserveTicket`)
3. When block number past endBlock, sale closes and user can not reserve tickets.
4. Admin make a settlement for the sale (`settleSale`)
   - Admin invoke a function to make a settlement
   - If oversubscribed, 
      - Select User FCFS based
   - If not oversubscribed,
      - Select all users
5. After the steelement
   - users who does not selected can invoke `refund` to refund USDC (`refund`)
   - admin can withdraw USDC for sold tickets (`withdrawFunds`)
