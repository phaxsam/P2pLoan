pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract  lenderfile{
    
     using SafeMath for uint256;
       
       /* purpose of this smart contract :
       * lender creaate a loan offer and pushed to market
       *borrower take loan 
       *borrower pays back loan
       *liquidate borrower and take collateral if borrower defaults
        */
   
       address private a2zRevenue = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

      uint256 public activeOffers = 0;
      mapping(address => uint256) public borrowersBalance;
      uint256 public id;
      uint256 a2zfee;
   
       enum Status { initial, lent, paid, destroyed }
           Status status;
           Status constant defaultStatus = Status.initial;

         //uint256 a2zfee;

        struct Offer{
         Status status;
         uint256 offeredAmount;
         uint256 collValue;
         uint256 duration;
         uint256 dueTime; 
         
         IERC20 offerToken;
         IERC20 acceptedColl;

         address lender;
         address borrower;

         uint256 interestRate;
         uint256 expirationOffer;
        }

        Offer[] private loans;
        mapping(uint256 => Offer) public offers;

   
   /* +createOffer function makes the lender set his loan term and at that instant the money he is lending 
    will be withdran from his wallet and locked in this contract  *
     */
     function createOffer(
        address _offerToken,
        uint256 _offeredAmount, 
        uint256 _collvalue,
        address _acceptedColl, 
        uint256 _duration,
        uint256 _expirationOffer,
        uint256 _interestRate
         ) public returns (uint256) {
     // offer.lender == msg.sender;

      require(_offeredAmount != 0);
      require(IERC20(_offerToken).balanceOf(msg.sender) >= _offeredAmount);
      require(_interestRate != 0); 
      require(_duration != 0);
      require(_expirationOffer > block.timestamp);

      Offer storage offer = offers[id];
    offer.status = Status.initial;
    offer.offeredAmount = _offeredAmount;
    //offer.borrower = address(0);
    offer.lender = msg.sender;
    offer.offerToken = IERC20(_offerToken);
    offer.acceptedColl = IERC20(_acceptedColl);
    offer.duration = _duration;
    offer.expirationOffer = _expirationOffer;
    offer.interestRate = _interestRate;
    offer.collValue = _collvalue;
    

        loans.push(offer);
         uint256 id = loans.length - 1;

         IERC20(_offerToken).transferFrom(msg.sender, address(this), _offeredAmount);

        return id;

   }

/* this function is called by a borrwer who find interest in the loan terms and ready to take it.
 the borroer must provide the right collateral and at the instant of calling this function the collateraal is withdrawn from his wallet and locked uptill payment time 
 */
  function takeOffer(uint256 id, address _owner) public returns (bool) {

     Offer storage offer = offers[id];

     offer.status = Status.initial;
     offer.borrower = _owner;
     offer.duration = uint40(block.timestamp) + offer.duration;
     IERC20(offer.offerToken);
     offer.collValue;
     IERC20(offer.acceptedColl);

     offer.status = Status.lent;

     activeOffers += 1;
     borrowersBalance[offer.borrower] += 1;

     /* withdrawing the collateral as the borrower is taking a loan offer */
     IERC20(offer.acceptedColl).transferFrom(_owner, address(this), offer.collValue);

     /* sending the loan amount to the borrower */
      uint256 resortAmount = lastResortAmount(offer.offeredAmount, offer.interestRate);
      IERC20(offer.offerToken).transfer(_owner, resortAmount);



      uint256 lendersProfit = feeNum(offer.interestRate, feeDen(offer.interestRate, a2zfee));
      IERC20(offer.offerToken).transfer(offer.lender, lendersProfit); 

      uint256 azFinRevenue = feeDen(offer.interestRate, a2zfee);
      IERC20(offer.offerToken).transfer(a2zRevenue, azFinRevenue);

     // emit offerTaken(id, _owner);

     return true;
      
  }

 
  function payLoan(uint256 id) public  returns (bool) {
     Offer storage offer = offers[id];

     offer.status = Status.lent; 

     offer.borrower = msg.sender;  
      offer.offeredAmount;

     offer.status = Status.paid;
   
 
     activeOffers -= 1;
     borrowersBalance[offer.borrower] -= 1;
     // withdrawing collateral from the contract and send to the borrower at loan payment instance *
     IERC20(offer.acceptedColl).transfer(msg.sender, offer.collValue);

    // Taking the payment from borrower's wallet at instance of loan payment *
     IERC20(offer.offerToken).transferFrom(msg.sender, offer.lender, offer.offeredAmount);

   //  emit LoanPaid(id, msg.sender);

     return true;  
     
  }

  

   function lastResortAmount(uint256 _offerAmount, uint256 _interest) internal returns (uint256) {
      Offer storage offer = offers[id];
     
     offer.offeredAmount = _offerAmount;
     offer.interestRate = _interest;

     uint256 endAmount = _offerAmount - _interest;

     return endAmount;  

   }

   function feeDen(uint256 _tot, uint256 _tatn) internal returns (uint256){
      Offer storage offer = offers[id];

      offer.interestRate = _tot;
      a2zfee = _tatn;

      uint256 ketos  = _tot * _tatn;

      return ketos;
   }

   function feeNum(uint256 _cal, uint256 _coc) internal returns (uint256){
      Offer storage offer = offers[id];

      offer.interestRate = _cal;
       _coc = feeDen(offer.interestRate, a2zfee);

      uint256 calc = _cal - _coc;

      return calc;
   }

/*todo 

liquidation machine function
pls i need help to make this and i will apprecaite help from the expert here..thanks
**/
}
