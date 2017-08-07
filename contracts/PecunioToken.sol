pragma solidity ^0.4.7;

import "./CrowdsaleToken.sol";

contract PecunioToken is CrowdsaleToken {
  function PecunioToken(string _name, string _symbol, uint _initialSupply, uint _decimals)
   CrowdsaleToken(_name, _symbol, _initialSupply, _decimals) {
  }
}
