#!/usr/bin/python3
import os
import signal
import sys
import json
from time import sleep
import RPi.GPIO as GPIO

JSON_DATA_FILE = "/tmp/.power_led"
LED_PIN = None

def read_json():
    try:
        with open(JSON_DATA_FILE) as file:
            return json.load(file)
    except:
        return None

def sigterm_handler(*_):
    # Turn off LED cleanly on termination
    global LED_PIN
    if LED_PIN is not None:
        try:
            GPIO.output(LED_PIN, GPIO.LOW)
            GPIO.cleanup()
        except:
            pass
    sys.exit(0)

def main():
    global LED_PIN
    
    # 1. Wait until config file exists and is valid
    json_data = None
    while json_data is None:
        json_data = read_json()
        if json_data is None:
            sleep(1)
            
    LED_PIN = int(json_data["led_gpio"])
    
    # 2. GPIO initialization (simple ON/OFF instead of heavy PWM)
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(LED_PIN, GPIO.OUT)
    GPIO.output(LED_PIN, GPIO.HIGH) # Turn LED ON
    
    # 3. Wait for Chromium without CPU-heavy blink loops
    while not os.popen("ps -ef | grep chromium-browser | grep http | grep -v grep").read().strip():
        sleep(2)
        
    last_mtime = 0
    last_dim_mode = str(json_data.get("led_dim_mode", "0"))

    # 4. Main loop using mtime to avoid unnecessary file reads
    while True:
        sleep(1)
        try:
            current_mtime = os.path.getmtime(JSON_DATA_FILE)
            if current_mtime != last_mtime:
                last_mtime = current_mtime
                json_data = read_json()
                
                if json_data:
                    current_dim_mode = str(json_data.get("led_dim_mode", "0"))
                    if current_dim_mode != last_dim_mode:
                        # 0 = Bright/ON, 1 = Dimmed/OFF
                        if current_dim_mode == "0":
                            GPIO.output(LED_PIN, GPIO.HIGH)
                        elif current_dim_mode == "1":
                            GPIO.output(LED_PIN, GPIO.LOW) 
                        last_dim_mode = current_dim_mode
        except FileNotFoundError:
            pass

if __name__ == "__main__":
    signal.signal(signal.SIGTERM, sigterm_handler)
    try:
        main()
    except KeyboardInterrupt:
        sigterm_handler()
