from get_stats import getBalance
from tpp_bot import TppBot


def test_bot():
    bot = TppBot()
    test_votation()

def test_votation():
    bot = TppBot()
    bot.messages['!check'] = 0
    bot.messages['!fold'] = 0
    bot.messages['!call'] = 0
    bot.messages['!allin'] = 0
    bot.messages['!raise1'] = 0
    bot.messages['!raise2'] = 10
    bot.messages['!raise3'] = 0
    bot.messages['!raise4'] = 0
    bot.messages['!raise5'] = 0
    bot.messages['!raise6'] = 0
    bot.messages['!raise7'] = 0
    bot.messages['!raise8'] = 0
    bot.messages['!raise9'] = 0
    bot.messages['!raise10'] = 0
    bot.messages['!raise11'] = 0
    bot.messages['!raise12'] = 0
    bot.messages['!raise13'] = 0
    bot.messages['!raise14'] = 0
    bot.messages['!raise15'] = 1
    bot.messages['!raise16'] = 1
    bot.messages['!raise17'] = 0
    bot.messages['!raise18'] = 0
    bot.messages['!raise19'] = 0
    bot.messages['!raise20'] = 0
    print(bot.calculateVotation(ponderation=1))
    

if __name__ == "__main__":
    print(getBalance())
