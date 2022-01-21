#!/usr/bin/python

from genericpath import isdir
import os
import sys, getopt
import platform
import requests
import hashlib
import tarfile
import copy

CEF_WEBSITE="https://cef-builds.spotifycdn.com"

CEF_WIN64_TARBALL="cef_binary_97.1.6%2Bg8961cdb%2Bchromium-97.0.4692.99_windows64.tar.bz2"
# CEF_WIN64_TARBALL="cef_binary_97.1.5%2Bg2b00258%2Bchromium-97.0.4692.71_windows64.tar.bz2"
CEF_WIN64_SHA1="61d5976efb76248ca86b71405f55d84cc9df199b"
CEF_WIN64_FILE="cef_97.1.6.tar.bz2"
# CEF_WIN64_FILE="cef_97.1.5.tar.bz2"

BUF_SIZE=1*1024*1024

def usage():
   print('checkenv.py [debug|release|clean]')

def fatal(error):
   print("", flush=True)
   print("[101m" + error + "![0m")
   sys.exit(2)

def rmdir(top):
   for root, dirs, files in os.walk(top, topdown=False):
      for name in files:
         os.remove(os.path.join(root, name))
      for name in dirs:
         os.rmdir(os.path.join(root, name))
   os.rmdir(top)

def unpack_file(tar_bz2_file_name, dest_dir):
   with tarfile.open(tar_bz2_file_name) as f:
      directories = []
      root_dir = ""

      for tarinfo in f:
         if tarinfo.isdir() and root_dir == "":
            root_dir = tarinfo.name

         name = tarinfo.name.replace(root_dir, dest_dir)
         print(" - %s" % name)

         if tarinfo.isdir():
            os.mkdir(name)
            continue

         tarinfo.name = name
         f.extract(tarinfo, "")

def compute_sha1(file_name):
   sha1 = hashlib.sha1()
   with open(file_name, 'rb') as f:
      while True:
         data = f.read(BUF_SIZE)
         if not data:
            break
         sha1.update(data)
   return "{0}".format(sha1.hexdigest())

def download_file(url, dst):
   local_filename = url.split('/')[-1]
   with requests.get(url, stream=True) as r:
      r.raise_for_status()
      with open(dst, 'wb') as f:
         sum = 0
         for chunk in r.iter_content(chunk_size=BUF_SIZE): 
            sum += BUF_SIZE
            print("downloading %s %d bytes\r" % (dst, sum), end='')
            f.write(chunk)
   print("%s downloaded                                            " % dst) # enough space to hide downloading message
   return local_filename   

def main_common(WORKSPACE_STIGMEE = None):
   if WORKSPACE_STIGMEE == None:
      WORKSPACE_STIGMEE = os.environ.get('WORKSPACE_STIGMEE')
      if WORKSPACE_STIGMEE == None:
          fatal("WORKSPACE_STIGMEE is NOT set, please set it and retry")

   print("checking %s directory" % WORKSPACE_STIGMEE)
   if os.path.isdir(WORKSPACE_STIGMEE) == False:
      fatal("%s is NOT a valid directory" % WORKSPACE_STIGMEE)

   # todo check if directories are Ok
   print("common: ok")
   return WORKSPACE_STIGMEE

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
   rmdir_cef_binary = False
   try:
      opts, args = getopt.getopt(argv,"hw:", ["workspace", "ws", "remove-cef-dir"])
   except getopt.GetoptError:
      usage()
      sys.exit(1)
   for opt, arg in opts:
      if opt == '-h':
         usage()
         sys.exit(1)
      elif opt in ("-w", "--workspace", "--ws"):
         ws = arg         
      elif opt in ("--remove-cef-dir"):
         try:
            rmdir_cef_binary = True
         except OSError as error:
            fatal(error.strerror)
   system = platform.system()
   print("Operating system: " + system)
   WORKSPACE_STIGMEE = main_common(ws)
   if system == "Windows":
      # main_windows()

      cef_directory = WORKSPACE_STIGMEE+"/godot/gdnative/browser/thirdparty/cef_binary"
      if rmdir_cef_binary and os.path.isdir(cef_directory):
         rmdir(cef_directory)
      if os.path.isfile(cef_directory + "/README.txt") == False:
         # download file
         if os.path.isfile(CEF_WIN64_FILE) == False:
            download_file(CEF_WEBSITE+"/"+CEF_WIN64_TARBALL, CEF_WIN64_FILE)
         else:
            print("%s is already downloaded" % CEF_WIN64_FILE)
         print("computing %s SHA1" % CEF_WIN64_FILE)
         hash = compute_sha1(CEF_WIN64_FILE)
         if hash != CEF_WIN64_SHA1:
            fatal("%s: invalid hash: remove it and try again" % CEF_WIN64_SHA1)
         print("Hash is ok. Unpacking ...")
         unpack_file(CEF_WIN64_FILE, cef_directory)
      else:
         print("Found cef_binary directory: %s\nIf not ok, please restart with --remove-cef-dir" % cef_directory)

if __name__ == "__main__":
   main(sys.argv[1:])
