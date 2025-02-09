// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameToken is ERC20, Ownable {
    address public paymentContract;
    address public prizeContract;
    uint8 private _decimals = 0;

    constructor()
        ERC20("Capsule Factory 9000 Game Token", "CF9GT")
        Ownable(msg.sender)
    {}

    modifier onlyAuthorized() {
        require(
            msg.sender == paymentContract || msg.sender == prizeContract,
            "Not authorized"
        );
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function setPaymentContract(address _paymentContract) external onlyOwner {
        paymentContract = _paymentContract;
    }

    function setPrizeContract(address _prizeContract) external onlyOwner {
        prizeContract = _prizeContract;
    }

    function mint(address to, uint256 amount) external {
        require(
            msg.sender == paymentContract || msg.sender == owner(),
            "Only Payment Contract or Owner can mint"
        );
        // Ensure that minting is always a whole number
        require(
            amount == uint256(uint64(amount)),
            "Amount must be a whole number"
        );
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == prizeContract, "Only Prize Contract can burn");
        // Ensure burning is only done with whole numbers
        require(
            amount == uint256(uint64(amount)),
            "Amount must be a whole number"
        );
        _burn(from, amount);
    }
}
