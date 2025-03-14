import microcontroller
import time
import board
import neopixel
import supervisor

pixels = neopixel.NeoPixel(board.NEOPIXEL, 64, auto_write=False, brightness=0.1, pixel_order=neopixel.RGB)
pixels.fill((0, 0, 0))
pixels[35] = (0, 20, 0)
pixels[36] = (0, 0, 20)
if supervisor.runtime.safe_mode_reason == supervisor.SafeModeReason.BROWNOUT:
    pixels[43] = (20, 0, 0)
    pixels[44] = (20, 0, 0)
pixels.show()
time.sleep(2)

pixels.fill((0, 0, 0))
pixels.show()
time.sleep(3)
microcontroller.reset()
