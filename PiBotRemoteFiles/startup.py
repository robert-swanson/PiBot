import RPi.GPIO as GPIO
import time

GPIO.setmode(GPIO.BOARD)
GPIO.setup(36,GPIO.OUT)
GPIO.output(36,True)
time.sleep(1)
