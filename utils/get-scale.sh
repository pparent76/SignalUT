#!/usr/bin/python3
'''
 Copyright (C) 2022  UBPorts

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; version 3.

 udeb is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
'''
import os
import sys
import yaml
import re
import subprocess


#### Functions
def get_lcd_density() -> int:
  # getprop ro.sf.lcd_density
  lcd_density = None
  process = None
  try:
    # Start the QML process, capturing stdout
    process = subprocess.Popen(
        ["getprop", "ro.sf.lcd_density"],
        stdout=subprocess.PIPE,
        text=True,  # Decode output as text
        bufsize=1,  # Line-buffered output
        universal_newlines=True # Ensure consistent newline handling
    )
    lcd_density = int(process.stdout.readline().strip())

  except Exception as e:
    print(f"An error occurred: {e}", file=sys.stderr)
    return 0
  finally:
    if process and process.poll() is None:  # Check if the process is still running
        print("Killing process...", file=sys.stderr)
        process.terminate()  # Send a terminate signal
        try:
          process.wait(timeout=5)  # Wait for the process to terminate
        except subprocess.TimeoutExpired:
          print("Process did not terminate gracefully, killing it.", file=sys.stderr)
          process.kill()  # Force kill if termination fails
  
  return lcd_density

def scalingdevidor(GRID_PX : int = int(os.environ["GRID_UNIT_PX"])) -> int: 
  if GRID_PX >= 21: # seems to be what most need if above or at 21 grid px
    return 8
  elif GRID_PX <= 16: # this one i know because my phone is 16 so if it seems weird don't worry it works.
    return 12
  else: # throw in the dark but lets hope it works
    return 10


#### GLOBAL VARIABLES
scaling = 2
if get_lcd_density() == 0:
  scaling = str(round(1.05*float(os.environ["GRID_UNIT_PX"])/scalingdevidor(),2)) 
else:
  scaling = str(round(float(get_lcd_density()/173),2))

print(scaling)
