// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";

contract OnjiBank {
    Token private token;

    mapping(address => uint256) public depositStart;
    mapping(address => uint256) public depositedAmountOf;
    mapping(address => uint256) public collateralEther;
    uint256 public apy = 10;

    event Deposit(address indexed user, uint256 etherAmount, uint256 timeStart);
    event Withdraw(
        address indexed user,
        uint256 etherAmount,
        uint256 depositTime,
        uint256 interest
    );
    event Borrow(
        address indexed user,
        uint256 collateralEtherAmount,
        uint256 borrowedTokenAmount
    );
    event PayOff(address indexed user, uint256 fee);

    constructor(Token _token) {
        token = _token;
    }

    function deposit() public payable {
        require(
            depositedAmountOf[msg.sender] == 0,
            "Error, deposit already active"
        );
        require(msg.value >= 1e16, "Error, deposit must be >= 0.01 ETH");

        depositedAmountOf[msg.sender] = msg.value;
        depositStart[msg.sender] = block.timestamp;

        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    function withdraw() public {
        require(
            depositedAmountOf[msg.sender] > 0,
            "Error, no previous deposit"
        );
        uint256 userBalance = depositedAmountOf[msg.sender]; //for event

        //Time for which the staking is done
        uint256 depositTime = block.timestamp - depositStart[msg.sender];

        //  Interest per second for 10% APY
        uint256 interestPerSecond =
            ((depositedAmountOf[msg.sender] *apy) / (100 * (365 days + 6 hours)));
        uint256 interest = interestPerSecond * depositTime;

        //send funds to user
        payable(msg.sender).transfer(depositedAmountOf[msg.sender]); //eth back to user
        token.mint(msg.sender, interest); //interest to user

        //reset depositer data
        depositStart[msg.sender] = 0;
        depositedAmountOf[msg.sender] = 0;

        emit Withdraw(msg.sender, userBalance, depositTime, interest);
    }

    function borrow() public payable {
        require(msg.value >= 1e16, "Error, collateral must be >= 0.01 ETH");
        require(collateralEther[msg.sender] == 0, "Error, loan already taken");

        //this Ether will be locked till user payOff the loan
        collateralEther[msg.sender] = msg.value;

        //calc tokens amount to mint, 50% of msg.value
        uint256 tokensToMint = collateralEther[msg.sender] / 2;

        //mint&send tokens to user
        token.mint(msg.sender, tokensToMint);

        emit Borrow(msg.sender, collateralEther[msg.sender], tokensToMint);
    }

    function payOff() public {
        require(collateralEther[msg.sender] != 0, "Error, loan not active");
        require(
            token.transferFrom(
                msg.sender,
                address(this),
                collateralEther[msg.sender] / 2
            ),
            "Error, can't receive tokens"
        ); //must approve dBank 1st

        uint256 fee = collateralEther[msg.sender] / 10; //calc 10% fee

        //send user's collateral minus fee
        payable(msg.sender).transfer(collateralEther[msg.sender] - fee);

        //reset borrower's data
        collateralEther[msg.sender] = 0; 

        emit PayOff(msg.sender, fee);
    }
}
