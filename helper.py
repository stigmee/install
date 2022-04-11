###############################################################################
## Stigmee: The art to sanctuarize knowledge exchanges.
## Copyright 2021-2022 Quentin Quadrat <lecrapouille@gmail.com>
##
## This file is part of Stigmee.
##
## Stigmee is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################
###
### Helper functions for compiling Stigmee
###
###############################################################################

import os, sys, re, platform, subprocess, hashlib, tarfile, wget, shutil, glob
import zipfile, argparse, pysftp

from multiprocessing import cpu_count
from sysconfig import get_platform
from packaging import version
from pathlib import Path
from platform import machine, system
from subprocess import run

###############################################################################
### Hack that seems to fix color issue for Windows
os.system("")

###############################################################################
### Green color message
def info(msg):
    print("\033[32m[INFO] " + msg + "\033[00m", flush=True)

###############################################################################
### Red color message + abort
def fatal(msg):
    print("\033[31m[FATAL] " + msg + "\033[00m", flush=True)
    sys.exit(2)

###############################################################################
### AMD64, ARM64 ...
ARCHI = machine()

###############################################################################
### Type of operating system
OSTYPE = system()
if os.name == "nt" and get_platform().startswith("mingw"):
    OSTYPE = "MinGW"
EXEC = ".exe" if OSTYPE == "Windows" else ""

###############################################################################
### Number of CPU cores
NPROC = str(cpu_count())

###############################################################################
### Download artifacts
def download(url):
    wget.download(url)
    print('', flush=True)

###############################################################################
### Equivalent to cp --verbose
def copyfile(file_name, folder):
    dest = os.path.join(folder, os.path.basename(file_name))
    print("Copy " + file_name + " => " + dest)
    shutil.copyfile(file_name, dest)

###############################################################################
### Equivalent to rm -fr
def rmdir(top):
    if os.path.isdir(top):
        for root, dirs, files in os.walk(top, topdown=False):
            for name in files:
                os.remove(os.path.join(root, name))
            for name in dirs:
                os.rmdir(os.path.join(root, name))
        os.rmdir(top)

###############################################################################
### Equivalent to mkdir -p
def mkdir(path):
    Path(path).mkdir(parents=True, exist_ok=True)

###############################################################################
### Equivalent to tar -xj
def untarbz2(tar_bz2_file_name, dest_dir):
    info("Unpacking " + tar_bz2_file_name + " ...")
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

###############################################################################
### Equivalent to tar jcvf
def tarbz2(tarball_name, source_dir):
    with tarfile.open(tarball_name, "w:bz2") as tar:
        tar.add(source_dir, arcname=os.path.basename(source_dir))
        tar.close()

###############################################################################
### Equivalent to unzip
def unzip(path_to_zip_file):
    with zipfile.ZipFile(path_to_zip_file, 'r') as zip_ref:
        zip_ref.extractall()

###############################################################################
### Search an expression (not a regexp) inside a file
def grep(file_name, what):
    try:
        file = open(file_name, "r")
        for line in file:
            if line.find(what) != -1:
                return line
        return None
    except IOError:
        return None

###############################################################################
### Equivalent to test -L e on alias + ln -s
def valid_symlink(path):
    p = Path(path);
    return p.is_symlink() and p.exists()

###############################################################################
### Equivalent to test -L e on alias + ln -s
def symlink(src, dst):
    p = Path(dst);
    if p.is_symlink():
        os.remove(p)
    os.symlink(src, dst)

###############################################################################
### Compute the SHA1 of the given artifact file
def compute_sha1(artifact):
    CHUNK = 1 * 1024 * 1024
    sha1 = hashlib.sha1()
    with open(artifact, 'rb') as f:
        while True:
            data = f.read(CHUNK)
            if not data:
                break
            sha1.update(data)
    return "{0}".format(sha1.hexdigest())

###############################################################################
### Read a text file holding a SHA1 value
def read_sha1_file(path_sha1):
    file = open(path_sha1, "r")
    for line in file:
        return line # Just read 1st line
    return None

###############################################################################
### Check if compilers are present
def check_compiler():
    if OSTYPE == "Windows":
        with open("win.cc", 'w') as f:
            f.write("#include <windows.h>\r\n")
            f.write("int main(int argc, char **argv) { return 0; }")
        if os.system("cl.exe /Fe:win.exe win.cc") != 0:
            fatal("MS C++ compiler is not found")
        if os.path.isfile("win.exe") == False:
            fatal("MS C++ compiler is not working")
        if os.system("win.exe") != 0:
            fatal("MS C++ compiler could not compile test program")
        info("MS C++ Compiler OK")

###############################################################################
### Check if cmake version is >= 3.19 needed by CEF
def check_cmake_version(min_version):
    info("Checking cmake version ...")
    output = subprocess.check_output(["cmake", "--version"]).decode("utf-8")
    line = output.splitlines()[0]
    current_version = line.split()[2]
    if version.parse(current_version) < version.parse(min_version):
        fatal("Your CMake version is " + current_version + " but shall be >= "
              + min_version + "\nSee " + WORKSPACE_STIGMEE +
              "/doc/internal/doc/install_latest_cmake.sh to update it before "
              "running this script")
