# @version 0.3.3

from interfaces import IAddressValidator
from . import Token
from . import Likes

implements: IAddressValidator

interface AddressBook:
    def addressOf(_type: String[12]) -> address: view
    def governance() -> address: view

struct Metadata:
    content: String[128]
    publisher: address
    datetime: uint256
    parentId: uint256

interface Item:
    def ownerOf(_tokenId: uint256) -> address: view
    def mint(to: address, content: String[128], parentId: uint256) -> bool: nonpayable
    def tokenMetadata(arg0: uint256) -> Metadata: view

interface Profile:
    def setProfile(
        _address: address,
        _name: String[32],
        _username: String[32],
        _bio: String[256],
        _imageUrl: String[256],
        _isNft: bool,
        _nftContract: address,
        _nftTokenId: uint256
    ): nonpayable

addressBook: immutable(AddressBook)

postPriceInTokens: public(uint256) # in Tokens
repostPriceInTokens: public(uint256) # in Tokens
likeRewardsInTokens: public(uint256) # in Tokens
likePrice: public(uint256) # in ETH
comission: public(uint256) # in ETH
profilePrice: public(uint256) # in Tokens

@external
def __init__(
    _addressBook: address
):
    addressBook = AddressBook(_addressBook)

@external
def setPrices(
    _postPriceInTokens: uint256,
    _repostPriceInTokens: uint256,
    _likeRewardsInTokens: uint256,
    _likePrice: uint256,
    _comission: uint256,
    _profilePrice: uint256):

    assert msg.sender == addressBook.governance(), "Only governance can set prices"
    assert _likePrice >= _comission

    self.postPriceInTokens = _postPriceInTokens
    self.repostPriceInTokens = _repostPriceInTokens
    self.likeRewardsInTokens = _likeRewardsInTokens
    self.likePrice = _likePrice
    self.comission = _comission
    self.profilePrice = _profilePrice

@payable
@external
def post(_content: String[128], parentId: uint256 = 0):
    """
    @dev Function to post a new item
    """
    tokenContract: Token = Token(addressBook.addressOf("Token"))
    itemContract: Item = Item(addressBook.addressOf("Item"))

    if (parentId > 0 and self.repostPriceInTokens > 0):
        tokenContract.burn(msg.sender, self.repostPriceInTokens)
    else: 
        if (self.postPriceInTokens > 0):
            tokenContract.burn(msg.sender, self.postPriceInTokens)

    itemContract.mint(msg.sender, _content, parentId)
    

@payable
@external
def like(_itemId: uint256):
    """
    @dev Function to like a post
    """
    assert msg.value == self.likePrice

    itemContract: Item = Item(addressBook.addressOf("Item"))
    tokenContract: Token = Token(addressBook.addressOf("Token"))
    likesContract: Likes = Token(addressBook.addressOf("Likes"))

    ownerOfItem: address = itemContract.ownerOf(_itemId)
    parentId: uint256 = itemContract.tokenMetadata(_itemId).parentId
    ownerToPay: address = ownerOfItem

    if (parentId > 0):
        ownerOfParent: address = itemContract.ownerOf(parentId)
        if (msg.sender != ownerOfParent):
            ownerToPay = ownerOfParent

    assert ownerToPay != msg.sender, "You can't like your own post"
    assert ownerToPay != ZERO_ADDRESS, "You can't like a post that doesn't exist"
    
    ownerAmmount: uint256 = self.likePrice - self.comission
    if ownerAmmount > 0:
        send(ownerToPay, ownerAmmount)

    if ownerToPay != ownerOfItem:
        comission: uint256 = self.comission / 2
        if comission > 0:
            send(ownerOfItem, comission)

    if(self.likeRewardsInTokens > 0):
        tokenContract.mint(msg.sender, self.likeRewardsInTokens)

    likesContract.like(_itemId, msg.sender)


@external
def setProfile(
        _name: String[32],
        _username: String[32],
        _bio: String[256],
        _imageUrl: String[256] = "",
        _isNft: bool = False,
        _nftContract: address = ZERO_ADDRESS,
        _nftTokenId: uint256 = 0
    ):
    
    tokenContract: Token = Token(addressBook.addressOf("Token"))
    profileContract: Profile = Profile(addressBook.addressOf("Profile"))

    if (self.profilePrice > 0):
        tokenContract.burn(msg.sender, self.profilePrice)

    profileContract.setProfile(
        msg.sender,
        _name,
        _username,
        _bio,
        _imageUrl,
        _isNft,
        _nftContract,
        _nftTokenId,
    )


@external
def withdraw():
    """
    @dev Function to withdraw the comission
    """
    send(addressBook.governance(), self.balance)


@external
@pure
def isValidContract(_type: String[12]) -> bool:
    """
    @dev Function to check if a contract is valid   
    """

    return _type == "Minter"