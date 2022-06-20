# @version 0.3.3

from vyper.interfaces import ERC721
from interfaces import IAddressValidator

implements: IAddressValidator

interface AddressBook:
    def addressOf(_type: String[12]) -> address: view

addressBook: immutable(AddressBook)

struct ProfileData:
    name: String[32]
    username: String[32]
    imageUrl: String[256]
    bio: String[256]
    isNft: bool
    nftContract: address
    nftTokenId: uint256

accounts: HashMap[address, ProfileData]
usernames: HashMap[String[32], address]

@external
def __init__(_addressBook: address):
    addressBook = AddressBook(_addressBook)

@external
@pure
def isValidContract(_type: String[12]) -> bool:
    """
    @dev Function to check if a contract is valid   
    """

    return _type == "Profile"

@external 
def setProfile(
        _address: address,
        _name: String[32],
        _username: String[32],
        _bio: String[256],
        _imageUrl: String[256],
        _isNft: bool,
        _nftContract: address,
        _nftTokenId: uint256
    ):
    """
    @dev Function to set profile data
    """
    assert msg.sender == addressBook.addressOf("Minter")
    assert _username != "", "Username cannot be empty"
    assert _name != "", "Name cannot be empty"

    usernameOwner: address = self.usernames[_username]
    assert usernameOwner == _address or usernameOwner == empty(address), "Username already in use"
    
    if _isNft:
        nft:ERC721 = ERC721(_nftContract)
        assert nft.ownerOf(_nftTokenId) == _address, "Token not owned by user"


    lastProfile: ProfileData = self.accounts[_address]

    self.accounts[_address] = ProfileData({
        name: _name,
        username: _username,
        imageUrl: _imageUrl,
        bio: _bio,
        isNft: _isNft,
        nftContract: _nftContract,
        nftTokenId: _nftTokenId
    })

    if lastProfile.username != _username:
        self.usernames[lastProfile.username] = empty(address)
        self.usernames[_username] = _address

@view
@external
def getProfile(_address: address) -> ProfileData:
    """
    @dev Function to get profile data
    """
    account: ProfileData = self.accounts[_address]

    if (account.isNft):
        nft:ERC721 = ERC721(account.nftContract)
        if (nft.ownerOf(account.nftTokenId) != _address):
            account.nftTokenId = 0
            account.nftContract = ZERO_ADDRESS
            account.isNft = False

    return account