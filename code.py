import random
import time
import neopixel
import board
import digitalio
from adafruit_ble import BLERadio
from adafruit_ble.advertising.standard import ProvideServicesAdvertisement
from adafruit_ble.services.nordic import UARTService

# Set up watchdog
from microcontroller import watchdog as w
from watchdog import WatchDogMode
w.timeout = 30
w.mode = WatchDogMode.RESET

# Underclock to save battery
import microcontroller
microcontroller.cpu.frequency = 80_000_000

# Set up PIR motion sensor pins
pir_ground = digitalio.DigitalInOut(board.D7)
pir_ground.direction = digitalio.Direction.OUTPUT
pir_ground.value = False
pir_power = digitalio.DigitalInOut(board.D6)
pir_power.direction = digitalio.Direction.OUTPUT
pir_power.value = True
pir_data = digitalio.DigitalInOut(board.D5)
pir_data.direction = digitalio.Direction.INPUT

# Set up constants
SERVER_MAC_ADDRESS = "98:3D:AE:F3:69:DE"
SHOW_MOTION_TIME = 5

# Initialize BLE radio
ble = BLERadio()

# Initialize last motion times
last_motion_time_local = -9999
last_motion_time_remote = -9999

# Initialize pixel grid
pixels = neopixel.NeoPixel(board.NEOPIXEL, 64, auto_write=False, brightness=0.1, pixel_order=neopixel.RGB)

def stop_sign_pixels():
    _ = 0
    shape = [
        [_,_,_,1,1,_,_,_],
        [_,_,_,1,1,_,_,_],
        [_,_,_,1,1,_,_,_],
        [_,_,_,1,1,_,_,_],
        [_,_,_,1,1,_,_,_],
        [_,_,_,_,_,_,_,_],
        [_,_,_,1,1,_,_,_],
        [_,_,_,1,1,_,_,_],
    ]
    for row in range(len(shape)):
        for col in range(len(shape[row])):
            if shape[row][col] == 1:
                yield [row * 8 + col, (30, 0, 0)]
            else:
                yield [row * 8 + col, (0, 0, 0)]

def ok_sign_pixels():
    _ = 0
    shape = [
        [_,_,_,_,_,_,_,_],
        [_,_,_,_,_,_,_,1],
        [_,_,_,_,_,_,1,1],
        [1,1,_,_,_,1,1,_],
        [_,1,1,_,1,1,_,_],
        [_,_,1,1,1,_,_,_],
        [_,_,_,1,_,_,_,_],
        [_,_,_,_,_,_,_,_],
    ]
    for row in range(len(shape)):
        for col in range(len(shape[row])):
            if shape[row][col] == 1:
                yield [row * 8 + col, (0, 30, 0)]
            else:
                yield [row * 8 + col, (0, 0, 0)]

def flash_sign(sign, flashes=10, on_time=0.1, off_time=0.2):
    sign_pixels = list(sign)
    for _ in range(flashes):
        sign_iter = iter(sign_pixels)
        for i in range(64):
            pixels[i] = next(sign_iter)[1]
        pixels.show()
        time.sleep(on_time)
        pixels.fill((0, 0, 0))
        pixels.show()
        time.sleep(off_time)

def fluid_random_colors(duration=1, delay=0.05):
    end_time = time.monotonic() + duration
    while time.monotonic() < end_time:
        for i in range(64):
            pixels[i] = (random.randint(0, 20), random.randint(0, 20), random.randint(0, 20))
        pixels.show()
        time.sleep(delay)
    pixels.fill((0, 0, 0))
    pixels.show()

def breathing_effect(pixel_index=0, color=(30, 20, 0), duration=1, steps=50, count=3):
    step_delay = duration / (2 * steps)
    for _ in range(count):
        for brightness in range(steps):
            pixels[pixel_index] = (int(color[0] * (brightness / steps)), 
                                   int(color[1] * (brightness / steps)), 
                                   int(color[2] * (brightness / steps)))
            pixels.show()
            time.sleep(step_delay)
        for brightness in range(steps, -1, -1):
            pixels[pixel_index] = (int(color[0] * (brightness / steps)), 
                                   int(color[1] * (brightness / steps)), 
                                   int(color[2] * (brightness / steps)))
            pixels.show()
            time.sleep(step_delay)
    pixels[pixel_index] = (0, 0, 0)
    pixels.show()

