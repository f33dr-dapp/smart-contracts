# @version 0.3.3

from interfaces import IAddressValidator

implements: IAddressValidator

interface AddressBook:
    def addressOf(_type: String[12]) -> address: view
    
# External Interfaces
interface Item:
    def tokenByIndex(index: uint256) -> uint256: view

addressBook: immutable(AddressBook)

itemLikesCount: public(HashMap[uint256, uint256])
itemLikesAccounts: public(HashMap[uint256, HashMap[address, uint256]])

@external
def __init__(_addressBook: address):
    addressBook = AddressBook(_addressBook)


@external
def like(itemId: uint256, account: address):
    assert msg.sender == addressBook.addressOf("Minter")
    itemContract:Item = Item(addressBook.addressOf("Item"))
    assert itemContract.tokenByIndex(itemId) == itemId

    self.itemLikesCount[itemId] += 1
    self.itemLikesAccounts[itemId][account] += 1


@external
@pure
def isValidContract(_type: String[12]) -> bool:
    """
    @dev Function to check if a contract is valid   
    """

    return _type == "Likes"
