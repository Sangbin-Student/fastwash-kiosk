import RPi.GPIO as GPIO
import time
import sys

GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)

PIN = 13
FREQ = 50
GPIO.setup(PIN, GPIO.OUT)
pwm = GPIO.PWM(PIN, FREQ)
pwm.start(0)

try:
    if sys.argv[1] == "CLOSE":
        pwm.ChangeDutyCycle(4.6)
    elif sys.argv[1] == "OPEN":
        pwm.ChangeDutyCycle(10)
    time.sleep(1.5)
except KeyboardInterrupt:
    print("Exit")

GPIO.cleanup()