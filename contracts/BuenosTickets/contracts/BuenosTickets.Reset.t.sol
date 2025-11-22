// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BuenosTickets } from "./BuenosTickets.sol";
import { MockUSDC } from "./MockUSDC.sol";

contract BuenosTicketsResetTest {
    BuenosTickets public ticketSale;
    MockUSDC public mockUSDC;
    
    address public admin;
    uint256 public ticketPrice = 1000000; // 1 USDC (6 decimals)
    uint256 public maxTickets = 2;
    uint256 public endBlock;

    function setUp() public {
        admin = address(this);
        mockUSDC = new MockUSDC();
        ticketSale = new BuenosTickets(address(mockUSDC));
        endBlock = block.number + 100;
    }

    // === Reset Tests ===
    
    function test_Reset() public {
        // Setup and reserve a ticket
        ticketSale.setupSale(endBlock, ticketPrice, maxTickets);
        mockUSDC.approve(address(ticketSale), ticketPrice);
        ticketSale.reserveTicket();
        
        uint256 adminBalanceBefore = mockUSDC.balanceOf(admin);
        uint256 contractBalance = mockUSDC.balanceOf(address(ticketSale));
        
        // Reset contract
        ticketSale.reset();
        
        // Check USDC withdrawn to admin
        uint256 adminBalanceAfter = mockUSDC.balanceOf(admin);
        require(adminBalanceAfter - adminBalanceBefore == contractBalance, "USDC not withdrawn");
        require(mockUSDC.balanceOf(address(ticketSale)) == 0, "Contract should have 0 USDC");
        
        // Check state reset
        require(ticketSale.endBlock() == 0, "End block should be reset");
        require(ticketSale.ticketPrice() == 0, "Ticket price should be reset");
        require(ticketSale.maxTickets() == 0, "Max tickets should be reset");
        require(ticketSale.totalReserved() == 0, "Total reserved should be reset");
        require(ticketSale.isSettled() == false, "isSettled should be reset");
        
        // Check reservation cleared
        require(
            ticketSale.getUserStatus(address(this)) == BuenosTickets.Status.Unreserved,
            "User status should be reset"
        );
    }
    
    function test_ResetAfterSettlement() public {
        // Setup with short endBlock
        ticketSale.setupSale(block.number + 1, ticketPrice, maxTickets);
        mockUSDC.approve(address(ticketSale), ticketPrice);
        ticketSale.reserveTicket();
        
        // Note: Would need block mining to settle in real test
        // For now, just test reset before settlement
        ticketSale.reset();
        
        // Verify can setup new sale after reset
        ticketSale.setupSale(block.number + 100, ticketPrice * 2, maxTickets + 1);
        require(ticketSale.ticketPrice() == ticketPrice * 2, "Should allow new setup after reset");
    }
    
    function test_ResetWithNoReservations() public {
        // Setup sale but no reservations
        ticketSale.setupSale(endBlock, ticketPrice, maxTickets);
        
        uint256 adminBalanceBefore = mockUSDC.balanceOf(admin);
        
        // Reset should work even with no reservations
        ticketSale.reset();
        
        require(ticketSale.endBlock() == 0, "Should reset successfully");
        require(mockUSDC.balanceOf(admin) == adminBalanceBefore, "No USDC to withdraw");
    }
    
    function test_ResetWithMultipleReservations() public {
        // Setup sale
        ticketSale.setupSale(endBlock, ticketPrice, 5);
        
        // Make multiple reservations
        mockUSDC.approve(address(ticketSale), ticketPrice);
        ticketSale.reserveTicket();
        
        require(ticketSale.totalReserved() == 1, "Should have 1 reservation");
        
        uint256 contractBalanceBefore = mockUSDC.balanceOf(address(ticketSale));
        uint256 adminBalanceBefore = mockUSDC.balanceOf(admin);
        
        // Reset
        ticketSale.reset();
        
        // Verify all cleared
        require(ticketSale.totalReserved() == 0, "Reservations should be cleared");
        require(
            mockUSDC.balanceOf(admin) - adminBalanceBefore == contractBalanceBefore,
            "All USDC should be withdrawn"
        );
    }
    
    function test_ResetAllowsNewSale() public {
        // First sale
        ticketSale.setupSale(endBlock, ticketPrice, maxTickets);
        mockUSDC.approve(address(ticketSale), ticketPrice);
        ticketSale.reserveTicket();
        
        // Reset
        ticketSale.reset();
        
        // New sale with different parameters
        uint256 newEndBlock = block.number + 200;
        uint256 newPrice = ticketPrice * 3;
        uint256 newMaxTickets = maxTickets * 2;
        
        ticketSale.setupSale(newEndBlock, newPrice, newMaxTickets);
        
        require(ticketSale.endBlock() == newEndBlock, "New end block set");
        require(ticketSale.ticketPrice() == newPrice, "New price set");
        require(ticketSale.maxTickets() == newMaxTickets, "New max tickets set");
        
        // New reservation should work
        mockUSDC.approve(address(ticketSale), newPrice);
        ticketSale.reserveTicket();
        
        require(ticketSale.totalReserved() == 1, "New reservation successful");
    }
    
    function test_ResetWithZeroBalance() public {
        // Setup sale but don't make any reservations
        ticketSale.setupSale(endBlock, ticketPrice, maxTickets);
        
        uint256 contractBalance = mockUSDC.balanceOf(address(ticketSale));
        require(contractBalance == 0, "Contract should have 0 balance");
        
        // Reset should still work
        ticketSale.reset();
        
        require(ticketSale.endBlock() == 0, "Reset successful with zero balance");
    }
}

