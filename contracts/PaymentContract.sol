// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./GameToken.sol";

contract PaymentContract is Ownable {
    GameToken public gameToken;

    event TokensPurchased(
        address indexed buyer,
        uint256 avaxAmount,
        uint256 tokenAmount
    );
    event AVAXReceived(address sender, uint256 amount, uint256 currentBalance);
    event AVAXWithdrawn(address indexed owner, uint256 amount);
    event GameTokenAddressUpdated(address newGameTokenAddress);

    constructor(address _gameTokenAddress) Ownable(msg.sender) {
        gameToken = GameToken(_gameTokenAddress);
    }

    // Fixed token price (1 AVAX = 2 tokens)
    uint256 public tokenRate = 2; // 1 AVAX = 2 tokens

    // Receive function to accept AVAX transfers
    receive() external payable {
        uint256 avaxAmount = msg.value;

        // Calculate the number of tokens user can buy (1 AVAX = 2 tokens)
        uint256 tokensToMint = (avaxAmount / 1 ether) * tokenRate; // Only whole AVAX amounts are used

        // Log the receipt of AVAX and mint tokens
        emit TokensPurchased(msg.sender, avaxAmount, tokensToMint);

        // Mint tokens to the sender
        gameToken.mint(msg.sender, tokensToMint);
    }

    // Function to withdraw a specific amount of AVAX by the owner
    function withdrawAVAX(uint256 amountInAVAX) external onlyOwner {
        uint256 amountInWei = amountInAVAX * 1 ether; // Convert AVAX to wei
        uint256 balance = address(this).balance;
        require(
            balance >= amountInWei,
            "Not enough AVAX in contract to withdraw"
        );

        // Transfer the specified amount to the owner
        payable(owner()).transfer(amountInWei);

        // Emit event for the withdrawal
        emit AVAXWithdrawn(owner(), amountInWei);
    }

    // Function to check the balance of AVAX in the contract, in AVAX instead of wei
    function getBalance() external view returns (uint256) {
        return address(this).balance / 1 ether; // Convert wei to AVAX
    }

    // Function to update the GameToken address (only the owner can update it)
    function setGameTokenAddress(address _gameTokenAddress) external onlyOwner {
        require(_gameTokenAddress != address(0), "Invalid address");
        gameToken = GameToken(_gameTokenAddress);
        emit GameTokenAddressUpdated(_gameTokenAddress);
    }
}
