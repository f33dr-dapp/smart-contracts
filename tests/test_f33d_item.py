import pytest
import brownie


def test_mint(f33d_item, owner):
    content = "My first post"
    f33d_item.mint(owner, content, {"from": owner})
    balance = f33d_item.balanceOf(owner)
    assert balance == 1
    tokenId = f33d_item.tokenOfOwnerByIndex(owner, 0)
    assert tokenId == 1
    assert f33d_item.tokenContent(1) == content

    content = "My second post"
    f33d_item.mint(owner, content, {"from": owner})
    balance = f33d_item.balanceOf(owner)
    tokenId = f33d_item.tokenOfOwnerByIndex(owner, 1)
    assert tokenId == 2
    assert f33d_item.tokenContent(2) == content


def test_transfer(f33d_item, owner, bob):
    content = "My first post"
    f33d_item.mint(owner, content, {"from": owner})
    balance = f33d_item.balanceOf(owner)
    assert balance == 1
    tokenId = f33d_item.tokenOfOwnerByIndex(owner, 0)
    assert tokenId == 1
    assert f33d_item.tokenContent(1) == content

    content = "My second post"
    f33d_item.mint(owner, content, {"from": owner})
    balance = f33d_item.balanceOf(owner)
    tokenId = f33d_item.tokenOfOwnerByIndex(owner, 1)
    assert tokenId == 2
    assert f33d_item.tokenContent(2) == content

    f33d_item.transferFrom(owner, bob, 1, {"from": owner})
    balance = f33d_item.balanceOf(owner)
    assert balance == 1
    tokenId = f33d_item.tokenOfOwnerByIndex(owner, 0)
    assert tokenId == 2

    balance = f33d_item.balanceOf(bob)
    assert balance == 1
    tokenId = f33d_item.tokenOfOwnerByIndex(bob, 0)
    assert tokenId == 1
