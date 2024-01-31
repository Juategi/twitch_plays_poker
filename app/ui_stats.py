import tkinter as tk
import pyautogui
import get_stats as stats
import config.config as config
import tools.files_tools as files_tools
import time

stats_path = '../saves/stats.txt'

window = tk.Tk()
balanceLabel = tk.Label(window, text="Total earned: 0€", fg="white", bg="black", font=("Arial", 28))
spinsLabel = tk.Label(window, text="Spins won: 0", fg="white", bg="black", font=("Arial", 28))
nextMoveLabel = tk.Label(window, text="Last move: ", fg="white", bg="black", font=("Arial", 28))
startLabel= tk.Label(window, text="write !start in chat to start next game", fg="white", bg="black", font=("Arial", 36))

def createWindow():
    window.title("Stats")
    window.configure(bg="black")
    window.geometry("1600x1200+200+200") 
    #nextMoveLabel.place(x=1200, y=950)
    balanceLabel.place(x=1200, y=1010)
    spinsLabel.place(x=1200, y=1070)
    startLabel.place(x=50, y=600)
    updateStats() 
    time.sleep(1)
    checkForUpdates()
    window.mainloop()

def updateStats():
    spins = stats.getSpinsWon()
    balance = stats.getBalance()
    earned = config.initial_balance - float(balance)
    if earned < 0:
        earned = 0
    balanceLabel.config(text="Total earned: " + str(earned) + "€")
    spinsLabel.config(text="Spins won: " + str(spins))

def checkForUpdates():
    stats = files_tools.retrieveListFromFile(stats_path)
    #updateNextMove(stats[0])
    if stats[1] == "True":
        updateStats()
        files_tools.saveListToFile(stats_path, ["-", "False"])
    window.after(5000, checkForUpdates)

def updateNextMove(nextMove):
    nextMoveLabel.config(text="Last move: " + nextMove)

def main():
    if __name__ =='__main__':   
        createWindow()
main()
