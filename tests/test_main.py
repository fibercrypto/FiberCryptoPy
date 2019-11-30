import fibercryptopy


def test_TestRegisterSkycoinPlugin():
    SkycoinTicker = b"SKY"
    CoinHoursTicker = b"SKYCH"
    err, Temp = fibercryptopy.FC_util_AltcoinCaption(CoinHoursTicker)
    assert err == fibercryptopy.FC_OK
    assert Temp == b"Coin Hours"
    err, Temp = fibercryptopy.FC_util_AltcoinCaption(SkycoinTicker)
    assert err == fibercryptopy.FC_OK
    assert Temp == b"Skycoin"
