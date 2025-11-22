// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BuenosTickets } from "./BuenosTickets.sol";
import { MockUSDC } from "./MockUSDC.sol";

contract BuenosTicketsSetupTest {
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

    // === Deployment Tests ===
    
    function test_InitialState() public view {
        require(ticketSale.admin() == admin, "Admin should be deployer");
        require(address(ticketSale.usdcToken()) == address(mockUSDC), "USDC token should be set");
        require(ticketSale.endBlock() == 0, "End block should be 0 initially");
        require(ticketSale.isSettled() == false, "Sale should not be settled");
    }

    // === Setup Sale Tests ===
    
    function test_SetupSale() public {
        uint256 expectedEndBlock = block.number + duration;
        ticketSale.setupSale(duration, ticketPrice, maxTickets);
        
        require(ticketSale.endBlock() == expectedEndBlock, "End block mismatch");
        require(ticketSale.ticketPrice() == ticketPrice, "Ticket price mismatch");
        require(ticketSale.maxTickets() == maxTickets, "Max tickets mismatch");
    }
    
    function test_SetupSaleZeroTickets() public {
        try ticketSale.setupSale(duration, ticketPrice, 0) {
            revert("Should have reverted");
        } catch Error(string memory reason) {
            require(
                keccak256(bytes(reason)) == keccak256("TS: Max tickets must be positive"),
                "Wrong revert reason"
            );
        }
    }
    
    function test_SetupSaleZeroPrice() public {
        try ticketSale.setupSale(duration, 0, maxTickets) {
            revert("Should have reverted");
        } catch Error(string memory reason) {
            require(
                keccak256(bytes(reason)) == keccak256("TS: Ticket price must be positive"),
                "Wrong revert reason"
            );
        }
    }
    
    function test_SetupSaleZeroDuration() public {
        try ticketSale.setupSale(0, ticketPrice, maxTickets) {
            revert("Should have reverted");
        } catch Error(string memory reason) {
            require(
                keccak256(bytes(reason)) == keccak256("TS: Duration must be positive"),
                "Wrong revert reason"
            );
        }
    }
    
    function test_SetupSaleAlreadySetup() public {
        ticketSale.setupSale(duration, ticketPrice, maxTickets);
        
        try ticketSale.setupSale(duration + 100, ticketPrice, maxTickets) {
            revert("Should have reverted");
        } catch Error(string memory reason) {
            require(
                keccak256(bytes(reason)) == keccak256("TS: Sale already set up"),
                "Wrong revert reason"
            );
        }
    }
}

