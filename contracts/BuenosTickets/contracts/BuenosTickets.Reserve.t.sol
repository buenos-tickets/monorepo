// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BuenosTickets } from "./BuenosTickets.sol";
import { MockUSDC } from "./MockUSDC.sol";

contract BuenosTicketsReserveTest {
    BuenosTickets public ticketSale;
    MockUSDC public mockUSDC;
    
    address public admin;
    address public mockEntropyAddress = address(0x999); // Mock entropy address
    uint256 public ticketPrice = 1000000; // 1 USDC (6 decimals)
    uint256 public maxTickets = 2;
    uint256 public duration = 100; // 100 blocks

    function setUp() public {
        admin = address(this);
        mockUSDC = new MockUSDC();
        ticketSale = new BuenosTickets(address(mockUSDC), mockEntropyAddress);
    }

    // === Reserve Ticket Tests ===
    
    function test_ReserveTicket() public {
        ticketSale.setupSale(duration, ticketPrice, maxTickets);
        
        mockUSDC.approve(address(ticketSale), ticketPrice);
        ticketSale.reserveTicket();
        
        require(ticketSale.totalReserved() == 1, "Total reserved should be 1");
        require(
            ticketSale.getUserStatus(address(this)) == BuenosTickets.Status.Reserved,
            "Status should be Reserved"
        );
    }
    
    function test_ReserveTicketWithoutSetup() public {
        mockUSDC.approve(address(ticketSale), ticketPrice);
        
        try ticketSale.reserveTicket() {
            revert("Should have reverted");
        } catch Error(string memory reason) {
            require(
                keccak256(bytes(reason)) == keccak256("TS: Sale not set up yet"),
                "Wrong revert reason"
            );
        }
    }
    
    function test_ReserveTicketDoubleReservation() public {
        ticketSale.setupSale(duration, ticketPrice, maxTickets);
        
        mockUSDC.approve(address(ticketSale), ticketPrice * 2);
        ticketSale.reserveTicket();
        
        try ticketSale.reserveTicket() {
            revert("Should have reverted");
        } catch Error(string memory reason) {
            require(
                keccak256(bytes(reason)) == keccak256("TS: Ticket already reserved"),
                "Wrong revert reason"
            );
        }
    }
    
    function test_ReserveTicketWithoutApproval() public {
        ticketSale.setupSale(duration, ticketPrice, maxTickets);
        
        try ticketSale.reserveTicket() {
            revert("Should have reverted");
        } catch Error(string memory reason) {
            require(
                keccak256(bytes(reason)) == keccak256("ERC20: transfer amount exceeds allowance"),
                "Wrong revert reason"
            );
        }
    }
    
    function test_MultipleReservations() public {
        ticketSale.setupSale(duration, ticketPrice, 5);
        
        mockUSDC.approve(address(ticketSale), ticketPrice);
        ticketSale.reserveTicket();
        
        require(ticketSale.totalReserved() == 1, "Should have 1 reservation");
        require(ticketSale.reservationOrder(0) == address(this), "FCFS order mismatch");
    }
    
    function test_CheckReservationDetails() public {
        ticketSale.setupSale(duration, ticketPrice, maxTickets);
        
        mockUSDC.approve(address(ticketSale), ticketPrice);
        ticketSale.reserveTicket();
        
        (uint256 amountPaid, BuenosTickets.Status status) = ticketSale.reservations(address(this));
        require(amountPaid == ticketPrice, "Amount paid mismatch");
        require(status == BuenosTickets.Status.Reserved, "Status mismatch");
    }
    
    function test_ContractHoldsUSDC() public {
        ticketSale.setupSale(duration, ticketPrice, maxTickets);
        
        uint256 contractBalanceBefore = mockUSDC.balanceOf(address(ticketSale));
        
        mockUSDC.approve(address(ticketSale), ticketPrice);
        ticketSale.reserveTicket();
        
        uint256 contractBalanceAfter = mockUSDC.balanceOf(address(ticketSale));
        require(
            contractBalanceAfter - contractBalanceBefore == ticketPrice,
            "Contract should hold USDC"
        );
    }
}

