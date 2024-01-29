import tkinter as tk
import get_stats as stats
import config.config as config
window = tk.Tk()
balanceLabel = tk.Label(window, text="Total earned: 0€", fg="white", bg="black", font=("Arial", 28))
spinsLabel = tk.Label(window, text="Spins won: 0", fg="white", bg="black", font=("Arial", 28))
nextMoveLabel = tk.Label(window, text="Next move: ", fg="white", bg="black", font=("Arial", 28))

def createWindow():
    window.title("Stats")
    window.configure(bg="black")
    window.geometry("600x300+200+200") 
    nextMoveLabel.place(x=100, y=20)
    balanceLabel.place(x=100, y=100)
    spinsLabel.place(x=100, y=180)
    updateStats() 
    window.mainloop()

def updateStats():
    spins = stats.getSpinsWon()
    balance = stats.getBalance()
    earned = config.initial_balance - float(balance)
    if earned < 0:
        earned = 0
    balanceLabel.config(text="Total earned: " + str(earned) + "€")
    spinsLabel.config(text="Spins won: " + str(spins))

def updateNextMove(nextMove):
    nextMoveLabel.config(text="Next move: " + nextMove)

def main():
    if __name__ =='__main__':   
        createWindow()
#main()
