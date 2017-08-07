pragma solidity ^0.4.7;

import "./Crowdsale.sol";
import "./PecunioPricing.sol";
import "./MintableToken.sol";


contract PecunioCrowdsale is Crowdsale {
  using SafeMathLib for uint;

  // Are we on the "end slope" (triggered after soft cap)
  bool public softCapTriggered;

  // The default minimum funding limit 7,000,000 USD
  uint public minimumFundingUSD = 700000 * 10000;

  uint public hardCapUSD = 14000000 * 10000;

  function PecunioCrowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end)
    Crowdsale(_token, _pricingStrategy, _multisigWallet, _start, _end, 0) {
  }

  /// @dev triggerSoftCap triggers the earlier closing time
  function triggerSoftCap() private {
    if(softCapTriggered)
      throw;

    uint softCap = PecunioPricing(pricingStrategy).getSoftCapInWeis();

    if(softCap > weiRaised)
      throw;

    // When contracts are updated from upstream, you should use:
    // setEndsAt (now + 24 hours);
    endsAt = now + (3*24*3600);
    EndsAtChanged(endsAt);

    softCapTriggered = true;
  }

  /**
   * Hook in to provide the soft cap time bomb.
   */
  function onInvest() internal {
     if(!softCapTriggered) {
         uint softCap = PecunioPricing(pricingStrategy).getSoftCapInWeis();
         if(weiRaised > softCap) {
           triggerSoftCap();
         }
     }
  }

  /**
   * Get minimum funding goal in wei.
   */
  function getMinimumFundingGoal() public constant returns (uint goalInWei) {
    return PecunioPricing(pricingStrategy).convertToWei(minimumFundingUSD);
  }

  /**
   * Allow reset the threshold.
   */
  function setMinimumFundingLimit(uint usd) onlyOwner {
    minimumFundingUSD = usd;
  }

  /**
   * @return true if the crowdsale has raised enough money to be a succes
   */
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= getMinimumFundingGoal();
  }

  function getHardCap() public constant returns (uint capInWei) {
    return PecunioPricing(pricingStrategy).convertToWei(hardCapUSD);
  }

  /**
   * Reset hard cap.
   *
   * Give price in USD * 10000
   */
  function setHardCapUSD(uint _hardCapUSD) onlyOwner {
    hardCapUSD = _hardCapUSD;
  }

  /**
   * Called from invest() to confirm if the curret investment does not break our cap rule.
   */
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
    return weiRaisedTotal > getHardCap();
  }

  function isCrowdsaleFull() public constant returns (bool) {
    return weiRaised >= getHardCap();
  }

  /**
   * @return true we have reached our soft cap
   */
  function isSoftCapReached() public constant returns (bool reached) {
    return weiRaised >= PecunioPricing(pricingStrategy).getSoftCapInWeis();
  }


  /**
   * Dynamically create tokens and assign them to the investor.
   */
  function assignTokens(address receiver, uint tokenAmount) private {
    MintableToken mintableToken = MintableToken(token);
    mintableToken.mint(receiver, tokenAmount);
  }

}
