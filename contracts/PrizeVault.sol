// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PrizeVault is Ownable, IERC721Receiver {
    struct Prize {
        uint256 prizeId;
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        string size;
    }

    IERC20 public gameToken;
    mapping(uint256 => Prize) public prizes;
    uint256 public prizeCount = 0;

    event PrizeDeposited(
        uint256 prizeId,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        string size
    );
    event PrizeAwarded(address indexed winner, uint256 prizeId);

    constructor(address _gameTokenAddress) Ownable(msg.sender) {
        gameToken = IERC20(_gameTokenAddress);
    }

    function depositERC20Prize(
        address tokenAddress,
        uint256 amountPerPrize,
        uint256 quantity,
        string memory size
    ) external onlyOwner {
        require(
            amountPerPrize > 0 && quantity > 0,
            "Invalid prize amount or quantity"
        );
        uint256 totalAmount = amountPerPrize * quantity;
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            totalAmount
        );

        for (uint256 i = 0; i < quantity; i++) {
            prizes[prizeCount] = Prize(
                prizeCount,
                tokenAddress,
                0,
                amountPerPrize,
                size
            );
            emit PrizeDeposited(
                prizeCount,
                tokenAddress,
                0,
                amountPerPrize,
                size
            );
            prizeCount++;
        }
    }

    function depositNFTPrizes(
        address tokenAddress,
        uint256[] memory tokenIds,
        string memory size
    ) external onlyOwner {
        require(tokenIds.length > 0, "Must provide at least one token ID");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
            prizes[prizeCount] = Prize(
                prizeCount,
                tokenAddress,
                tokenIds[i],
                0,
                size
            );
            emit PrizeDeposited(prizeCount, tokenAddress, tokenIds[i], 0, size);
            prizeCount++;
        }
    }

    function claimPrize() external {
        require(prizeCount > 0, "No prizes available");
        require(
            gameToken.balanceOf(msg.sender) >= 1,
            "Must own at least 1 GameToken"
        );

        gameToken.transferFrom(msg.sender, address(this), 1);

        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    msg.sender,
                    blockhash(block.number - 1)
                )
            )
        );
        uint256 prizeId = randomHash % prizeCount;

        while (prizes[prizeId].tokenAddress == address(0)) {
            prizeId = (prizeId + 1) % prizeCount;
        }

        Prize memory prize = prizes[prizeId];
        emit PrizeAwarded(msg.sender, prizeId);

        if (prize.amount > 0) {
            IERC20(prize.tokenAddress).transfer(msg.sender, prize.amount);
        } else {
            IERC721(prize.tokenAddress).safeTransferFrom(
                address(this),
                msg.sender,
                prize.tokenId
            );
        }

        delete prizes[prizeId];
        prizeCount--; // Decrease total prize count
    }

    function getPrizeCount() external view returns (uint256) {
        return prizeCount;
    }

    function onERC721Received(
        address, // Removed the 'operator' name
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
