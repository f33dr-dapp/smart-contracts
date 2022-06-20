from brownie import (
    AddressBook,
    DataUri,
    ToString,
    Item,
    Token,
    Minter,
    Likes,
    Profile,
    Multicall,
    Multicall2,
)
import brownie
import json


def main():
    governance = brownie.accounts[0]
    bob = brownie.accounts[1]
    brownie.network.max_fee("25 gwei")
    brownie.network.priority_fee("2 gwei")

    # Deploy Multicall contracts on Localhost
    Multicall.deploy({"from": governance})
    Multicall2.deploy({"from": governance})

    # Deoloy the AddressBook contract
    addressBook = AddressBook.deploy(governance, {"from": governance})

    # Deploy all the app contracts
    token = Token.deploy("F33D Token", "F33D", 18, addressBook, {"from": governance})
    item = Item.deploy(
        "F33D Item",
        "F33DI",
        "https://images.f33dr.space/api/image/",
        addressBook,
        {"from": governance},
    )
    likes = Likes.deploy(addressBook, {"from": governance})
    minter = Minter.deploy(addressBook, {"from": governance})
    dataUri = DataUri.deploy({"from": governance})
    toString = ToString.deploy({"from": governance})
    profile = Profile.deploy(addressBook, {"from": governance})

    #  Set the addresses
    addressBook.setAddress("Token", token, {"from": governance})
    addressBook.setAddress("Item", item, {"from": governance})
    addressBook.setAddress("Likes", likes, {"from": governance})
    addressBook.setAddress("Minter", minter, {"from": governance})
    addressBook.setAddress("DataUri", dataUri, {"from": governance})
    addressBook.setAddress("ToString", toString, {"from": governance})
    addressBook.setAddress("Profile", profile, {"from": governance})

    minter.setProfile(
        "F33D Root",
        "F33D",
        "The very first F33D account",
        # "https://f33dr.space/logo.png",
        {"from": governance},
    )

    minter.post("Hello Earth!", {"from": governance})

    minter.setPrices(
        "50 ether",  # Post price in tokens
        "10 ether",  # Repost price in tokens
        "100 ether",  # Tokens back per like
        "0.01 ether",  # Like Price
        "0.002 ether",  # Like contract commission
        "50 ether",  # profile price in tokens
        {"from": governance},
    )

    minter.like(1, {"from": bob, "value": "0.01 ether"})
    minter.post("Hello Mars!", 1, {"from": bob})
    minter.like(2, {"from": governance, "value": "0.01 ether"})

    manifest = {
        "Token": token.address,
        "Item": item.address,
        "Likes": likes.address,
        "Minter": minter.address,
        "AddressBook": addressBook.address,
        "Profile": profile.address,
        "Multicall": Multicall[0].address,
        "Multicall2": Multicall2[0].address,
    }

    with open("manifest.json", "w") as outfile:
        json.dump(manifest, outfile)
