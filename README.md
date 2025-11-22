# buenos-tickets

We aim to make the ticket sales fair, not based on first-come, first-served basis.
Tickets will be sold until the closing time, after which a limited number of people will be selected.
Payment will be collected in advance, and refunds will be issued to those not selected.

## sequence diagram

```mermaid
sequenceDiagram
  participant Users
  participant Seller
  Seller->>Contract: Setup the campaign 
  Users->>Contract: Buy tickets
  Users->>Contract: End sales by anyone
  activate Contract
  Contract->>Pyth: Request entropy
  deactivate Contract
  Pyth->>Contract: Return random number by callback
  par check results
    Users->>Contract: Check results
  and refund
    Users->>Contract: Request refunds
    Contract->>Users: Refunds
  and settlement
    Seller->>Contract: Request sales revenue
    Contract->>Seller: Send the fund
  end
```
