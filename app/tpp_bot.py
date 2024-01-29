import time
import pyautogui
import time
import random
import tools.find_image_tools as find_image_tools
import get_stats
import ui_stats
import twitch_chat
import tools.files_tools as files_tools
import config.config as config



mode_image = '../assets/mode.png'
turn_image = '../assets/your_turn.png'
play_image = '../assets/play_now.png'
confirm_image = '../assets/confirm.png'
test_image = '../assets/test.png'
close_image = '../assets/close.png'
in_game_image = '../assets/in_game.png'
participants_path = '../saves/participants.txt'
stats_path = '../saves/stats.txt'


class TppBot:
	
	def __init__(self):
		self.users = []
		self.messages = {}
		self.participants = files_tools.retrieveListFromFile(participants_path)

	def getUser(self, line):
		colons = line.count(":")
		colonless = colons-1
		separate = line.split(":", colons)
		user = separate[colonless].split("!", 1)[0]		
		return user
	
	def decodeMessage(self, line):
		colons = line.count(":")
		message = (line.split(":", colons))[colons]	
		message = message.replace(" ", "")
		return message

	def saveMessage(self, line):
		message = self.decodeMessage(line)
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


	def calculateVotation(self, ponderation=1.3):
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
		twitch_chat.sendMessage("The next command is: " + maxCommand)
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
					
	def startBot(self):			
		twitch_chat.joinchat()
		self.clearCommands()
		find_image_tools.moveMouseToCenter()
		while True:
			if find_image_tools.findImage(in_game_image):
				self.playGame()
			else:
				#self.awaitStartCommand()
				#time.sleep(random.randint(11, 19))
				self.startGame()
				self.persistParticipants()						

	
	def awaitStartCommand(self):
		while True:
			print("Waiting start command...")
			for line in twitch_chat.getMessages():
				message = self.decodeMessage(line)		
				print(message)																															
				if "!start" in message:
					return
			time.sleep(1)
		
	def startGame(self):
		print("Starting game...")
		time.sleep(1)
		find_image_tools.findAndMoveToImage(mode_image)
		time.sleep(1)
		find_image_tools.findAndMoveToImage(play_image)
		time.sleep(1)
		find_image_tools.findAndMoveToImage(confirm_image, 0.8, False)
		time.sleep(2)
		self.playGame()
		time.sleep(2)
		#we use this file to pass information to the ui thread, reload all data
		files_tools.saveListToFile(stats_path, ["-", "True"])

	def playGame(self):
		while True:
			print("Playing game...")
			#game ended
			if find_image_tools.findImage(close_image):
				print("Game ended")
				get_stats.isSpinWon()
				find_image_tools.findAndMoveToImage(close_image)
				break
			#our turn
			elif find_image_tools.findImage(turn_image):
				print("Our turn")
				self.getMessages()
				command = self.calculateVotation()
				#we use this file to pass information to the ui thread, the next command
				files_tools.saveListToFile(stats_path, [command, "False"])
				self.executeCommand(command)
				self.clearCommands()
				print("Turn ended")
			time.sleep(0.6)

	def getMessages(self):
		start_time = time.time()
		while time.time() - start_time < config.turn_timeout:
			print("Getting messages...")
			for line in twitch_chat.getMessages():
				user = self.getUser(line)																																	
				if(user not in self.users):
					message = self.saveMessage(line)		
					if message != "":
						self.users.append(user)		
						self.saveParticipant(user)
						print(user + " : " + message)	

	def saveParticipant(self, user):
		if user not in self.participants:
			self.participants.append(user)
	
	def persistParticipants(self):
		files_tools.saveListToFile(participants_path, self.participants)
			
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
		
	
