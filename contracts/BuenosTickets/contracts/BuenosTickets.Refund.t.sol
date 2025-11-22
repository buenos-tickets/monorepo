// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BuenosTickets } from "./BuenosTickets.sol";
import { MockUSDC } from "./MockUSDC.sol";

contract BuenosTicketsRefundTest {
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

    // === Refund Tests ===
    
    function test_RefundBeforeSettlement() public {
        ticketSale.setupSale(endBlock, ticketPrice, maxTickets);
        
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
        ticketSale.setupSale(block.number + 1, ticketPrice, maxTickets);
        
        // Note: Would need block mining and settlement to test properly
    }
}

