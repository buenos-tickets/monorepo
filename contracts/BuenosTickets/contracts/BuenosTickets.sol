// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MockUSDC.sol";
import { IEntropyConsumer } from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
import { IEntropyV2 } from "@pythnetwork/entropy-sdk-solidity/IEntropyV2.sol";

// Main Ticket Sale Contract
contract BuenosTickets is IEntropyConsumer{
    address public admin;
    IERC20 public usdcToken; // Address of the actual USDC token contract
    IEntropyV2 entropy;

    uint256 public endBlock; // Block number when the sale stops accepting reservations
    uint256 public ticketPrice; // Price of one ticket in USDC (e.g., 1e6 for 1 USDC)
    uint256 public maxTickets; // Total tickets available for sale
    uint256 public totalReserved; // Total number of unique reservations made
    uint64 sequenceNumber;
    bytes32 randomNumber;

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
     * @param _entropyAddress The address of the Pyth Network random number provider contract.
     */
    constructor(address _usdcTokenAddress, address _entropyAddress) {
        admin = msg.sender;
        usdcToken = IERC20(_usdcTokenAddress);
        entropy = IEntropyV2(_entropyAddress);
        // Ensure initial status for any address is Unreserved
        // by mapping(address => Reservation) default value
    }

    // --- 1. Setup a ticket sale (Admin) ---
    /**
     * @notice Admin sets up the parameters for the ticket sale.
     * @param _duration The number of blocks from now until the sale ends (e.g., 100 for 100 blocks).
     * @param _price The price of one ticket in USDC (e.g., 10000 for 0.01 USDC with 6 decimals).
     * @param _maxTickets The maximum number of tickets available for sale.
     */
    function setupSale(uint256 _duration, uint256 _price, uint256 _maxTickets) external onlyAdmin {
        require(endBlock == 0, "TS: Sale already set up");
        require(_maxTickets > 0, "TS: Max tickets must be positive");
        require(_price > 0, "TS: Ticket price must be positive");
        require(_duration > 0, "TS: Duration must be positive");

        endBlock = block.number + _duration;
        ticketPrice = _price;
        maxTickets = _maxTickets;

        emit SaleSetup(_duration, _price, _maxTickets);
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
    function settleSale() external payable onlyAdmin saleClosed {
        uint256 soldTickets = 0;

        if (totalReserved < maxTickets) {
            // FCFS: All reservations become winners
            for (uint256 i = 0; i < totalReserved; i++) {
                address user = reservationOrder[i];
                Reservation storage res = reservations[user];

                res.status = Status.Selected;
                soldTickets++;
            }

            uint256 totalRevenue = soldTickets * ticketPrice;

            isSettled = true;
            emit SaleSettled(soldTickets, totalRevenue);
        } else {
            // Lottery: Request random number from Pyth Network
            uint256 fee = entropy.getFeeV2();
            sequenceNumber = entropy.requestV2{ value: fee }();
        }
    }

    // @param _sequenceNumber The sequence number of the request.
    // @param _provider The address of the provider that generated the random number. If your app uses multiple providers, you can use this argument to distinguish which one is calling the app back.
    // @param _randomNumber The generated random number.
    // This method is called by the entropy contract when a random number is generated.
    // This method **must** be implemented on the same contract that requested the random number.
    // This method should **never** return an error -- if it returns an error, then the keeper will not be able to invoke the callback.
    // If you are having problems receiving the callback, the most likely cause is that the callback is erroring.
    // See the callback debugging guide here to identify the error https://docs.pyth.network/entropy/debug-callback-failures
    function entropyCallback(
        uint64 _sequenceNumber,
        address /* _provider */,
        bytes32 _randomNumber
    ) internal override {
        require(sequenceNumber == _sequenceNumber, "TS: Invalid Pyth Entropy callback called");

        randomNumber = _randomNumber;
    }

    /**
     * @notice Select winners by using Pyth Network Entropy.
     * This function can only be called after the `entropyCallback`.
     */
    function spinWheel() external onlyAdmin saleClosed {
        address[] memory candidates = reservationOrder;
        uint256 soldTickets = 0;

        // shuffle
        for (uint256 i = 0; i < maxTickets; i++) {
            uint256 randomness = uint256(keccak256(abi.encodePacked(randomNumber, i)));
            uint256 swapIndex = i + (randomness % (maxTickets - i));
            address temp = candidates[i];
            candidates[i] = candidates[swapIndex];
            candidates[swapIndex] = temp;
        }

        for (uint256 i = 0; i < maxTickets; i++) {
            address user = candidates[i];
            Reservation storage res = reservations[user];
            res.status = Status.Selected;
            soldTickets++;
        }

        uint256 totalRevenue = soldTickets * ticketPrice;

        isSettled = true;
        emit SaleSettled(soldTickets, totalRevenue);
    }

    function getEntropy() internal view override returns (address) {
        return address(entropy);
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
        sequenceNumber = 0;
        randomNumber = 0;

        emit ContractReset(contractBalance);
    }
}
