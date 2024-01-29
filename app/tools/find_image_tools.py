import cv2
import numpy as np
from PIL import ImageGrab
import time
import pyautogui

def findImage( target_image_path, confidence_threshold=0.8):
    target_image = cv2.imread(target_image_path)		
    screen = np.array(ImageGrab.grab())
    result = cv2.matchTemplate(screen, target_image, cv2.TM_CCOEFF_NORMED)
    
    min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)

    if max_val >= confidence_threshold:		
        print("Image found " + target_image_path)		
        return True
    else:
        return False	
    

def findAndMoveToImage(target_image_path, confidence_threshold=0.8, click = True):
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

            if click:
                # Click on the center of the found image
                pyautogui.click(center_x, center_y)
            else:
                # Move to the center of the found image
                pyautogui.moveTo(center_x, center_y)

            print("Image found " + target_image_path)				
            break
        
        time.sleep(1)
    