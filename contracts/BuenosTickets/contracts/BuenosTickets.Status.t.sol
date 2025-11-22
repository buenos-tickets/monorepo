// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BuenosTickets } from "./BuenosTickets.sol";
import { MockUSDC } from "./MockUSDC.sol";

contract BuenosTicketsStatusTest {
    BuenosTickets public ticketSale;
    MockUSDC public mockUSDC;
    
    address public admin;
    address public user1 = address(0x1);
    uint256 public ticketPrice = 1000000; // 1 USDC (6 decimals)
    uint256 public maxTickets = 2;
    uint256 public endBlock;

    function setUp() public {
        admin = address(this);
        mockUSDC = new MockUSDC();
        ticketSale = new BuenosTickets(address(mockUSDC));
        endBlock = block.number + 100;
    }

    // === Status Check Tests ===
    
    function test_GetUserStatusUnreserved() public view {
        require(
            ticketSale.getUserStatus(user1) == BuenosTickets.Status.Unreserved,
            "New user should be Unreserved"
        );
    }
    
    function test_GetUserStatusAfterReservation() public {
        ticketSale.setupSale(endBlock, ticketPrice, maxTickets);
        
        mockUSDC.approve(address(ticketSale), ticketPrice);
        ticketSale.reserveTicket();
        
        require(
            ticketSale.getUserStatus(address(this)) == BuenosTickets.Status.Reserved,
            "User should be Reserved after reservation"
        );
    }
}

