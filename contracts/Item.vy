# @version 0.3.3

from vyper.interfaces import ERC721
from vyper.interfaces import ERC165
from interfaces import IAddressValidator

implements: ERC721
implements: ERC165
implements: IAddressValidator

# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
    def onERC721Received(
            _operator: address,
            _from: address,
            _tokenId: uint256,
            _data: Bytes[1024]
        ) -> bytes32: view

interface AddressBook:
    def addressOf(_type: String[12]) -> address: view
    def governance() -> address: view
    
interface DataUri:
    def toDataURI(
        json: String[9000] 
    )  -> String[9000]: view

interface ToString:
    def fromUint256(_value: uint256) -> String[78]: view

interface Likes:
    def itemLikesCount(_itemId: uint256) -> uint256: view

struct Metadata:
    content: String[128]
    publisher: address
    datetime: uint256
    parentId: uint256
    

# EVENTS
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    tokenId: indexed(uint256)

event Approval:
    owner: indexed(address)
    approved: indexed(address)
    tokenId: indexed(uint256)

event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool


# STORAGE

addressBook: immutable(AddressBook)

idToOwner: HashMap[uint256, address]
idToApprovals: HashMap[uint256, address]
ownerToNFTokenCount: HashMap[address, uint256]
ownerToOperators: HashMap[address, HashMap[address, bool]]

# ERC721Metadata Interface
name: public(String[32])
symbol: public(String[32])
baseUri: public(String[128])

maxSupply: public(uint256)
tokenMetadata: public(HashMap[uint256, Metadata])
ownerToTokenIndex: HashMap[address, HashMap[uint256, uint256]]
tokenToChildren: public(HashMap[uint256, HashMap[uint256, bool]])
tokenToChildrenCount: public(HashMap[uint256, uint256])


# @dev Static list of supported ERC165 interface ids
SUPPORTED_INTERFACES: constant(bytes4[2]) = [
    # ERC165 interface ID of ERC165
    0x01ffc9a7,
    # ERC165 interface ID of ERC721
    0x80ac58cd,
]

@external
def __init__(_name: String[32], _symbol: String[32], _baseUri: String[128], _addressBook: address):
    self.name = _name
    self.symbol = _symbol
    self.baseUri = _baseUri
    addressBook = AddressBook(_addressBook)


@pure
@external
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Interface identification is specified in ERC-165.
    @param interface_id Id of the interface
    """
    return interface_id in SUPPORTED_INTERFACES

### VIEW FUNCTIONS ###
@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @dev Returns the number of NFTs owned by `_owner`.
         Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    @param _owner Address for whom to query the balance.
    """
    assert _owner != ZERO_ADDRESS
    return self.ownerToNFTokenCount[_owner]

@view
@external
def ownerOf(_tokenId: uint256) -> address:
    """
    @dev Returns the address of the owner of the NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId The identifier for an NFT.
    """
    owner: address = self.idToOwner[_tokenId]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
    return owner

@view
@external
def getApproved(_tokenId: uint256) -> address:
    """
    @dev Get the approved address for a single NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId ID of the NFT to query the approval of.
    """
    # Throws if `_tokenId` is not a valid NFT
    assert self.idToOwner[_tokenId] != ZERO_ADDRESS
    return self.idToApprovals[_tokenId]

@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    """
    @dev Checks if `_operator` is an approved operator for `_owner`.
    @param _owner The address that owns the NFTs.
    @param _operator The address that acts on behalf of the owner.
    """
    return (self.ownerToOperators[_owner])[_operator]


### TRANSFER FUNCTION HELPERS ###

@view
@internal
def _isApprovedOrOwner(_spender: address, _tokenId: uint256) -> bool:
    """
    @dev Returns whether the given spender can transfer a given token ID
    @param spender address of the spender to query
    @param tokenId uint256 ID of the token to be transferred
    @return bool whether the msg.sender is approved for the given token ID,
        is an operator of the owner, or is the owner of the token
    """
    owner: address = self.idToOwner[_tokenId]
    spenderIsOwner: bool = owner == _spender
    spenderIsApproved: bool = _spender == self.idToApprovals[_tokenId]
    spenderIsApprovedForAll: bool = (self.ownerToOperators[owner])[_spender]
    return (spenderIsOwner or spenderIsApproved) or spenderIsApprovedForAll

