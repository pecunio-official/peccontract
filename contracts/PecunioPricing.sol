pragma solidity ^0.4.6;

import "./PricingStrategy.sol";
import "./SafeMathLib.sol";
import "./Crowdsale.sol";
import "zeppelin/contracts/ownership/Ownable.sol";

/**
 * Fixed crowdsale pricing - everybody gets the same price.
 */
contract PecunioPricing is PricingStrategy, Ownable {

  using SafeMathLib for uint;

  // The conversion rate: how many weis is 1 USD
  // https://www.coingecko.com/en/price_charts/ethereum/usd
  // 120.34587901 is 1203458 (for USD)
  uint public usdRate;

  uint public usdScale = 10000;

  /* How many weis one token costs */
  uint public hardCapPrice = 12000;  // 1.2 * 10000 Expressed as CFH base points

  uint public softCapPrice = 10000;  // 1.0 * 10000 Expressed as CFH base points

  uint public softCapUSD = 6000000 * 10000; // Soft cap set in USD

  //Address of the ICO contract:
  Crowdsale public crowdsale;

  function PecunioPricing(uint initialUsdRate) {
    usdRate = initialUsdRate;
  }

  /// @dev Setting crowdsale for setConversionRate()
  /// @param _crowdsale The address of our ICO contract
  function setCrowdsale(Crowdsale _crowdsale) onlyOwner {

    if(!_crowdsale.isCrowdsale()) {
      throw;
    }

    crowdsale = _crowdsale;
  }

  /// @dev Here you can set the new USD/ETH rate
  /// @param _usdRate The rate how many weis is one USD
  function setConversionRate(uint _usdRate) onlyOwner {
    //Here check if ICO is active
    if(now > crowdsale.startsAt())
      throw;

    usdRate = _usdRate;
  }

  /**
   * Allow to set soft cap.
   */
  function setSoftCapUSD(uint _softCapUSD) onlyOwner {
    softCapUSD = _softCapUSD;
  }

  /**
   * Get USD/ETH pair as an integer.
   *
   * Used in distribution calculations.
   */
  function getEthUsdPrice() public constant returns (uint) {
    return usdRate / usdScale;
  }

  /**
   * Currency conversion
   *
   * @param  usd USD price * 100000
   * @return wei price
   */
  function convertToWei(uint usd) public constant returns(uint) {
    return usd.times(10**18) / usdRate;
  }

  /// @dev Function which tranforms USD softcap to weis
  function getSoftCapInWeis() public returns (uint) {
    return convertToWei(softCapUSD);
  }

  /**
   * Calculate the current price for buy in amount.
   *
   * @param  {uint amount} How many tokens we get
   */
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint) {

    uint multiplier = 10 ** decimals;
    if (weiRaised > getSoftCapInWeis()) {
      //Here SoftCap is not active yet
      return value.times(multiplier) / convertToWei(hardCapPrice);
    } else {
      return value.times(multiplier) / convertToWei(softCapPrice);
    }
  }

}
