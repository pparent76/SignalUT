#!/bin/python3
import os
import sys

if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} <fichier>")
    sys.exit(1)

file_path = sys.argv[1]

try:
    os.remove(file_path)
except FileNotFoundError:
    print(f"rm Error : '{file_path}' does not exist.")
except PermissionError:
    print(f"rm Error : Unauthorized.")
except Exception as e:
    print(f"rm Unknown error : {e}")