@internal
def _addTokenTo(_to: address, _tokenId: uint256):
    """
    @dev Add a NFT to a given address
         Throws if `_tokenId` is owned by someone.
    """
    # Throws if `_tokenId` is owned by someone
    assert self.idToOwner[_tokenId] == ZERO_ADDRESS
    # Change the owner
    self.idToOwner[_tokenId] = _to
    # Change count tracking
    self.ownerToTokenIndex[_to][self.ownerToNFTokenCount[_to]] =_tokenId
    self.ownerToNFTokenCount[_to] += 1

@internal
def _removeTokenFrom(_from: address, _tokenId: uint256):
    """
    @dev Remove a NFT from a given address
         Throws if `_from` is not the current owner.
    """
    # Throws if `_from` is not the current owner
    assert self.idToOwner[_tokenId] == _from
    # Change the owner
    self.idToOwner[_tokenId] = ZERO_ADDRESS
    # Change count tracking
    self.ownerToNFTokenCount[_from] -= 1
    
    found: bool = False    
    for i in range(MAX_UINT256):
        if i == self.ownerToNFTokenCount[_from]:
            break
        
        value: uint256 = self.ownerToTokenIndex[_from][i]
        if _tokenId == self.ownerToTokenIndex[_from][i]:
            found = True
        if found:
            value = self.ownerToTokenIndex[_from][i+1]
        self.ownerToTokenIndex[_from][i] = value
    
    self.ownerToTokenIndex[_from][self.ownerToNFTokenCount[_from]] = 0

@internal
def _clearApproval(_owner: address, _tokenId: uint256):
    """
    @dev Clear an approval of a given address
         Throws if `_owner` is not the current owner.
    """
    # Throws if `_owner` is not the current owner
    assert self.idToOwner[_tokenId] == _owner
    if self.idToApprovals[_tokenId] != ZERO_ADDRESS:
        # Reset approvals
        self.idToApprovals[_tokenId] = ZERO_ADDRESS

@internal
def _transferFrom(_from: address, _to: address, _tokenId: uint256, _sender: address):
    """
    @dev Exeute transfer of a NFT.
         Throws if contract is paused.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT. (NOTE: `msg.sender` not allowed in private function so pass `_sender`.)
         Throws if `_to` is the zero address.
         Throws if `_from` is not the current owner.
         Throws if `_tokenId` is not a valid NFT.
    """
    # Check requirements
    assert self._isApprovedOrOwner(_sender, _tokenId)
    # Throws if `_to` is the zero address
    assert _to != ZERO_ADDRESS
    # Clear approval. Throws if `_from` is not the current owner
    self._clearApproval(_from, _tokenId)
    # Remove NFT. Throws if `_tokenId` is not a valid NFT
    self._removeTokenFrom(_from, _tokenId)
    # Add NFT
    self._addTokenTo(_to, _tokenId)
    # Log the transfer
    log Transfer(_from, _to, _tokenId)


### TRANSFER FUNCTIONS ###

@external
def transferFrom(_from: address, _to: address, _tokenId: uint256):
    """
    @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT.
         Throws if `_from` is not the current owner.
         Throws if `_to` is the zero address.
         Throws if `_tokenId` is not a valid NFT.
    @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
            they maybe be permanently lost.
    @param _from The current owner of the NFT.
    @param _to The new owner.
    @param _tokenId The NFT to transfer.
    """
    self._transferFrom(_from, _to, _tokenId, msg.sender)

@external
def safeTransferFrom(
        _from: address,
        _to: address,
        _tokenId: uint256,
        _data: Bytes[1024]=b""
    ):
    """
    @dev Transfers the ownership of an NFT from one address to another address.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the
         approved address for this NFT.
         Throws if `_from` is not the current owner.
         Throws if `_to` is the zero address.
         Throws if `_tokenId` is not a valid NFT.
         If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
         the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
         NOTE: bytes4 is represented by bytes32 with padding
    @param _from The current owner of the NFT.
    @param _to The new owner.
    @param _tokenId The NFT to transfer.
    @param _data Additional data with no specified format, sent in call to `_to`.
    """
    self._transferFrom(_from, _to, _tokenId, msg.sender)
    if _to.is_contract: # check if `_to` is a contract address
        returnValue: bytes32 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)
        # Throws if transfer destination is a contract which does not implement 'onERC721Received'
        assert returnValue == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes32)

