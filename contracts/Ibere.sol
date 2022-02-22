pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Ibere {  

using SafeMath for uint256;

uint256 public activeLoans = 0;
mapping(address => uint256) public lendersBalance;
uint256 public id;

uint256 a2zFee = 3;

enum Status{initial, lent, paid, destroyed}
Status status;
Status constant defaultStatus = Status.initial;



struct Request{
    Status status;
    uint256 requestedAmount;
    uint256 collvalue;
    uint256 duration;
    uint256 dueTime;

    address borrower;
    address lender;

    IERC20 requestedToken;
    IERC20 collToken;

    uint256 interestRate;
    uint256 expirationRequest;
}

Request[] private loans;
mapping(uint256 => Request) public requests;

function createRequest(
    address _borrower,
    uint256 _requestedAmount,
    address _requestedToken,
    address  _collToken,
    uint256 _expirationRequest,
    uint256 _interestRate,
    uint256 _collValue,
    uint256 _duration
) public returns (uint256){
   // require(_borrower = msg.sender & _borrower != address(0));
    require(_requestedAmount != 0);
    require(_interestRate != 0);
    require(_expirationRequest > block.timestamp);
    require(IERC20(_collToken).balanceOf(msg.sender) >= _collValue);
    
    
    Request storage request = requests[id];
    request.status = Status.initial;
    request.requestedAmount = _requestedAmount;
    request.borrower = msg.sender;
    request.lender = address(0);
    request.requestedToken = IERC20(_requestedToken);
    request.collToken = IERC20(_collToken);
    request.duration = _duration;
    request.expirationRequest = _expirationRequest;
    request.interestRate = _interestRate;
    request.collvalue = _collValue;
    
      loans.push(request);
         uint256 id = loans.length - 1;
      
    
     IERC20(_collToken).transferFrom(msg.sender, address(this), _collValue);

     //emit Requestcreated(id, msg.sender);

     return id;

}


function fillRequest(uint256 id) public returns(bool) {
     Request storage request = requests[id];

     request.status == Status.initial;
     require(request.expirationRequest >= block.timestamp);
     require(IERC20(request.requestedToken).balanceOf(msg.sender) >= request.requestedAmount);

     request.lender = msg.sender;
     request.dueTime = uint40(block.timestamp) + request.duration;
     request.status = Status.lent;

     activeLoans += 1;
     lendersBalance[request.lender] += 1;
     

     uint256 feeLast = fee(request.interestRate, a2zFee);
     
     IERC20(request.requestedToken).transferFrom(msg.sender, address(this), feeLast);

     uint256 lastAmount = resortAmount(request.interestRate, request.requestedAmount);

     IERC20(request.requestedToken).transferFrom(msg.sender, request.borrower, lastAmount);

    // emit requestedFilled(id, msg.sender);

     return true;
}


 
function payLoan(uint256 id, uint256 _amount, address _from) public returns (bool){
    Request storage request = requests[id];

    request.status == Status.lent;
    require(IERC20(request.requestedToken).balanceOf(msg.sender) >= _amount);

    request.requestedAmount = _amount;
    request.borrower = _from;

    request.status = Status.paid;
                   
    activeLoans -= 1;
    lendersBalance[request.lender] -=1;
     
     IERC20(request.collToken).transfer(_from, request.collvalue);
     IERC20(request.requestedToken).transferFrom(msg.sender, request.lender, request.requestedAmount);

     return true;
}    


function  fee(uint256 _interest, uint256 _a2zfee) internal returns (uint256) {
 Request storage request = requests[id];
    request.interestRate = _interest;
    a2zFee = _a2zfee;

    uint256 fees =  _interest * _a2zfee ;

    return fees;
}


function resortAmount(uint256 _interest, uint256 _amount) internal returns (uint256) {
  Request storage request = requests[id];

  request.interestRate  = _interest;
  request.requestedAmount = _amount;

    uint256 amount = _amount - _interest ;

    return amount;

}

function liquidate(uint256 id) internal returns (bool){
    Request storage request = requests[id];
    request.status = Status.lent;
    uint40(block.timestamp) <= request.duration;
        lendersBalance[request.lender] -=1;
        activeLoans -=1;

        IERC20(request.collToken).transfer(request.lender, request.collvalue);

        return true;
    
}
   
}