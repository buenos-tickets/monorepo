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

    // === Getter Function Tests ===
    
    function test_GetSaleInfo() public {
        ticketSale.setupSale(endBlock, ticketPrice, maxTickets);
        
        (
            uint256 _endBlock,
            uint256 _ticketPrice,
            uint256 _maxTickets,
            uint256 _totalReserved,
            bool _isSettled
        ) = ticketSale.getSaleInfo();
        
        require(_endBlock == endBlock, "getSaleInfo endBlock mismatch");
        require(_ticketPrice == ticketPrice, "getSaleInfo ticketPrice mismatch");
        require(_maxTickets == maxTickets, "getSaleInfo maxTickets mismatch");
        require(_totalReserved == 0, "getSaleInfo totalReserved should be 0");
        require(_isSettled == false, "getSaleInfo isSettled should be false");
    }
    
    function test_GetSaleInfoAfterReservation() public {
        ticketSale.setupSale(endBlock, ticketPrice, maxTickets);
        
        mockUSDC.approve(address(ticketSale), ticketPrice);
        ticketSale.reserveTicket();
        
        (
            uint256 _endBlock,
            uint256 _ticketPrice,
            uint256 _maxTickets,
            uint256 _totalReserved,
            bool _isSettled
        ) = ticketSale.getSaleInfo();
        
        require(_endBlock == endBlock, "getSaleInfo endBlock should match");
        require(_ticketPrice == ticketPrice, "getSaleInfo ticketPrice should match");
        require(_maxTickets == maxTickets, "getSaleInfo maxTickets should match");
        require(_totalReserved == 1, "getSaleInfo should show 1 reservation");
        require(_isSettled == false, "getSaleInfo should show not settled");
    }
    
    function test_GetSaleInfoBeforeSetup() public view {
        // All values should be 0/false before setup
        (
            uint256 _endBlock,
            uint256 _ticketPrice,
            uint256 _maxTickets,
            uint256 _totalReserved,
            bool _isSettled
        ) = ticketSale.getSaleInfo();
        
        require(_endBlock == 0, "endBlock should be 0 before setup");
        require(_ticketPrice == 0, "ticketPrice should be 0 before setup");
        require(_maxTickets == 0, "maxTickets should be 0 before setup");
        require(_totalReserved == 0, "totalReserved should be 0 before setup");
        require(_isSettled == false, "isSettled should be false before setup");
    }
    
    function test_GetSaleInfoWithMultipleReservations() public {
        ticketSale.setupSale(endBlock, ticketPrice, 5);
        
        // Make multiple reservations
        mockUSDC.approve(address(ticketSale), ticketPrice);
        ticketSale.reserveTicket();
        
        (
            uint256 _endBlock,
            uint256 _ticketPrice,
            uint256 _maxTickets,
            uint256 _totalReserved,
            bool _isSettled
        ) = ticketSale.getSaleInfo();
        
        require(_endBlock == endBlock, "endBlock should match");
        require(_ticketPrice == ticketPrice, "ticketPrice should match");
        require(_maxTickets == 5, "maxTickets should be 5");
        require(_totalReserved == 1, "totalReserved should be 1");
        require(_isSettled == false, "should not be settled");
    }
    
    function test_PublicVariablesAccessible() public {
        ticketSale.setupSale(endBlock, ticketPrice, maxTickets);
        
        // Verify public variables can still be accessed directly
        require(ticketSale.endBlock() == endBlock, "Public endBlock should be accessible");
        require(ticketSale.ticketPrice() == ticketPrice, "Public ticketPrice should be accessible");
        require(ticketSale.maxTickets() == maxTickets, "Public maxTickets should be accessible");
        require(ticketSale.totalReserved() == 0, "Public totalReserved should be accessible");
        require(ticketSale.isSettled() == false, "Public isSettled should be accessible");
    }
}

