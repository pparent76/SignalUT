#!/bin/python3
import os
import sys

# Vérifier qu'un argument a été fourni
if len(sys.argv) < 2:
    print(f"Usage: {sys.argv[0]} <path>")
    exit(1)

# Récupérer le chemin dans le premier argument
path = sys.argv[1]

# Equivalent de mkdir -p
os.makedirs(path, exist_ok=True)
