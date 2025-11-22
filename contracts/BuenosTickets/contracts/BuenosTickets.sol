// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MockUSDC.sol";

// Main Ticket Sale Contract
contract BuenosTickets {
    address public admin;
    IERC20 public usdcToken; // Address of the actual USDC token contract

    uint256 public endBlock; // Block number when the sale stops accepting reservations
    uint256 public ticketPrice; // Price of one ticket in USDC (e.g., 1e6 for 1 USDC)
    uint256 public maxTickets; // Total tickets available for sale
    uint256 public totalReserved; // Total number of unique reservations made

    // Reservation status states
    enum Status { Unreserved, Reserved, Selected, Refunded }

    struct Reservation {
        uint256 amountPaid;
        Status status;
    }

    mapping(address => Reservation) public reservations;
    address[] public reservationOrder; // Tracks FCFS order for settlement

    bool public isSettled = false;

    // --- Events ---
    event SaleSetup(uint256 _endBlock, uint256 _price, uint256 _maxTickets);
    event TicketReserved(address indexed user, uint256 price);
    event SaleSettled(uint256 soldTickets, uint256 totalRevenue);
    event Refunded(address indexed user, uint256 amount);
    event AdminWithdrew(uint256 amount);
    event ContractReset(uint256 usdcWithdrawn);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "TS: Only admin can call this function");
        _;
    }

    modifier saleActive() {
        require(endBlock > 0, "TS: Sale not set up yet");
        require(block.number <= endBlock, "TS: Sale period has ended");
        require(!isSettled, "TS: Sale is already settled");
        _;
    }

    modifier saleClosed() {
        require(block.number > endBlock, "TS: Sale is still active");
        require(!isSettled, "TS: Sale is already settled");
        _;
    }

    modifier onlyAfterSettlement() {
        require(isSettled, "TS: Sale must be settled first");
        _;
    }

    /**
     * @notice Constructor sets the admin and the USDC token address.
     * @param _usdcTokenAddress The address of the deployed USDC (or MockUSDC) contract.
     */
    constructor(address _usdcTokenAddress) {
        admin = msg.sender;
        usdcToken = IERC20(_usdcTokenAddress);
        // Ensure initial status for any address is Unreserved
        // by mapping(address => Reservation) default value
    }

    // --- 1. Setup a ticket sale (Admin) ---
    /**
     * @notice Admin sets up the parameters for the ticket sale.
     * @param _endBlock The block number when the sales ends.
     * @param _price The price of one ticket in USDC (e.g., 10000 for 0.01 USDC with 6 decimals).
     * @param _maxTickets The maximum number of tickets available for sale.
     */
    function setupSale(uint256 _endBlock, uint256 _price, uint256 _maxTickets) external onlyAdmin {
        require(endBlock == 0, "TS: Sale already set up");
        require(_maxTickets > 0, "TS: Max tickets must be positive");
        require(_price > 0, "TS: Ticket price must be positive");
        require(_endBlock > block.number, "TS: End block must be in the future");

        endBlock = _endBlock;
        ticketPrice = _price;
        maxTickets = _maxTickets;

        emit SaleSetup(_endBlock, _price, _maxTickets);
    }

    // --- 2. User can reserve a ticket ---
    /**
     * @notice User reserves a ticket by paying the required USDC price. FCFS order is tracked.
     * NOTE: The user must approve the 'ticketPrice' amount to this contract beforehand.
     */
    function reserveTicket() external saleActive {
        // 2. Check if the user has already reserved
        require(reservations[msg.sender].status == Status.Unreserved, "TS: Ticket already reserved");

        // 3. Transfer USDC from the user to the contract using transferFrom (requires prior approval)
        bool success = usdcToken.transferFrom(msg.sender, address(this), ticketPrice);
        require(success, "TS: USDC transfer failed (Check approval/balance)");

        // 4. Store reservation details and track FCFS order
        reservations[msg.sender] = Reservation({
            amountPaid: ticketPrice,
            status: Status.Reserved
        });

        reservationOrder.push(msg.sender); // The order they appear here determines FCFS
        totalReserved++;

        emit TicketReserved(msg.sender, ticketPrice);
    }

    // --- 4. Admin makes a settlement for the sale ---
    /**
     * @notice Admin finalizes the sale, selects winners FCFS, and sets settlement status.
     * This function can only be called after the endBlock.
     */
    function settleSale() external onlyAdmin saleClosed {
        isSettled = true;
        uint256 soldTickets = 0;

        // Determine the number of winners (Min of reserved users or max available tickets)
        uint256 winners = totalReserved < maxTickets ? totalReserved : maxTickets;

        // 1. Select Winners (FCFS based on reservationOrder)
        for (uint256 i = 0; i < totalReserved; i++) {
            address user = reservationOrder[i];
            Reservation storage res = reservations[user];

            if (i < winners) {
                // FCFS Winner
                res.status = Status.Selected;
                soldTickets++;
            }
            // Users with index >= winners are rejected. Their status remains Status.Reserved,
            // allowing them to call refund later.
        }

        uint256 totalRevenue = soldTickets * ticketPrice;

        emit SaleSettled(soldTickets, totalRevenue);
    }

    // --- 5. Users and Admin actions after settlement ---

    /**
     * @notice Allows a user who was NOT selected to claim a refund of their deposited USDC.
     */
    function refund() external onlyAfterSettlement {
        Reservation storage res = reservations[msg.sender];
        require(res.amountPaid > 0, "TS: No active reservation found");

        // Only Reserved users (the ones that were rejected) can get a refund.
        require(res.status == Status.Reserved, "TS: User was either selected or already refunded");

        uint256 amountToRefund = res.amountPaid;

        // 1. Update status
        res.status = Status.Refunded;

        // 2. Transfer USDC back to the user
        bool success = usdcToken.transfer(msg.sender, amountToRefund);
        require(success, "TS: Refund USDC transfer failed");

        emit Refunded(msg.sender, amountToRefund);
    }

    /**
     * @notice Admin withdraws the USDC collected from the successful ticket sales.
     * The admin can only withdraw the funds corresponding to the 'Selected' reservations.
     */
    function withdrawFunds() external onlyAdmin onlyAfterSettlement {
        uint256 totalRevenue = 0;

        // Calculate the total revenue from 'Selected' reservations
        for (uint256 i = 0; i < reservationOrder.length; i++) {
            address user = reservationOrder[i];
            Reservation storage res = reservations[user];

            if (res.status == Status.Selected) {
                // This amount belongs to the admin
                totalRevenue += res.amountPaid;
            }
        }

        require(totalRevenue > 0, "TS: No revenue available to withdraw");

        // Transfer USDC to the admin
        bool success = usdcToken.transfer(admin, totalRevenue);
        require(success, "TS: Withdraw USDC transfer failed");

        emit AdminWithdrew(totalRevenue);
    }

    /**
     * @notice Utility function to check the status for a given user.
     */
    function getUserStatus(address user) external view returns (Status) {
        return reservations[user].status;
    }

    // --- 6. Read functions for sale configuration ---

    /**
     * @notice Get all sale configuration details at once.
     * @return _endBlock The block number when the sale ends.
     * @return _ticketPrice The price of one ticket in USDC.
     * @return _maxTickets The maximum number of tickets available.
     * @return _totalReserved The total number of reservations made.
     * @return _isSettled Whether the sale has been settled.
     */
    function getSaleInfo() external view returns (
        uint256 _endBlock,
        uint256 _ticketPrice,
        uint256 _maxTickets,
        uint256 _totalReserved,
        bool _isSettled
    ) {
        return (endBlock, ticketPrice, maxTickets, totalReserved, isSettled);
    }

    /**
     * @notice Admin resets the contract to initial state and withdraws all remaining USDC.
     * This function withdraws all USDC held by the contract and resets all state variables.
     * WARNING: This clears all reservation data. Use with caution.
     */
    function reset() external onlyAdmin {
        // 1. Withdraw all USDC balance to admin
        uint256 contractBalance = usdcToken.balanceOf(address(this));
        if (contractBalance > 0) {
            bool success = usdcToken.transfer(admin, contractBalance);
            require(success, "TS: Reset USDC withdrawal failed");
        }

        // 2. Clear all reservations for users who participated
        for (uint256 i = 0; i < reservationOrder.length; i++) {
            delete reservations[reservationOrder[i]];
        }

        // 3. Clear the reservation order array
        delete reservationOrder;

        // 4. Reset state variables to initial values
        endBlock = 0;
        ticketPrice = 0;
        maxTickets = 0;
        totalReserved = 0;
        isSettled = false;

        emit ContractReset(contractBalance);
    }
}
