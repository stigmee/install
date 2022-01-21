#!/usr/bin/python

from genericpath import isdir
import os
import sys, getopt
import platform

def usage():
   print('checkenv.py debug|release')

def fatal(error):
   print("[101m" + error + "![0m")
   sys.exit(2)

def main_common(WORKSPACE_STIGMEE = None):
   if WORKSPACE_STIGMEE == None:
      WORKSPACE_STIGMEE = os.environ.get('WORKSPACE_STIGMEE')
      if WORKSPACE_STIGMEE == None:
          fatal("WORKSPACE_STIGMEE is NOT set, please set it and retry")

   if os.path.isdir(WORKSPACE_STIGMEE) == False:
      fatal("WORKSPACE_STIGMEE \"%s\" is NOT a valid directory, please set it and retry" % WORKSPACE_STIGMEE)

   # todo check if directories are Ok
   print("common: ok")

def main_windows():
   res1 = os.system("cl.exe /Fe:res\win.exe res\win.cc")
   if res1 != 0:
      fatal("MS C++ compiler is not found")

   if os.path.isfile("res\win.exe") == False:
      fatal("MS C++ compiler is not working")

   res2 = os.system("res\win.exe")
   if res2 != 0:
      fatal("MS C++ compiler could not compile test program")

   print("windows: MS C++ Compiler OK")
   
def main(argv):
   ws = None
   try:
      opts, args = getopt.getopt(argv,"hw:", ["workspace", "ws"])
   except getopt.GetoptError:
      usage()
      sys.exit(1)
   for opt, arg in opts:
      if opt == '-h':
         usage()
         sys.exit(1)
      elif opt in ("-w", "--workspace", "--ws"):
         ws = arg         
   system = platform.system()
   print("Operating system: " + system)
   main_common(ws)
   if system == "Windows":
      main_windows()

if __name__ == "__main__":
   main(sys.argv[1:])
