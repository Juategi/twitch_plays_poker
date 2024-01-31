import time
import tools.files_tools as files_tools
import tools.ocr_tools as ocr_tools
import tools.find_image_tools as find_image_tools

cashier_image = '../assets/cashier.png'
spins_path = '../saves/spins.txt'

#Balance
def getBalance():
    find_image_tools.findAndMoveToImage(cashier_image)
    time.sleep(5)
    balance = getTextFromCashier()
    while balance == "-1":
        time.sleep(1)
        balance = getTextFromCashier()
    time.sleep(1)
    closeCashier()
    time.sleep(1)
    return balance

def getTextFromCashier():
    window_title_to_capture = "Cashier"
    screenshot_path = ocr_tools.captureWindowScreenshot(window_title_to_capture)

    if screenshot_path:
        # Define the region to extract text from (coordinates are in left, top, right, bottom order)
        text_extraction_region = (800, 0, 950, 400)  # Adjust these values based on your specific case

        extracted_text = ocr_tools.extractTextFromImage(screenshot_path, text_extraction_region)

        extracted_text_lines = extracted_text.split('\n')
        for line in extracted_text_lines:
            if "EUR" in line:
                return line.replace("EUR", "").strip()
    return "-1"
            
def closeCashier():
    window = ocr_tools.getWindow("Cashier")
    window.close()


#Spins
def getSpinsWon():
    return files_tools.retrieveIntFromFile(spins_path)

def isSpinWon():
    window_title_to_capture = "Spin"
    screenshot_path = ocr_tools.captureWindowScreenshot(window_title_to_capture, 1200, 1200)
    if screenshot_path:
        # Define the region to extract text from (coordinates are in left, top, right, bottom order)
        text_extraction_region = (0, 0, 1000, 1000)  # Adjust these values based on your specific case

        extracted_text = ocr_tools.extractTextFromImage(screenshot_path, text_extraction_region)

        extracted_text_lines = extracted_text.split('\n')
        for line in extracted_text_lines:
            if "PRIZE" in line:
                print("Spin won!")
                spinsWon = getSpinsWon()
                files_tools.saveIntToFile(spins_path, spinsWon + 1)
        print("Spin lost!")
                