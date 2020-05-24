from vyper.interfaces import ERC20

implements: ERC20

Transfer: event({_from: indexed(address), _to: indexed(address), _value: uint256})
Approval: event({_owner: indexed(address), _spender: indexed(address), _value: uint256})

name: public(string[64])
symbol: public(string[32])
decimals: public(uint256)

# has the ability to add and remove creator addresses from the pool
admin: public(address)

# the address of the erc-20 token in which donations are made
cashToken: public(address(ERC20))

balanceOf: public(map(address, uint256))

# addrsses in the whitelist can have a share balance
# (allowing them to claim part of the donations to the pool)
whitelist: public(map(address, bool))

# sqrt of balance, for whitelisted addresses
shareBalanceOf: public(map(address, uint256))

# used to keep pool accounting accurate even as deposits and withdrawals are made
cashCredit: map(address, int128)
poolCashAdjustment: uint256

total_supply: uint256
total_share_supply: uint256


@private
@constant
def _getCashPerShare() -> uint256:
    poolCashBalance: uint256 = self.cashToken.balanceOf(self) + self.poolCashAdjustment
    return poolCashBalance / self.total_share_supply


@public
@constant
def getCashPerShare() -> uint256:
    return _getCashPerShare()

@private
@constant
def _withdrawableCashOf(who: address) -> uint256:
    cashPerShare: uint256 = self._getCashPerShare()

    whoseCashCredit: uint256 = 0
    creditIsNonNegative: bool = True
    if self.cashCredit[who] < 0:
        whoseCashCredit = convert(-self.cashCredit[who], uint256)
        creditIsNonNegative = False
    else:
        whoseCashCredit = convert(self.cashCredit[who], uint256)

    result: uint256 = poolCashBalance
    if self.total_share_supply != 0:
        if creditIsNonNegative:
            result = (cashPerShare * self.shareBalanceOf[who]) + whoseCashCredit
        else:
            result = (cashPerShare * self.shareBalanceOf[who]) - whoseCashCredit

    return result


@public
@constant
def withdrawableCashOf(who: address) -> uint256:
    return self._withdrawableCashOf(who)

@private
def _sqrt256(x: uint256) -> uint256:
    if x == 0:
        return x

    z: uint256 = (x + 1) / 2
    y: uint256 = x

    for i in range(256):
        if (z > y):
            break
        y = z
        z = (x / z + z) / 2

    return y


@private
def _setShareBalanceOf(who: address, newShareBalance: uint256):
    difference: uint256 = newShareBalance - self.shareBalanceOf[who]
    self.total_share_supply += difference
    self.shareBalanceOf[who] = newShareBalance


@private
def _recalculateShares(who: address):
    # the goal of this function is to keep the cash withdrawable by an address invariant,
    # even as their share count (proportion of future donation stream) is changing

    withdrawableCash: uint256 = self._withdrawableCashOf(who)

    newShareBalance: uint256 = self._sqrt256(self.balanceOf[who])
    self._setShareBalanceOf(who, newShareBalance)

    pendingWithdrawableCash: uint256 = self._withdrawableCashOf(who)

    assert withdrawableCash <= MAX_INT128 and pendingWithdrawableCash <= MAX_INT128
    self.cashCredit[who] += convert(withdrawableCash, int128) - convert(pendingWithdrawableCash, int128)


@public
def __init__(_name: string[64], _symbol: string[32], _decimals: uint256, _cash_token: address):
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.cashToken = ERC20(_cash_token)
    self.admin = msg.sender
    self.poolCashAdjustment = 0


@public
@constant
def totalSupply() -> uint256:
    return self.total_supply


@public
def setAdmin(who: address):
    assert msg.sender == self.admin

    self.admin = who


@public
def addToPool(who: address):
    assert msg.sender == self.admin

    self.whitelist[who] = True
    self._recalculateShares(who)


@public
def removeFromPool(who: address):
    assert msg.sender == self.admin

    self.whitelist[who] = False
    self._setShareBalanceOf(who, 0)


@public
def transfer(_to :address, _value :uint256) -> bool:
    # sender must be a donor
    assert not self.whitelist[msg.sender]

    # recipient must be a creator
    assert self.whitelist[_to]

    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value

    self._recalculateShares(_to)

    return True


@public
def mint(_to: address, _value: uint256):
    """
    @dev Generate DROPS tokens by making a donation to the pool.
    """
    whoseCashCredit: uint256 = convert(self.cashCredit[msg.sender], uint256)
    creditIsNonNegative: bool = True
    if self.cashCredit[msg.sender] < 0:
        whoseCashCredit = convert(-self.cashCredit[msg.sender], uint256)
        creditIsNonNegative = False

    assert _to != ZERO_ADDRESS

    # 1 DROPS token per cash token donated
    assert_modifiable(self.cashToken.transferFrom(msg.sender, self, _value))

    self.total_supply += _value
    self.balanceOf[_to] += _value

    log.Transfer(ZERO_ADDRESS, _to, _value)


@public
def withdrawDonations(amount: uint256):
    # the goal of this function is to keep the cash allocated to each share constant,
    # even when the total cash in the pool decreases (due to a withdrawal)
    # this is accomplished by tracking a debit to a creator's cash balance and crediting it to the pool

    withdrawableCash: uint256 = self._withdrawableCashOf(msg.sender)

    assert amount <= withdrawableCash
    assert amount <= MAX_INT128

    self.cashCredit[msg.sender] -= convert(amount, int128)

    assert_modifiable(self.cashToken.transfer(msg.sender, amount))


### UNUSED ###

@public
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
    return False

@public
def approve(_spender: address, _value: uint256) -> bool:
    return False

@public
@constant
def allowance(_owner: address, _spender: address) -> uint256:
    return 0
