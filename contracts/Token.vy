# @version 0.3.3

from vyper.interfaces import ERC20
from vyper.interfaces import ERC20Detailed
from interfaces import IAddressValidator

implements: ERC20
implements: ERC20Detailed
implements: IAddressValidator

interface AddressBook:
    def addressOf(_type: String[12]) -> address: view

# Declaring the events

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

# Declaring the storage variables

addressBook: immutable(AddressBook)

totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
name: public(String[32])
symbol: public(String[4])
decimals: public(uint8)


@external
def __init__(
    _name: String[32], 
    _symbol: String[4], 
    _decimals: uint8, 
    _addressBook: address
):
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    addressBook = AddressBook(_addressBook)

@external
def transfer(_to: address, _value: uint256) -> bool:
    assert _value > 0, "Value must be greater than 0"

    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value

    log Transfer(msg.sender, _to, _value)
    return True

@external 
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
    assert _value > 0, "Value must be greater than 0"
    
    self.allowance[_from][msg.sender] -= _value
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value

    log Transfer(_from, _to, _value)
    return True

@external
def approve(_spender: address, _value: uint256) -> bool:
    self.allowance[msg.sender][_spender] = _value

    log Approval(msg.sender, _spender, _value)
    return True

@external
def mint(_to: address, _value: uint256):
    """
    @dev Function to mint tokens
    """
    assert msg.sender == addressBook.addressOf("Minter")
    
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)


@external
def burn(_from: address, _value: uint256):
    """
    @dev Function to burn tokens
    """
    assert msg.sender == addressBook.addressOf("Minter")
    
    self.balanceOf[_from] -= _value
    self.totalSupply -= _value
    log Transfer(_from, ZERO_ADDRESS, _value)


@external
@pure
def isValidContract(_type: String[12]) -> bool:
    """
    @dev Function to check if a contract is valid   
    """

    return _type == "Token"