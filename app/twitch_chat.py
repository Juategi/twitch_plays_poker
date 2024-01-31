import socket
import os
from dotenv import load_dotenv
import config.config as config

SERVER = "irc.twitch.tv"
PORT = 6667
PORT = 6667

#Your OAUTH Code Here https://twitchapps.com/tmi/
BOT = "twitchplayspokerstars"
CHANNEL = "twitchplayspokerstars"
OWNER = "twitchplayspokerstars"

irc = socket.socket()

def joinchat():
    load_dotenv()
    PASS = os.getenv('PASS')
    irc.settimeout(config.turn_timeout)
    irc.connect((SERVER, PORT))
    irc.send((	"PASS " + PASS + "\n" +
        "NICK " + BOT + "\n" +
        "JOIN #" + CHANNEL + "\n").encode())
    Loading = True
    while Loading:
        readbuffer_join = irc.recv(1024)
        readbuffer_join = readbuffer_join.decode()
        print(readbuffer_join)
        for line in readbuffer_join.split("\n")[0:-1]:
            print(line)
            Loading = loadingComplete(line)
    irc.send("CAP REQ :twitch.tv/tags\r\n".encode())

def setTimeout(timeout):
    irc.settimeout(timeout)

def loadingComplete(line):
    if("End of /NAMES list" in line):
        print("TwitchBot has joined " + CHANNEL + "'s Channel!")
        return False
    else:
        return True

def sendMessage(message):
    messageTemp = "PRIVMSG #" + CHANNEL + " :" + message
    irc.send((messageTemp + "\n").encode())	

def getMessages():
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
                yield line																
            except Exception as e:
                print("Error: " + str(e))


def getMessagesThread(messagesBuffer, stopThread):
    while not stopThread():
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
                    messagesBuffer.append(line)															
                except Exception as e:
                    print("Error: " + str(e))
    print("Thread stopped")