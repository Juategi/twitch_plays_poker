import socket
import threading
import time
import pyautogui
import cv2
import numpy as np
from PIL import ImageGrab

SERVER = "irc.twitch.tv"
PORT = 6667

#Your OAUTH Code Here https://twitchapps.com/tmi/
PASS = "oauth:4ea2kl3jjpiaocf49lyhcin5r4830e"

#What you'd like to name your bot
BOT = "twitchplayspokerstars"

#The channel you want to monitor
CHANNEL = "twitchplayspokerstars"

#Your account
OWNER = "twitchplayspokerstars"

mode_image = 'assets/mode.png'
turn_image = 'assets/your_turn.png'
play_image = 'assets/play_now.png'
confirm_image = 'assets/confirm.png'

message = ""
user = ""
messages = {}
users = []


irc = socket.socket()

irc.connect((SERVER, PORT))
irc.send((	"PASS " + PASS + "\n" +
			"NICK " + BOT + "\n" +
			"JOIN #" + CHANNEL + "\n").encode())

def joinchat():
	Loading = True
	while Loading:
		readbuffer_join = irc.recv(1024)
		readbuffer_join = readbuffer_join.decode()
		print(readbuffer_join)
		for line in readbuffer_join.split("\n")[0:-1]:
			print(line)
			Loading = loadingComplete(line)
	irc.send("CAP REQ :twitch.tv/tags\r\n".encode())

def loadingComplete(line):
	if("End of /NAMES list" in line):
		print("TwitchBot has joined " + CHANNEL + "'s Channel!")
		#sendMessage(irc, "Hello World!")
		return False
	else:
		return True

def sendMessage(irc, message):
	messageTemp = "PRIVMSG #" + CHANNEL + " :" + message
	irc.send((messageTemp + "\n").encode())

def getUser(line):
	#global user
	colons = line.count(":")
	colonless = colons-1
	separate = line.split(":", colons)
	user = separate[colonless].split("!", 1)[0]		
	return user

def getMessage(line):
	#global message
	colons = line.count(":")
	message = (line.split(":", colons))[colons]		
	if message == "!check":
		messages['!check'] += 1
	elif message == "!fold":
		messages['!fold'] += 1
	elif message == "!call":
		messages['!call'] += 1
	elif message == "!allin":
		messages['!allin'] += 1
	elif  message == "!raise1":
		messages['!raise1'] += 1
	elif message == "!raise2":
		messages['!raise2'] += 1
	elif message == "!raise3":
		messages['!raise3'] += 1
	elif message == "!raise4":
		messages['!raise4'] += 1
	elif message == "!raise5":
		messages['!raise5'] += 1
	elif message == "!raise6":
		messages['!raise6'] += 1
	elif message == "!raise7":
		messages['!raise7'] += 1
	elif message == "!raise8":
		messages['!raise8'] += 1
	elif message == "!raise9":
		messages['!raise9'] += 1
	elif message == "!raise10":
		messages['!raise10'] += 1
	elif message == "!raise15":
		messages['!raise15'] += 1
	return message


def clearCommands():
	messages['!check'] = 0
	messages['!fold'] = 0
	messages['!call'] = 0
	messages['!allin'] = 0
	messages['!raise1'] = 0
	messages['!raise2'] = 0
	messages['!raise3'] = 0
	messages['!raise4'] = 0
	messages['!raise5'] = 0
	messages['!raise6'] = 0
	messages['!raise7'] = 0
	messages['!raise8'] = 0
	messages['!raise9'] = 0
	messages['!raise10'] = 0
	messages['!raise15'] = 0

	users.clear()

def votation():
	max = messages['!check']
	maxCommand = '!check'
	for key, value in messages.items():
		if value > max:
			max = value
			maxCommand = key
	if max == 0:
		return ""
	sendMessage(irc, "The next command is: " + maxCommand)
	clearCommands()
	return maxCommand

def executeCommand(command):
	if command == '!check':
		pyautogui.press('c')
	elif command == '!fold':
		pyautogui.press('f')
	elif command == '!call':
		pyautogui.press('i')
	elif command == '!allin':
		pyautogui.press('a')
	elif command == '!raise1':
		pyautogui.press('1')
	elif command == '!raise2':
		pyautogui.press('2')
	elif command == '!raise3':
		pyautogui.press('3')
	elif command == '!raise4':
		pyautogui.press('4')
	elif command == '!raise5':
		pyautogui.press('5')
	elif command == '!raise6':
		pyautogui.press('6')
	elif command == '!raise7':
		pyautogui.press('7')
	elif command == '!raise8':
		pyautogui.press('8')
	elif command == '!raise9':
		pyautogui.press('9')
	elif command == '!raise10':
		pyautogui.press('0')
	elif command == '!raise15':
		pyautogui.press('-')

def find_image_on_screen(target_image_path, confidence_threshold=0.8):
    target_image = cv2.imread(target_image_path)
    screen = np.array(ImageGrab.grab())
    result = cv2.matchTemplate(screen, target_image, cv2.TM_CCOEFF_NORMED)
    
    min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)

    if max_val >= confidence_threshold:
        return True
    else:
        return False
	
def find_and_click_image(target_image_path, confidence_threshold=0.8):
    target_image = cv2.imread(target_image_path)
    
    while True:
        screen = np.array(ImageGrab.grab())
        result = cv2.matchTemplate(screen, target_image, cv2.TM_CCOEFF_NORMED)
        
        min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)

        if max_val >= confidence_threshold:
            # Get the coordinates of the top-left corner of the found image
            top_left_x, top_left_y = max_loc

            # Get the width and height of the found image
            h, w = target_image.shape[:2]

            # Calculate the center coordinates of the found image
            center_x = top_left_x + w // 2
            center_y = top_left_y + h // 2

            # Click on the center of the found image
            pyautogui.click(center_x, center_y)

            print("¡Imagen encontrada y clic realizada!")
            # Puedes realizar acciones adicionales aquí si es necesario
            break
        
        time.sleep(1)


def getMessages():
	while True:
			try:
				readbuffer = irc.recv(1024).decode()
			except:
				readbuffer = ""
			for line in readbuffer.split("\r\n"):
				if line == "":
					continue
				if "PING :tmi.twitch.tv" in line:
					#print(line)
					msgg = "PONG :tmi.twitch.tv\r\n".encode()
					irc.send(msgg)
					#print(msgg)
					continue
				else:
					try:
						user = getUser(line)
						message = getMessage(line)		
						print(user + " : " + message)														
						#print(messages)
						executeCommand(votation())
						if(user not in users):
							users.append(user)
							print(users)
							#message = getMessage(line)											
							#print(messages)
					except Exception:
						print("Error")
	

def twitch():	
	joinchat()
	clearCommands()
	getMessages()
	
	

def main():
	if __name__ =='__main__':
		find_and_click_image(turn_image)
main()