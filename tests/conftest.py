import pytest
from brownie import accounts


@pytest.fixture(scope="function", autouse=True)
def shared_setup(fn_isolation):
    pass


# Accounts
@pytest.fixture
def owner():
    yield accounts[0]


@pytest.fixture
def bob():
    yield accounts[1]


@pytest.fixture
def alice():
    yield accounts[2]


@pytest.fixture
def f33d_token(F33DToken, owner):
    token = F33DToken.deploy(1000000, "My Token", "MYT", 18, {"from": owner})
    yield token


@pytest.fixture
def f33d_item(F33DItem, owner):
    nft = F33DItem.deploy(owner, owner, {"from": owner})
    yield nft
