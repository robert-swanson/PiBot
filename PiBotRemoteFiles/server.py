import socket
import time
import sys
import io
from threading import Thread
try:
    import RPi.GPIO as GPIO
except:
    print("Not Pi")

# Conection
port = 4000
ping = False
s = None
c = None

# GPIO
PWMA = 7  # Left Speed
AIN1 = 12 # Left Forward
AIN2 = 11 # Left Backward
STBY = 13
BIN1 = 15 # Right Forward
BIN2 = 16 # Right Backward
PWMB = 18 # Right Speed
SERVO = 22

connected = 37
replaying = 38
data = 40

lPWM = None
rPWM = None
sPWM = None

history = []
timer = 0
stop = False

lastServoCommand = 0
servoWaiting = False

def isNum(s):
    try:
        float(s)
        return True
    except ValueError:
        return False

def main():
    global port
    if len(sys.argv) > 1:
        port = int(sys.argv[1])
        global PWMA, AIN1, AIN2, STBY, BIN1, BIN2, PWMB,SERVO, connected, replaying, data
        for i in range(2,len(sys.argv)):
            val = sys.argv[i]
            if(i==2):
                PWMA = val
            elif(i==3):
                AIN1 = val
            elif(i==4):
                AIN2 = val
            elif(i==5):
                STBY = val
            elif(i==6):
                BIN1 = val
            elif(i==7):
                BIN2 = val
            elif(i==8):
                PWMB = val
            elif(i==9):
                SERVO = val
            elif(i==10):
                connected = val
            elif(i==11):
                replaying = val
            elif(i==12):
                data = val
    try:
        netLoop()
    except Exception as e:
        print("ERROR: " + str(e))
        time.sleep(1)
        global s
        if s != None:
            s.close()
    finally:
        print("Closing Client")
def netLoop():
    s = socket.socket()
    s.bind(('',port))
    on(data)
    print("Listening on port " + str(port) + "...")
    s.listen(5)
    global c
    c, addr = s.accept()
    on(connected)
    off(data)
    print(str(addr))
    while True:
        input = c.recv(1024).strip()[:-1]
        comms = input.split("$")
        for i in range(len(comms)):
            comm = comms[i]
            if((not isNum(comm) and not (len(comm.split(" ")) > 1) or (i == len(comms)-1)) and interpret(comm)):
                return

def interpret(input):
    print("Interpreting: "+input)
    on(data)
    if input == b'':
        return True
    elif input == b'close':
        c.send("ping")
        print("Closed by server")
        return True
    elif input == b'ping':
        if ping:
            print("Ping Successful")
        else:
            print("Ping")
            c.send("ping")
    elif input == b'forward':
        print("starting replay")
        Thread(target=playForward).start()
    elif input == b'backward':
        print("starting rewind")
        Thread(target=playBackward).start()
    elif input == b'clear':
        global history
        history = []
        print("cleared")
    elif input == b'stop':
        global stop
        stop = True
        updateGPIO(0,0)
        print("stop")
    else:
        try:
            nums = input.split(" ")
            if(len(nums) >= 2):
                l = float(nums[0])
                r = float(nums[1])
                updateGPIO(l,r)
                addEventToHistory(l,r)
            elif(len(nums)==1 and SERVO > 0): #Servo
                global sPWM
                global lastServoCommand
                global servoWaiting

                sPWM.start(2.5)
                lastServoCommand = time.time()
                if not servoWaiting:
                    sPWM = GPIO.PWM(SERVO,50)
                    sPWM.start(float(nums[0]))
                    Thread(target=servoWait).start()
                else:
                    sPWM.ChangeDutyCycle(float(nums[0]))
        except Exception as e:
            print(e)
            print("Unkown Message: " + input)
            pass
    off(data)

def servoWait():
    global servoWaiting
    global lastServoCommand
    servoWaiting = True
    blink = False
    while time.time()-lastServoCommand <= .1:
        time.sleep(.1)
    sPWM.stop()

    servoWaiting = False

def addEventToHistory(l,r):
    global timer
    history.append([l,r])
    if timer != 0:
        dur = time.time() - timer
        history[len(history)-2].append(dur)
    timer = time.time()
def playForward():
    global stop
    on(replaying)
    stop = False
    global timer
    for event in history:
        if stop:
            break
        if event[0] != 0 and event[1] != 0:
            updateGPIO(event[0],event[1])
            if len(event) >= 2:
                time.sleep(event[2])
            else:
                updateGPIO(0,0)
    updateGPIO(0,0)
    stop = False
    off(replaying)
    c.send("done")
    print("done replay")
def playBackward():
    global stop
    on(replaying)
    stop = False
    global timer
    for i in range(len(history)):
        index = len(history)-1-i
        event = history[index]
        if stop:
            break
        if event[0] != 0 and event[1] != 0:
            updateGPIO(-event[0],-event[1])
            if len(event) >= 2:
                time.sleep(event[2])
            else:
                updateGPIO(0,0)
    updateGPIO(0,0)
    stop = False
    off(replaying)
    c.send("done")
    print("done rewind")

# GPIO --------------------------------------------
def setout(pin):
    if(pin > 0 and pin <= 40):
        GPIO.setup(pin,GPIO.OUT)
    else:
        print("ignoring pin")
def setupGPIO():
    GPIO.setmode(GPIO.BOARD)
    setout(PWMA)
    setout(AIN1)
    setout(AIN2)
    setout(STBY)
    setout(BIN1)
    setout(BIN2)
    setout(PWMB)
    setout(connected)
    setout(replaying)
    setout(data)
    setout(SERVO)
    GPIO.output(STBY,True)
    global lPWM
    global rPWM
    global sPWM
    lPWM = GPIO.PWM(PWMA, 100)
    rPWM = GPIO.PWM(PWMB, 100)
    if(SERVO > 0):
        sPWM = GPIO.PWM(SERVO, 50)
    lPWM.start(0)
    rPWM.start(0)
def updateGPIO(lS, rS):
    lS *= 100
    rS *= 100
    if lS > 100: lS = 100
    if lS < -100: lS = -100
    if rS > 100: rS = 100
    if rS < -100: rS = -100
    lPWM.ChangeDutyCycle(abs(lS))
    rPWM.ChangeDutyCycle(abs(rS))
    GPIO.output(AIN1,lS>=0)
    GPIO.output(AIN2,lS<0)
    GPIO.output(BIN1,rS>=0)
    GPIO.output(BIN2,rS<0)
def on(pin):
    if(pin > 0 and pin <= 40):
        GPIO.output(pin, True)
def off(pin):
    if(pin > 0 and pin <= 40):
        GPIO.output(pin, False)
# -------------------------------------------------
print("Just so that at least something is printed")
try:
    try:
        setupGPIO()
    except: pass
    main()
finally:
    try:
        off(connected)
        GPIO.cleanup()
    except: pass
