# @version 0.3.3

from interfaces import IAddressValidator

addressOf: public(HashMap[String[12], address])
governance: public(address)
pendingGovernance: public(address)

@external
def __init__( _governance: address):
    self.governance = _governance
    

@external
def updateGovernance(newGovernance: address):
    """
    @dev Function to update the governance
    """
    assert msg.sender == self.governance
    self.pendingGovernance = newGovernance

@external
def acceptGovernance():
    """
    @dev Function to accept the governance change
    """
    assert msg.sender == self.pendingGovernance
    self.governance = self.pendingGovernance
    self.pendingGovernance = ZERO_ADDRESS


@external
def setAddress(_type: String[12], _address: address):
    """
    @dev Function to set an address
    """
    assert msg.sender == self.governance
    assert IAddressValidator(_address).isValidContract(_type) == True

    self.addressOf[_type] = _address