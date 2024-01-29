from tpp_bot import TppBot
import ui_stats
import threading

def main():
    if __name__ =='__main__':   
        #windowThread = threading.Thread(target=ui_stats.createWindow)
        #windowThread.start()
        bot = TppBot()
        bot.startBot()       
main()