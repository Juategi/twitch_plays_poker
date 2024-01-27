from tpp_bot import TppBot


def test_bot():
    bot = TppBot()
    test_votation()

def test_votation():
    bot = TppBot()
    bot.messages['!check'] = 10
    bot.messages['!fold'] = 0
    bot.messages['!call'] = 0
    bot.messages['!allin'] = 0
    bot.messages['!raise1'] = 0
    bot.messages['!raise2'] = 1
    bot.messages['!raise3'] = 10
    bot.messages['!raise4'] = 0
    bot.messages['!raise5'] = 0
    bot.messages['!raise6'] = 0
    bot.messages['!raise7'] = 0
    bot.messages['!raise8'] = 0
    bot.messages['!raise9'] = 0
    bot.messages['!raise10'] = 0
    bot.messages['!raise11'] = 0
    bot.messages['!raise12'] = 12
    bot.messages['!raise13'] = 0
    bot.messages['!raise14'] = 5
    bot.messages['!raise15'] = 0
    bot.messages['!raise16'] = 2
    bot.messages['!raise17'] = 2
    bot.messages['!raise18'] = 3
    bot.messages['!raise19'] = 4
    bot.messages['!raise20'] = 0
    print(bot.votation())
    

if __name__ == "__main__":
    test_bot()
    print("Everything passed")
