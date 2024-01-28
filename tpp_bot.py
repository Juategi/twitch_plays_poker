import socket
import time
import pyautogui
import cv2
import numpy as np
from PIL import ImageGrab
import time
import random

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
test_image = 'assets/test.png'
close_image = 'assets/close.png'
in_game_image = 'assets/in_game.png'

irc = socket.socket()
irc.settimeout(9)
irc.connect((SERVER, PORT))
irc.send((	"PASS " + PASS + "\n" +
	"NICK " + BOT + "\n" +
	"JOIN #" + CHANNEL + "\n").encode())

class TppBot:
	
	def __init__(self):
		self.users = []
		self.messages = {}

	def joinchat(self):
		Loading = True
		while Loading:
			readbuffer_join = irc.recv(1024)
			readbuffer_join = readbuffer_join.decode()
			print(readbuffer_join)
			for line in readbuffer_join.split("\n")[0:-1]:
				print(line)
				Loading = self.loadingComplete(line)
		irc.send("CAP REQ :twitch.tv/tags\r\n".encode())

	def loadingComplete(self, line):
		if("End of /NAMES list" in line):
			print("TwitchBot has joined " + CHANNEL + "'s Channel!")
			return False
		else:
			return True

	def sendMessage(self, message):
		messageTemp = "PRIVMSG #" + CHANNEL + " :" + message
		irc.send((messageTemp + "\n").encode())	

	def getUser(self, line):
		colons = line.count(":")
		colonless = colons-1
		separate = line.split(":", colons)
		user = separate[colonless].split("!", 1)[0]		
		return user

	def getMessage(self, line):
		colons = line.count(":")
		message = (line.split(":", colons))[colons]	
		message = message.replace(" ", "")
		if "!check" in message:
			self.messages['!check'] += 1
		elif "!fold" in message:
			self.messages['!fold'] += 1
		elif "!call" in message:
			self.messages['!call'] += 1
		elif "!allin" in message:
			self.messages['!allin'] += 1
		elif "!raise10" in message:
			self.messages['!raise10'] += 1
		elif "!raise11" in message:
			self.messages['!raise11'] += 1
		elif "!raise12" in message:
			self.messages['!raise12'] += 1
		elif "!raise13" in message:
			self.messages['!raise13'] += 1
		elif "!raise14" in message:
			self.messages['!raise14'] += 1
		elif "!raise15" in message:
			self.messages['!raise15'] += 1
		elif "!raise16" in message:
			self.messages['!raise16'] += 1
		elif "!raise17" in message:
			self.messages['!raise17'] += 1
		elif "!raise18" in message:
			self.messages['!raise18'] += 1
		elif "!raise19" in message:
			self.messages['!raise19'] += 1
		elif "!raise20" in message:
			self.messages['!raise20'] += 1
		elif  "!raise1" in message:
			self.messages['!raise1'] += 1
		elif "!raise2" in message:
			self.messages['!raise2'] += 1
		elif "!raise3" in message:
			self.messages['!raise3'] += 1
		elif "!raise4" in message:
			self.messages['!raise4'] += 1
		elif "!raise5" in message:
			self.messages['!raise5'] += 1
		elif "!raise6" in message:
			self.messages['!raise6'] += 1
		elif "!raise7" in message:
			self.messages['!raise7'] += 1
		elif "!raise8" in message:
			self.messages['!raise8'] += 1
		elif "!raise9" in message:
			self.messages['!raise9'] += 1
		else:
			message = ""
		return message


	def clearCommands(self):
		self.messages['!check'] = 0
		self.messages['!fold'] = 0
		self.messages['!call'] = 0
		self.messages['!allin'] = 0
		self.messages['!raise1'] = 0
		self.messages['!raise2'] = 0
		self.messages['!raise3'] = 0
		self.messages['!raise4'] = 0
		self.messages['!raise5'] = 0
		self.messages['!raise6'] = 0
		self.messages['!raise7'] = 0
		self.messages['!raise8'] = 0
		self.messages['!raise9'] = 0
		self.messages['!raise10'] = 0
		self.messages['!raise11'] = 0
		self.messages['!raise12'] = 0
		self.messages['!raise13'] = 0
		self.messages['!raise14'] = 0
		self.messages['!raise15'] = 0
		self.messages['!raise16'] = 0
		self.messages['!raise17'] = 0
		self.messages['!raise18'] = 0
		self.messages['!raise19'] = 0
		self.messages['!raise20'] = 0

		self.users.clear()

	def votation(self, ponderation=1.3):
		print("Votation...")
		max = self.messages['!check']
		maxCommand = '!check'
		if(self.messages['!fold'] > max):
			max = self.messages['!fold']
			maxCommand = '!fold'
		if(self.messages['!call'] > max):
			max = self.messages['!call']
			maxCommand = '!call'
		if(self.messages['!allin'] > max):
			max = self.messages['!allin']
			maxCommand = '!allin'
		numberRaises = self.calculateNumberRaises()
		if(numberRaises > max):
			maxCommand = self.calculateRaiseCommand(numberRaises, ponderation)
		print("The next command is: " + maxCommand)
		self.sendMessage("The next command is: " + maxCommand)
		return maxCommand

	def calculateNumberRaises(self):
		total = 0
		for key, votes in self.messages.items():
			if key.startswith('!raise'):
				total += votes
		return total

	#TODO: revisar, no funciona bien con ponderacion, probar con 1 solo comando
	def calculateRaiseCommand(self, totalVotes, ponderation=1.3):
		totalValue = 0
		for key, votes in self.messages.items():
			if key.startswith('!raise'):
				value = int(key.replace('!raise', ''))
				totalValue += (value/ponderation) * votes / totalVotes
		totalValue = int(round(totalValue))
		command = '!raise' + str(totalValue)
		print(command)
		return command 

	def executeCommand(self, command):
		if command == '!check':
			pyautogui.press('c')
		elif command == '!fold':
			pyautogui.press('f')
		elif command == '!call':
			pyautogui.press('l')
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
		elif command == '!raise11':
			pyautogui.press('q')
		elif command == '!raise12':
			pyautogui.press('w')
		elif command == '!raise13':
			pyautogui.press('e')
		elif command == '!raise14':
			pyautogui.press('r')
		elif command == '!raise15':
			pyautogui.press('t')
		elif command == '!raise16':
			pyautogui.press('y')
		elif command == '!raise17':
			pyautogui.press('u')
		elif command == '!raise18':
			pyautogui.press('i')
		elif command == '!raise19':
			pyautogui.press('o')
		elif command == '!raise20':
			pyautogui.press('p')


	def find_and_click_image(self, target_image_path, confidence_threshold=0.8):
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

				print("Image found " + target_image_path)
				break
			
			time.sleep(1)


	def find_and_move_image(self, target_image_path, confidence_threshold=0.8):
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

				# Move to the center of the found image
				pyautogui.moveTo(center_x, center_y)

				print("Image found " + target_image_path)				
				break
			
			time.sleep(1)

	
	def find_image(self, target_image_path, confidence_threshold=0.8):
		target_image = cv2.imread(target_image_path)		
		screen = np.array(ImageGrab.grab())
		result = cv2.matchTemplate(screen, target_image, cv2.TM_CCOEFF_NORMED)
		
		min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)

		if max_val >= confidence_threshold:		
			print("Image found " + target_image_path)		
			return True
		else:
			return False	
			
			
			

	def getMessages(self):
		start_time = time.time()
		while time.time() - start_time < 7:
			print("Getting messages...")
			try:
				readbuffer = irc.recv(1024).decode()
			except:
				readbuffer = ""
			for line in readbuffer.split("\r\n"):
				if line == "":
					continue
				if "PING :tmi.twitch.tv" in line:
					msgg = "PONG :tmi.twitch.tv\r\n".encode()
					irc.send(msgg)
					continue
				else:
					try:
						user = self.getUser(line)																																	
						if(user not in self.users):
							message = self.getMessage(line)		
							if message != "":
								self.users.append(user)		
								print(user + " : " + message)																
					except Exception as e:
						print("Error: " + str(e))
		

	def startBot(self):			
		self.joinchat()
		self.clearCommands()
		while True:
			if self.find_image(in_game_image):
				self.playGame()
			else:
				#TODO: check si hay viewers
				self.startGame()
				print("Waiting next game...")
			time.sleep(random.randint(31, 63))

	
	def startGame(self):
		print("Starting game...")
		time.sleep(1)
		self.find_and_click_image(mode_image)
		time.sleep(1)
		self.find_and_click_image(play_image)
		time.sleep(1)
		self.find_and_click_image(confirm_image)
		time.sleep(2)
		self.playGame()

	def playGame(self):
		while True:
			print("Playing game...")
			#game ended
			#TODO: revisar ingame si va, añadir win image
			if self.find_image(close_image):
				print("Game ended")
				self.find_and_click_image(close_image)
				break
			#our turn
			elif self.find_image(turn_image):
				print("Our turn")
				self.getMessages()
				self.executeCommand(self.votation())
				self.clearCommands()
				print("Turn ended")
			time.sleep(0.6)
	
	
def main():
	if __name__ =='__main__':	
		bot = TppBot()
		bot.startBot()
		#bot.find_image(turn_image, 0.8)
main()