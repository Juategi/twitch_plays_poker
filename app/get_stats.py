import tools.ocr_tools as ocr_tools
import time
import tools.find_image_tools as find_image_tools

cashier_image = 'assets/cashier.png'

def closeCashier():
    window = ocr_tools.getWindow("Cashier")
    window.close()

def get_text_from_cashier():
    window_title_to_capture = "Cashier"
    screenshot_path = ocr_tools.capture_window_screenshot(window_title_to_capture)

    if screenshot_path:
        # Define the region to extract text from (coordinates are in left, top, right, bottom order)
        text_extraction_region = (800, 0, 950, 400)  # Adjust these values based on your specific case

        extracted_text = ocr_tools.extract_text_from_image(screenshot_path, text_extraction_region)

        extracted_text_lines = extracted_text.split('\n')
        for line in extracted_text_lines:
            if "EUR" in line:
                return line.replace("EUR", "").strip()

def getBalance():
    find_image_tools.find_and_click_image(cashier_image)
    time.sleep(5)
    balance = get_text_from_cashier()
    closeCashier()
    return balance
                