pragma solidity 0.8.10;

import "@OpenZeppelin/contracts/token/ERC20/IERC20.sol";
import "@OpenZeppelin/contracts/access/Ownable.sol";
import "@OpenZeppelin/contracts/utils/math/SafeMath.sol";

contract  lenderfile{
    
    using SafeMath for uint256;
       
       /* purpose of this smart contract :
       * lender creaate a loan offer and pushed to market
       *borrower take loan
       *borrower pays back loan
       *liquidate borrower and take collateral if borrower default
        */
   
   
       enum Status { initial, lent, paid, destroyed }
           Status status;
           Status constant defaultStatus = Status.initial;

         //uint256 a2zfee;

        struct offer{
         Status status;
         uint256 amount;
         uint256 collValue;
         uint256 duration; 
         
         address offerToken;
         address acceptedColl;

         address lender;
         address borrower;

         uint256 interestRate;
         uint256 expirationOffer;
        }

        Loan[] private loans;
        mapping(uint256 => Offer) public offers;

   
   /* +createOffer function makes the lender set his loan term and at that instant the money he is lendin out will be withdran from his wallet and locked in this contract  */
   function createOffer(address _offerToken, uint256 _amount, uint256 _collValue, address _acceptedColl, uint256 _duration, uint256 _expirationOffer, uint256 _interestRate) public returns (uint256) {
      offer.lender == msg.sender;

      require(_amount != 0);
      require(_interestRate != 0); 
      require(_duration != 0);
      require(_expirationOffer > block.timestamp);

      Loan memory Id = Loan (
         Status.initial,
         _amount,
         _collValue,
         _duration,
        _offerToken,
        _acceptedColl,
         address(0),
        _interestRate,
        _expirationOffer
 );

        offer.push(Id);
         uint256 id = loans.length - 1;

         IERC20.transferFrom(msg.sender, address(this), _amount);

        return id;

   }

/* this function is called by a borrwer who find interest in the loan terms and ready to take it. the borroer must provide the right collateral and at the instant of calling this function the collateraal is withdrawn from his wallet and locked uptill payment time */ 


  function takeOffer(uint256 id, address _owner) public {
     require(offer.status == Status.initial);

     Deed memory offer = offers[id];
     offer.borrower = _owner;
     offer.duration = uint40(block.timestamp) + offer.duration;
     offer.collValue = _collValue;
     offer.acceptedColl = _acceptedColl;

     offer.status = Status.lent;

     /* withdrawing the collateral as the borrower is taking a loan offer */
      IERC20.transferFrom(_owner, address(this), _collValue);


     /* sending the loan amount to the borrower */
      uint256 resortAmount = lastResortAmount(_offerAmount, _interest);

      IERC20.transfer(_owner, resortAmount);   


      emit offerTaken(id, _owner);
      
  }

 
  function payLoan(uint256 id) public  returns (bool) {
     require(offer.status = Status.lent);   

     offer.status = Status.paid;
     offer.amount = offer.amount(id);

    // IERC20.transferFrom(address(this), msg.sender, collValue(id));
     /* withdrawing collateral from the contract and send to the borrower at loan payment instance */
     IERC20.transfer(offer.collValue(id), offer.borrower(id));

     /*Taking the payment from borrower's wallet at instance of loan payment */
     IERC20.transferFrom(offer.borrower(id), offer.lender(id), offer.amount(id));

    emit LoanPaid(id, msg.sender);

     return true;  
     
  }
  
  /*  function a2zfee(uint256 _amount) internal returns (uint256){
        offer.amount = _amount;
         uint256 memory feeNum = 2;
         uint256 memory feeDen = 100;
         
         uint256 memory feepercent = div(feeNum, feeDen);

         uint256 a2zfee = mul(_amount, feepercent);

         return a2zfee;
   
    }

    */


   function lastResortAmount(uint256 _offerAmount, uint256 _interest) internal returns (uint256) {
     offer.amount = _offerAmount;
     offer.interestRate = _interest;
    // uint256 a2zfee = _a2zfee;

     uint256 endAmount = sub(_offerAmount, _interest);

     return endAmount;  

   }

/*todo 

liquidation machine function
pls i need help to make this and i will apprecaite help from the expert here..thanks
*/
}