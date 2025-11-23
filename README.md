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

## Screenshot
<img width="950" height="589" alt="screenshot1" src="https://github.com/user-attachments/assets/c9c782c5-af82-4a98-bb54-f9628eb80cf3" />
<img width="950" height="589" alt="screenshot2" src="https://github.com/user-attachments/assets/a525a0e1-c96b-4077-9c99-20be6997b1b2" />
<img width="950" height="589" alt="screenshot3" src="https://github.com/user-attachments/assets/84a1a769-31e8-4e24-bc62-3f4ac00012f7" />


## AI
- Please take a look at [AI_USAGE.md](https://github.com/buenos-tickets/monorepo/blob/main/AI_USAGE.md)
