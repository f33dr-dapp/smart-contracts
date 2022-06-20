import pytest
import brownie


def test_metadata(f33d_token):
    assert f33d_token.name() == "My Token"
    assert f33d_token.symbol() == "MYT"
    assert f33d_token.decimals() == 18
    assert f33d_token.totalSupply() == 1000000 * 10**18


def test_ownership(f33d_token, owner):
    assert f33d_token.balanceOf(owner) == f33d_token.totalSupply()


def test_transfer(f33d_token, owner, bob):
    owner_balance = f33d_token.balanceOf(owner)
    transfer_value = 100

    f33d_token.transfer(bob, transfer_value, {"from": owner})

    assert f33d_token.balanceOf(bob) == transfer_value
    assert f33d_token.balanceOf(owner) == owner_balance - transfer_value


def test_allowance(f33d_token, owner, bob):
    transfer_value = 100
    f33d_token.approve(bob, transfer_value, {"from": owner})

    assert f33d_token.allowance(owner, bob) == transfer_value


def test_transfer_from(f33d_token, owner, bob, alice):
    owner_balance = f33d_token.balanceOf(owner)
    approval_value = 100
    transfer_value = 10

    f33d_token.approve(bob, approval_value, {"from": owner})
    f33d_token.transferFrom(owner, alice, transfer_value, {"from": bob})

    assert f33d_token.balanceOf(owner) == owner_balance - transfer_value
    assert f33d_token.balanceOf(alice) == transfer_value
    assert f33d_token.allowance(owner, bob) == approval_value - transfer_value


def test_should_fail_transfer_zero_value(f33d_token, owner, bob):
    with brownie.reverts():
        f33d_token.transfer(bob, 0, {"from": owner})


def test_should_fail_transfer_from_zero_value(f33d_token, owner, bob, alice):
    with brownie.reverts():
        f33d_token.transferFrom(owner, alice, 0, {"from": bob})
