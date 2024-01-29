import pygetwindow as gw
import pyautogui
import pytesseract
from PIL import Image

pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

def capture_window_screenshot(window_title_substring):
    window = getWindow(window_title_substring)

    # Activate the window
    window.activate()

    # Resize the window to a constant size
    window.resizeTo(700, 700)

    # Wait for a moment to allow the window to adjust
    pyautogui.PAUSE = 1
    pyautogui.FAILSAFE = True
    pyautogui.moveTo(0, 0)

    # Capture the screenshot
    screenshot = pyautogui.screenshot(region=(window.left, window.top, window.width, window.height))

    # Save the screenshot or process it as needed
    screenshot.save('window_screenshot.png')

    return 'window_screenshot.png'

def getWindow(window_title_substring):
    # Get all windows
    all_windows = gw.getAllTitles()

    # Find the first window whose title contains the specified substring
    window = next((w for w in all_windows if window_title_substring.lower() in w.lower()), None)

    if not window:
        print(f"Window with title containing '{window_title_substring}' not found.")
        return None

    # Get the window by title
    window = gw.getWindowsWithTitle(window)

    if not window:
        print(f"Window with title '{window}' not found.")
        return None

    window = window[0]
    return window


def extract_text_from_image(image_path, region):
    # Open the image using PIL
    image = Image.open(image_path)

    # Define the region to extract text from (coordinates are in left, top, right, bottom order)
    region_of_interest = image.crop(region)

    # Use Tesseract to extract text
    extracted_text = pytesseract.image_to_string(region_of_interest)

    return extracted_text