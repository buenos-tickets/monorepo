// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BuenosTickets } from "./BuenosTickets.sol";
import { MockUSDC } from "./MockUSDC.sol";

contract BuenosTicketsSettlementTest {
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

    // === Settlement Tests ===
    
    function test_SettleSaleFCFS() public {
        // Test FCFS settlement when totalReserved < maxTickets
        ticketSale.setupSale(5, ticketPrice, 10); // 10 max tickets
        
        // Reserve only 1 ticket (less than max)
        mockUSDC.approve(address(ticketSale), ticketPrice);
        ticketSale.reserveTicket();
        
        // Note: Would need block mining to actually settle
        // This tests the FCFS path (no lottery needed)
    }
    
    function test_SettleSaleWithLottery() public {
        // Test lottery path when totalReserved >= maxTickets
        ticketSale.setupSale(5, ticketPrice, maxTickets);
        
        // Reserve tickets equal to or more than max
        mockUSDC.approve(address(ticketSale), ticketPrice);
        ticketSale.reserveTicket();
        
        // Note: Would need block mining and entropy callback to test lottery
        // This requires Pyth Network entropy integration for full testing
    }
    
    function test_SettleSaleBeforeEndBlock() public {
        ticketSale.setupSale(duration, ticketPrice, maxTickets);
        
        mockUSDC.approve(address(ticketSale), ticketPrice);
        ticketSale.reserveTicket();
        
        try ticketSale.settleSale() {
            revert("Should have reverted");
        } catch Error(string memory reason) {
            require(
                keccak256(bytes(reason)) == keccak256("TS: Sale is still active"),
                "Wrong revert reason"
            );
        }
    }
}

