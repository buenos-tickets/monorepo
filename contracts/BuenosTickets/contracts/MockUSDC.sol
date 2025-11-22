// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for ERC-20 (USDC)
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// MockUSDC ERC-20 Contract (For Testing/Demonstration)
// This contract is included so you can easily deploy and test the TicketSale contract
// without relying on a real USDC token on a testnet.
contract MockUSDC is IERC20 {
    string public name = "Mock USDC";
    string public symbol = "MOCKUSDC";
    uint8 public decimals = 6; // Standard for USDC

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        // Mint a starting supply to the deployer (which will be the Admin/Test account)
        uint256 initialSupply = 1000000 * 10**decimals;
        balances[msg.sender] = initialSupply;
    }

    function balanceOf(address account) public view override returns (uint256) { return balances[account]; }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        return true;
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(allowance[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");

        balances[sender] -= amount;
        allowance[sender][msg.sender] -= amount;
        balances[recipient] += amount;
        return true;
    }
}

