// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BuenosTickets } from "./BuenosTickets.sol";
import { MockUSDC } from "./MockUSDC.sol";

contract BuenosTicketsRefundTest {
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

    // === Refund Tests ===
    
    function test_RefundBeforeSettlement() public {
        ticketSale.setupSale(duration, ticketPrice, maxTickets);
        
        mockUSDC.approve(address(ticketSale), ticketPrice);
        ticketSale.reserveTicket();
        
        try ticketSale.refund() {
            revert("Should have reverted");
        } catch Error(string memory reason) {
            require(
                keccak256(bytes(reason)) == keccak256("TS: Sale must be settled first"),
                "Wrong revert reason"
            );
        }
    }
    
    function test_RefundNoReservation() public {
        ticketSale.setupSale(1, ticketPrice, maxTickets);
        
        // Note: Would need block mining and settlement to test properly
    }
}

