import RPi.GPIO as GPIO
import time
import socket
import select
import sys

port = 3000
if len(sys.argv) > 0:
    port = int(sys.argv[1])

def setupGPIO():
    setout(PWMA)
    setout(AIN1)
    setout(AIN2)
    setout(STBY)
    setout(BIN1)
    setout(BIN2)
    setout(PWMB)
    setout(LED)
    setout(RLED)
    GPIO.setup(STOP,GPIO.IN)
    GPIO.output(STBY,True)
def updateGPIO():
    GPIO.output(AIN1,leftDir)
    GPIO.output(AIN2,not leftDir)
    GPIO.output(BIN1,rightDir)
    GPIO.output(BIN2,not rightDir)
    GPIO.output(STBY, not moving)
    lPWM.ChangeDutyCycle(leftSpeed)
    rPWM.ChangeDutyCycle(rightSpeed)

def setout(pin):
    GPIO.setup(pin,GPIO.OUT)
def on(pin):
    GPIO.output(pin, True)
def off(pin):
    GPIO.output(pin, False)
def stop():
    return GPIO.input(STOP)

GPIO.setmode(GPIO.BOARD)

backwards = False
moving = False
leftDir = True
rightDir = True
leftSpeed = 0
rightSpeed = 0

driftLF = .987
driftRF = 1
driftLB = 1
driftRB = .987


PWMA = 7  # Left Speed
AIN1 = 11 # Left Forward
AIN2 = 12 # Left Backward
STBY = 13
BIN1 = 15 # Right Forward
BIN2 = 16 # Right Backward
PWMB = 18 # Right Speed
LED = 36
RLED = 29
STOP = 22

setupGPIO()

lPWM = GPIO.PWM(PWMA, 100)
rPWM = GPIO.PWM(PWMB, 100)
lPWM.start(0)
rPWM.start(0)

s = socket.socket()

def interpret(mess):
    global backwards
    if mess == b'close':
        return True
    if mess == b'startb':
        on(RLED)
        backwards = True
        return
    if mess == b'startf':
        backwards = False
        on(RLED)
        return
    if mess == b'end':
        backwards = False
        off(RLED)
        return
    instruc = mess.split(b'_')
    if len(instruc) == 0:
        return False
    print(mess)
    rS = -1*int(instruc[0])
    lS = int(instruc[1])
    if lS > 100: lS = 100
    if lS < -100: lS = -100
    if rS > 100: rS = 100
    if rS < -100: rS = -100
    print(str(lS) + " : " + str(rS))
    rS *= driftLF if lS <= 0 else driftLB
    lS *= driftRF if rS <= 0 else driftRB
    lPWM.ChangeDutyCycle(abs(lS))
    rPWM.ChangeDutyCycle(abs(rS))
    GPIO.output(AIN1,lS>=0)
    GPIO.output(AIN2,lS<0)
    GPIO.output(BIN1,rS>=0)
    GPIO.output(BIN2,rS<0)
    return False

try:
    time.sleep(.1)
    print("Connecting to Server on port: " + str(port))
    s.connect(('cobalt.local', port))
    s.setblocking(0)
    print("Connected")
    on(LED)
    while not stop():
        ready = select.select([s],[],[],.1)
        if ready[0]:
            if interpret(s.recv(1024)):
                break
    if stop():
        print("Stopping")

finally:
    s.shutdown(socket.SHUT_RDWR)
    s.close()
    GPIO.cleanup()