def travel_effect(line=0, color=(0, 0, 40), count=1, delay=0.02):
    for _ in range(count):
        for i in range(8):
            pixels.fill((0, 0, 0))
            pixels[line * 8 + i] = color
            pixels.show()
            time.sleep(delay)
    pixels.fill((0, 0, 0))
    pixels.show()

def found_ready_command(uart):
    if uart.in_waiting:
        command = uart.read(uart.in_waiting).decode().strip()
        print(f"Waiting for 'ready'. Received: {command}")
        return True # we're fine with anything received
    return False

def run_loop(uart):
    global last_motion_time_local, last_motion_time_remote
    if uart.in_waiting:
        command = uart.read(uart.in_waiting).decode().strip()
        print(f"Received: {command}")
        # Treat all received commands as motion
        last_motion_time_remote = time.monotonic()

    if pir_data.value:
        print(f"Sending motion! (random: {random.randint(0, 100)})")
        uart.write("1\n")
        last_motion_time_local = time.monotonic()

    pixels.fill((0, 0, 0))
    time_since_last_motion_local = time.monotonic() - last_motion_time_local
    time_since_last_motion_remote = time.monotonic() - last_motion_time_remote
    if (time_since_last_motion_remote < SHOW_MOTION_TIME):
        flash_sign(stop_sign_pixels(), flashes=1, on_time=0.2, off_time=0)
    elif (time_since_last_motion_local < SHOW_MOTION_TIME):
        flash_sign(ok_sign_pixels(), flashes=1, on_time=0.2, off_time=0)

def run_server():
    uart = UARTService()
    advertisement = ProvideServicesAdvertisement(uart)
    w.feed()
    ble.start_advertising(advertisement)
    print("Waiting for a connection...")
    w.feed()
    while not ble.connected:
        w.feed()
        breathing_effect(pixel_index=63, count=1)

    print("Connected, waiting for ready...")
    w.feed()
    while ble.connected and not found_ready_command(uart):
        breathing_effect(pixel_index=0, count=1)

    print("Client ready!")
    w.feed()
    ble.stop_advertising()
    while ble.connected:
        w.feed()
        run_loop(uart)
        w.feed()
        time.sleep(0.3)
    uart.deinit()

def run_client():
    print("Scanning...")

    # Scan for advertisements
    found = False
    w.feed()
    ble.stop_scan()
    travel_effect(line=1)
    travel_effect(line=3)
    travel_effect(line=5)
    travel_effect(line=7)
    pixels[63] = (0, 0, 30)
    pixels.show()
    w.feed()
    found = False
    for advertisement in ble.start_scan(ProvideServicesAdvertisement, timeout=10):
        w.feed()
        if bytes(reversed(advertisement.address.address_bytes)).hex(':').upper() == SERVER_MAC_ADDRESS:
            print(f"Found server with MAC address: {SERVER_MAC_ADDRESS}")
            found = True
            break
    ble.stop_scan()
    if not found:
        print("Server not found")
        return

    # Connect to the server
    print("Connecting to server...")
    w.feed()
    connection = ble.connect(advertisement)
    print("Getting UART...")
    w.feed()
    pixels[63] = (0, 0, 0)
    pixels[0] = (0, 0, 30)
    pixels.show()
    uart = connection[UARTService]
    pixels.fill((0, 0, 0))
    pixels.show()
    w.feed()

    print(f"Connected to server, interval: {connection.connection_interval}")

    uart.write("ready\n")

    while connection.connected:
        w.feed()
        run_loop(uart)
        w.feed()
        time.sleep(0.3)

def is_server(ble_address):
    return bytes(reversed(ble_address.address_bytes)).hex(':').upper() == SERVER_MAC_ADDRESS


# Run

fluid_random_colors()

try:
    while True:
        if is_server(ble._adapter.address):
            run_server()
        else:
            run_client()
except Exception as e:
    print(f"Error: {e}")

microcontroller.reset()
