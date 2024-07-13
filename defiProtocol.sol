// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SimpleNFT.sol";


//custom error
error _invalid_Rate();
error _depositmustbegreaterthanzero();
error _insufficientBalance();
error _insufficentLiquidity();
error _noLoantoRepay();

contract DeFiLending {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public loans;
    uint256 public totalDeposits;
    uint256 public totalLoans;
    uint256 public interestRate; // Annual interest rate in basis points (1% = 100 basis points)

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Loan(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);

    constructor(uint256 _interestRate) {
        interestRate = _interestRate;
    }
//modifiers
    modifier validateInterest(uint256 _interestRate){
        require(_interestRate != 0, "invalid Rate");
        _;

        if(_interestRate != 0){
            revert _invalid_Rate();
        }
        _;
    }

    modifier depositMustBeGreaterThanZero(uint256 _depositmustbegreaterthan){
        require(msg.value > 0, "Deposit Must be Greater than Zero");
        _;
    }

    modifier insufficientBalance(uint256 _amount){
        require(deposits [msg.sender] <= _amount, "You have Insufficient Balance");
        _;
    }

    modifier insufficentLiquidity(uint256 _amount){
        require(totalDeposits <= _amount, "Insufficient Liquidity");
        _;
    }

    modifier noLoantoRepay(uint256 _amount){
        require(loans[msg.sender] <= _amount, "No Loan to Repay");
        _;
    }

     function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external {
        require(deposits[msg.sender] >= _amount, "Insufficient balance");
        deposits[msg.sender] -= _amount;
        totalDeposits -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    function borrow(uint256 _amount) external {
        require(totalDeposits >= totalLoans + _amount, "Insufficient liquidity");
        loans[msg.sender] += _amount;
        totalLoans += _amount;
        payable(msg.sender).transfer(_amount);
        emit Loan(msg.sender, _amount);
    }

     function repay() external payable {
        require(loans[msg.sender] > 0, "No loan to repay");
        uint256 interest = (loans[msg.sender] * interestRate) / 10000;
        uint256 totalRepayment = loans[msg.sender] + interest;
        require(msg.value >= totalRepayment, "Insufficient repayment amount");

        loans[msg.sender] = 0;
        totalLoans -= msg.value - interest;
        emit Repay(msg.sender, msg.value);
    }


    function calculateInterest(uint256 _amount) public view returns (uint256) {
        return (_amount * interestRate) / 10000;
    }
}
