from tpp_bot import TppBot
import ui_stats
import threading

def main():
    if __name__ =='__main__':   
        bot = TppBot()
        #thread = threading.Thread(target=bot.startBot)
        #thread.start()
        #ui_stats.createWindow()
        #ui_stats.updateNextMove("test")
        bot.startBot()
main()