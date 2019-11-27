import fibercryptopy


def test_TestRegisterSkycoinPlugin():
    assert 0 == 0
    SkycoinTicker = b"SKY"
    CoinHoursTicker = b"SKYCH"

    Temp = fibercryptopy.FC_util_AltcoinCaption(SkycoinTicker)
    assert Temp == "Skycoin"
    Temp = fibercryptopy.FC_util_AltcoinCaption(CoinHoursTicker)
    assert Temp == "Coin Hours"