@external
def approve(_approved: address, _tokenId: uint256):
    """
    @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
         Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
         Throws if `_tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
         Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
    @param _approved Address to be approved for the given NFT ID.
    @param _tokenId ID of the token to be approved.
    """
    owner: address = self.idToOwner[_tokenId]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
    # Throws if `_approved` is the current owner
    assert _approved != owner
    # Check requirements
    senderIsOwner: bool = self.idToOwner[_tokenId] == msg.sender
    senderIsApprovedForAll: bool = (self.ownerToOperators[owner])[msg.sender]
    assert (senderIsOwner or senderIsApprovedForAll)
    # Set the approval
    self.idToApprovals[_tokenId] = _approved
    log Approval(owner, _approved, _tokenId)


@external
def setApprovalForAll(_operator: address, _approved: bool):
    """
    @dev Enables or disables approval for a third party ("operator") to manage all of
         `msg.sender`'s assets. It also emits the ApprovalForAll event.
         Throws if `_operator` is the `msg.sender`. (NOTE: This is not written the EIP)
    @notice This works even if sender doesn't own any tokens at the time.
    @param _operator Address to add to the set of authorized operators.
    @param _approved True if the operators is approved, false to revoke approval.
    """
    # Throws if `_operator` is the `msg.sender`
    assert _operator != msg.sender
    self.ownerToOperators[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)


@view
@external
def tokenByIndex(index: uint256) -> uint256:
    """
    @dev Returns the token ID of the token at the given index.
    @param index The index of the token.
    @return The token ID of the token at the given index.
    """
    assert index >= 0 and index <= self.maxSupply
    return index


@view
@external
def tokenOfOwnerByIndex(_owner: address, index: uint256) -> uint256:
    assert self.ownerToNFTokenCount[_owner] > index
    return self.ownerToTokenIndex[_owner][index]


@external
def mint(to: address, content: String[128], parentId: uint256 = 0) -> bool:
    """
    @dev Function to mint tokens
    """
    assert msg.sender == addressBook.addressOf("Minter")
    assert parentId <= self.maxSupply
    assert self.tokenMetadata[parentId].parentId == 0

    self.maxSupply += 1
    _tokenId: uint256 = self.maxSupply
    
    # Add NFT. Throws if `_tokenId` is owned by someone
    self._addTokenTo(to, _tokenId)
    self.tokenMetadata[_tokenId] = Metadata({
        content: content,
        publisher: to,
        datetime: block.timestamp,
        parentId: parentId
    })
    
    if parentId > 0:
        self.tokenToChildren[parentId][_tokenId] = True
        self.tokenToChildrenCount[parentId] += 1

    log Transfer(ZERO_ADDRESS, to, _tokenId)
    return True


@external
@pure
def isValidContract(_name: String[12]) -> bool:
    """
    @dev Function to check if a contract is valid   
    """

    return _name == "Item"

@external
@view
def tokenURI(_tokenId: uint256) -> String[9000]:
    """
    @dev Function to get the URI of a token
    """
    dataUri: DataUri = DataUri(addressBook.addressOf("DataUri"))
    toString: ToString = ToString(addressBook.addressOf("ToString"))
    likes: Likes = Likes(addressBook.addressOf("Likes"))

    metadata: Metadata = self.tokenMetadata[_tokenId]

    json: String[9000] = concat(
        "{",
        '"name": "',
        self.name,
        ' #',
        toString.fromUint256(_tokenId),
        '", "symbol": "',
        self.symbol,
        '", "image": "',
        self.baseUri,
        toString.fromUint256(_tokenId),
        '", "description": "',
        metadata.content,
        '", "atrributes": {',
        '"content": "',
        metadata.content,
        '", "likes": ',
        toString.fromUint256(likes.itemLikesCount(_tokenId)),
        ', "reposts": ',
        toString.fromUint256(self.tokenToChildrenCount[_tokenId]),
        '}',
        '}'
    )

    return dataUri.toDataURI(json)


@external
def updateBaseUri(_baseUri: String[128]):
    """
    @dev Function to update the base URI of a token
    """
    assert msg.sender == addressBook.governance()
    self.baseUri = _baseUri
