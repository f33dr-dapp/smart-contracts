# @version 0.3.3

from interfaces import IAddressValidator

implements: IAddressValidator

# @dev Private toStrig buffer
IDENTITY_PRECOMPILE: constant(address) = 0x0000000000000000000000000000000000000004

@pure
@external
def fromUint256(_value: uint256) -> String[78]:
    # Taken from Curve: https://github.com/curvefi/curve-veBoost/blob/0e51be10638df2479d9e341c07fafa940ef58596/contracts/VotingEscrowDelegation.vy#L423
    # NOTE: Odd that this works with a raw_call inside, despite being marked
    # a pure function
    if _value == 0:
        return "0"

    buffer: Bytes[78] = b""
    digits: uint256 = 78

    for i in range(78):
        # go forward to find the # of digits, and set it
        # only if we have found the last index
        if digits == 78 and _value / 10 ** i == 0:
            digits = i

        value: uint256 = ((_value / 10 ** (77 - i)) % 10) + 48
        char: Bytes[1] = slice(convert(value, bytes32), 31, 1)
        buffer = raw_call(
            IDENTITY_PRECOMPILE,
            concat(buffer, char),
            max_outsize=78,
            is_static_call=True
        )

    return convert(slice(buffer, 78 - digits, digits), String[78])


@external
@pure
def isValidContract(_name: String[12]) -> bool:
    """
    @dev Function to check if a contract is valid   
    """

    return _name == "ToString"