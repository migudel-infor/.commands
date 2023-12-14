#! /usr/bin/env python
from sys import argv
from os import listdir
from os.path import isfile, isdir

target:str = argv[1]
BOLD = "\033[1m";
BLACK = "\u001B[30m";
RED = "\u001B[31m";
GREEN = "\u001B[32m";
YELLOW = "\u001B[33m";
BLUE = "\u001B[34m";
PURPLE = "\u001B[35m";
CYAN = "\u001B[36m";
WHITE = "\u001B[37m";
RESET = "\u001B[0m";

def showLines(file):
     with open(file, "r") as f:
          for i, line in enumerate(f.readlines()):
               if target in line:
                    line = line.replace(target, BOLD + CYAN + target + RESET)
                    print(f"{file}:{i+1}:{line}", end='')

def list(path):
     for i in listdir(path):
          f = f"{path}/{i}"
          if isdir(f):
               list(f)
          elif isfile(f):
               showLines(f)

if len(argv) == 3:
     list(argv[2])
elif len(argv) == 2:
     list(".")
else:
     print("Usage: search.py <target> [path]")
