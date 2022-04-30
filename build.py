#!/usr/bin/env python3
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
### This python script allows to compile Stigmee project for Linux, MacOS X,
### Windows. Initially made in Bash language it was difficult to call bash for
### Windows so a batch file was made but maintaining two scripts was to painful
### therefore Python langage was used.
###
###############################################################################

from helper import *

###############################################################################
### Desired third part versions
GODOT_VERSION = "3.4.3-stable"
CEF_VERSION = "100.0.24+g0783cf8+chromium-100.0.4896.127"

###############################################################################
### Check if WORKSPACE_STIGMEE is defined as environment variable in your
### operating system.
WORKSPACE_STIGMEE = os.environ.get("WORKSPACE_STIGMEE")
if WORKSPACE_STIGMEE == None or WORKSPACE_STIGMEE == "":
    fatal("Please export the environment variable WORKSPACE_STIGMEE before "
          "calling this script:\n"
          "  => Linux/Mac OS X:\n"
          "     export WORKSPACE_STIGMEE=<path/to/stigmee/workspace>\n"
          "  => Windows:\n"
          "     set WORKSPACE_STIGMEE <c:\path\to\stigmee\workspace>\n"
          "And ideally save it in your ~/.bashrc file (Linux/Mac) or "
          "in RegEdit (Windows)")
info("$WORKSPACE_STIGMEE=" + WORKSPACE_STIGMEE)

###############################################################################
### Set important Stigmee workspace pathes
STIGMEE_TSRC_PATH = os.path.join(WORKSPACE_STIGMEE, ".tsrc")
STIGMEE_PROJECT_PATH = os.path.join(WORKSPACE_STIGMEE, "stigmee")
STIGMEE_BUILD_PATH = os.path.join(STIGMEE_PROJECT_PATH, "build")
GODOT_ROOT_PATH = os.path.join(WORKSPACE_STIGMEE, "godot", GODOT_VERSION)
GODOT_CPP_PATH = os.path.join(GODOT_ROOT_PATH, "cpp")
GODOT_EDITOR_PATH = os.path.join(GODOT_ROOT_PATH, "editor")
GODOT_EDITOR_BIN_PATH = os.path.join(GODOT_EDITOR_PATH, "bin")
GODOT_EDITOR_ALIAS = os.path.join(WORKSPACE_STIGMEE, "godot-editor" + EXEC)
GODOT_GDNATIVE_PATH = os.path.join(WORKSPACE_STIGMEE, "godot", "gdnative")
IPFS_GDNATIVE_PATH = os.path.join(GODOT_GDNATIVE_PATH, "gdipfs")
IPFS_GODOT_EXAMPLE_BUILD = os.path.join(IPFS_GDNATIVE_PATH, "example", "build")
CEF_GDNATIVE_PATH = os.path.join(GODOT_GDNATIVE_PATH, "browser")
CEF_GODOT_EXAMPLE_BUILD = os.path.join(CEF_GDNATIVE_PATH, "example", "build")
STIGMARK_GDNATIVE_PATH = os.path.join(GODOT_GDNATIVE_PATH, "stigmark")
STIGMARK_GODOT_EXAMPLE_BUILD = os.path.join(STIGMARK_GDNATIVE_PATH, "examples", "godot", "build")
GDCEF_PATH = os.path.join(CEF_GDNATIVE_PATH, "gdcef")
GDCEF_PROCESSES_PATH = os.path.join(CEF_GDNATIVE_PATH, "gdcef_subprocess")
GDCEF_THIRDPARTY_PATH = os.path.join(CEF_GDNATIVE_PATH, "thirdparty")
CEF_PATH = os.path.join(GDCEF_THIRDPARTY_PATH, "cef_binary")
STIGMEE_INSTALL_PATH = os.path.join(WORKSPACE_STIGMEE, "packages", "install")

###############################################################################
### By default compile the project in release mode (will be modified when
### parsing the command line)
GODOT_EDITOR_TARGET = "release_debug"
GODOT_CPP_TARGET = "release"
STIGMEE_TARGET = "release"
CEF_TARGET = "Release"
STIGMEE_EXCEC_NAME = "Stigmee"

###############################################################################
### Return the Stigmee tarball name
def stigmee_exec_name():
    global STIGMEE_EXCEC_NAME
    if OSTYPE == "Linux":
        STIGMEE_EXCEC_NAME = "Stigmee.x11." + GODOT_CPP_TARGET + ".64"
    elif OSTYPE == "Darwin":
        STIGMEE_EXCEC_NAME = "Stigmee.osx." + GODOT_CPP_TARGET + ".64"
    elif OSTYPE == "Windows":
        STIGMEE_EXCEC_NAME = "Stigmee.win." + GODOT_CPP_TARGET + "64.exe"
    else:
        fatal("Unknown archi " + OSTYPE)
    return None

###############################################################################
### Compile the project in debug or release mode ?
def set_compile_mode(debug):
    global GODOT_EDITOR_TARGET, GODOT_CPP_TARGET, STIGMEE_TARGET, CEF_TARGET
    if debug:
        info("Compiling Stigmee in debug mode")
        GODOT_EDITOR_TARGET = "debug"
        GODOT_CPP_TARGET = "debug"
        STIGMEE_TARGET = "debug"
        CEF_TARGET = "Debug"
    else:
        info("Compiling Stigmee in release mode")
        GODOT_EDITOR_TARGET = "release_debug"
        GODOT_CPP_TARGET = "release"
        STIGMEE_TARGET = "release"
        CEF_TARGET = "Release"
    stigmee_exec_name()

###############################################################################
### Instal system packages needed for compiling Godot. Need to be sudo
def install_system_packages():
    info("Installing system packages ...")
    if OSTYPE == "Linux":
        META_PATH = os.path.join(STIGMEE_INSTALL_PATH, "meta", "stigmee-developpers_1.0_all.deb")
        run(["sudo", "dpkg", "-i", META_PATH], check=True)
    elif OSTYPE == "Darwin":
        run(["brew", "install", "scons", "yasm", "cmake", "ninja", "curl",
             "openssl", "rust", "rustup"], check=True)
    elif OSTYPE == "MinGW":
        run(["pacman", "-S", "--noconfirm", "--needed", "tar", "git",
             "make", "mingw-w64-x86_64-toolchain", "openssl-devel",
             "mingw-w64-x86_64-cmake", "mingw-w64-x86_64-ninja",
             "mingw-w64-x86_64-python3-pip", "rust", "mingw-w64-x86_64-curl",
             "mingw-w64-x86_64-scons", "mingw-w64-x86_64-gcc"], check=True)
    elif OSTYPE != "Windows":
        fatal("Your operating system " + OSTYPE + " is not managed")

###############################################################################
### Check if Stigmee workspace folder exists: If it does not exits then create
### the folder and download code source using the tsrc tool which is an
### alternative to git-repo.
def create_stigmee_workspace():
    if not os.path.isdir(WORKSPACE_STIGMEE):
        info(WORKSPACE_STIGMEE + " foder does not exist. I'll create it and "
             "clone the project ...")
        mkdir(WORKSPACE_STIGMEE)
        os.chdir(WORKSPACE_STIGMEE)
        init_repositories()

    # Check if important folders are present to be sure we are in Stigmee
    # workspace.
    info("Checking Stigmee folders ...")
    for folder in (STIGMEE_TSRC_PATH, STIGMEE_PROJECT_PATH, GODOT_ROOT_PATH,
                   GODOT_CPP_PATH, GODOT_EDITOR_PATH, CEF_GDNATIVE_PATH,
                   GDCEF_PATH, STIGMARK_GDNATIVE_PATH, GDCEF_PROCESSES_PATH):
        if not os.path.isdir(folder):
            fatal(folder + " is missing!\n The environment variable "
                  "WORKSPACE_STIGMEE " + WORKSPACE_STIGMEE + " is either not "
                  "refering to the Stigmee workspace or, if you think the "
                  "workspace folder is the good one, call the command:\n"
                  "   tsrc sync\nand recall this script")

###############################################################################
### If Stigmee workspace folder exists, before compiling it, remove and clear
### the build/ folder to force removing artifacts we do not want to compute
### checksums: GPUCache, logs ... This function will fail if trying to delete
### something which is not a folder. The consequence is that Google pages will
### ask you each time CEF cache is removed to accept their agreements.
def recreate_build_dir():
    if os.path.exists(STIGMEE_BUILD_PATH):
        if os.path.isdir(STIGMEE_BUILD_PATH):
            info("Removing folder " + STIGMEE_BUILD_PATH + " ...")
            rmdir(STIGMEE_BUILD_PATH)
        else:
            fatal(STIGMEE_BUILD_PATH + " seems not to be a folder!")
    mkdir(STIGMEE_BUILD_PATH)

###############################################################################
### Compile Godot editor. We compile it instead to download one because its
### compilation is not difficult and we want to ensure using the whole Stigmee
### team use the same binary (for editing, for exporting Stigmee).
def compile_godot_editor():
    if valid_symlink(GODOT_EDITOR_ALIAS):
        info("Godot Editor already compiled !")
    else:
        os.chdir(GODOT_EDITOR_PATH)
        # Check if we are not running inside GitHub actions docker
        if not run_from_github_action():
            info("Compiling Godot editor (inside " + GODOT_EDITOR_PATH + ") ...")
            if OSTYPE == "Linux":
                run(["scons", "platform=linux", "target=" + GODOT_EDITOR_TARGET,
                     "--jobs=" + NPROC], check=True)
            elif OSTYPE == "Darwin":
                run(["scons", "platform=osx", "macos_arch=" + ARCHI,
                     "target=" + GODOT_EDITOR_TARGET, "--jobs=" + NPROC], check=True)
            elif OSTYPE == "MinGW":
                run(["scons", "platform=windows", "use_mingw=True",
                     "target=" + GODOT_EDITOR_TARGET, "--jobs=" + NPROC], check=True)
            elif OSTYPE == "Windows":
                run(["scons", "platform=windows", "target=" + GODOT_EDITOR_TARGET,
                     "--jobs=" + NPROC], check=True)
            else:
                fatal("Unknown architecture " + OSTYPE +
                      ": I dunno how to compile Godot editor")
        else:
            # GitHub actions: compile a Godot editor without X11 (godot
            # --no-window does not work with Linux but only on Windows)
            info("Compiling headless Godot editor (inside " + GODOT_EDITOR_PATH + ") ...")
            run(["scons", "plateform=x11", "tools=no",
                 "vulkan=no x11=no", "target=" + GODOT_EDITOR_TARGET,
                 "--jobs=" + NPROC], check=True)

        # Create an alias on the Godot editor (we suppose the glob will find a
        # single binary FIXME ugly!)
        for f in glob.glob(os.path.join(GODOT_EDITOR_BIN_PATH, "godot*.64" + EXEC)):
            symlink(f, GODOT_EDITOR_ALIAS)

###############################################################################
### Download and install Godot tempates needed for exporting Stigmee
def install_godot_templates():
    # Check the folder in where templates shall be installed
    TEMPLATES_PATH=None
    if OSTYPE == "Linux":
        TEMPLATES_PATH = os.environ.get("HOME") + "/.local/share/godot/templates"
    elif OSTYPE == "Windows":
        TEMPLATES_PATH = os.environ.get("APPDATA") + "\\Godot\\templates"
    elif OSTYPE == "Darwin":
        TEMPLATES_PATH = "~/Library/Application Support/Godot"
    else:
        fatal("Unknown archi: " + OSTYPE)

    # From "3.4.3-stable" separate "3.4.3" and "stable" we need
    # both of them and convert the '-' to '.'
    version = GODOT_VERSION.split("-")
    TEMPLATE_FOLDER_NAME = version[0]
    if version[1] != None:
        TEMPLATE_FOLDER_NAME += "."
        TEMPLATE_FOLDER_NAME += version[1]

    # Download the tpz file (zip) if folder is not present
    if os.path.isdir(os.path.join(TEMPLATES_PATH, TEMPLATE_FOLDER_NAME)):
        info("Godot templates already downloaded ...")
    else:
        info("Downloading Godot templates into " + TEMPLATES_PATH + " ...")

        # Where to download the zip file
        WEBSITE = "https://downloads.tuxfamily.org/godotengine/" + version[0]
        TEMPLATES_TARBALL = "Godot_v" + GODOT_VERSION + "_export_templates.tpz"

        # Contrary to CEF we cannot unzip while downloading.
        mkdir(TEMPLATES_PATH)
        os.chdir(TEMPLATES_PATH)
        download(WEBSITE + "/" + TEMPLATES_TARBALL)
        unzip(TEMPLATES_TARBALL)
        os.rename("templates", TEMPLATE_FOLDER_NAME)
        os.remove(TEMPLATES_TARBALL)

###############################################################################
### Compile Godot cpp wrapper needed for our gdnative code: CEF, Stigmark ...
def compile_godot_cpp():
    info("Compiling Godot C++ API (inside " + GODOT_CPP_PATH + ") ...")
    lib = os.path.join(GODOT_CPP_PATH, "bin", "libgodot-cpp*" + GODOT_CPP_TARGET + "*")
    if not os.path.exists(lib):
        os.chdir(GODOT_CPP_PATH)
        if OSTYPE == "Linux":
            run(["scons", "platform=linux", "target=" + GODOT_CPP_TARGET,
                 "--jobs=" + NPROC], check=True)
        elif OSTYPE == "Darwin":
            run(["scons", "platform=osx", "macos_arch=" + ARCHI,
                 "target=" + GODOT_CPP_TARGET, "--jobs=" + NPROC], check=True)
        elif OSTYPE == "MinGW":
            run(["scons", "platform=windows", "use_mingw=True",
                 "target=" + GODOT_CPP_TARGET, "--jobs=" + NPROC], check=True)
        elif OSTYPE == "Windows":
            run(["scons", "platform=windows", "target=" + GODOT_CPP_TARGET,
                 "--jobs=" + NPROC], check=True)
        else:
            fatal("Unknown architecture " + OSTYPE + ": I dunno how to compile Godot-cpp")

###############################################################################
### Copy Chromium Embedded Framework assets to Stigmee build folder
def install_cef_assets():
    ### Get all CEF compiled artifacts needed for Stigmee
    info("Installing Chromium Embedded Framework to " + STIGMEE_BUILD_PATH + " ...")
    locales = os.path.join(STIGMEE_BUILD_PATH, "locales")
    mkdir(locales)
    if OSTYPE == "Linux" or OSTYPE == "Darwin":
        # cp CEF_PATH/build/tests/cefsimple/*.pak *.dat *.so locales/* STIGMEE_BUILD_PATH
        S = os.path.join(CEF_PATH, "build", "tests", "cefsimple", CEF_TARGET)
        copyfile(os.path.join(S, "v8_context_snapshot.bin"), STIGMEE_BUILD_PATH)
        copyfile(os.path.join(S, "icudtl.dat"), STIGMEE_BUILD_PATH)
        for f in glob.glob(os.path.join(S, "*.pak")):
            copyfile(f, STIGMEE_BUILD_PATH)
        for f in glob.glob(os.path.join(S, "locales/*")):
            copyfile(f, locales)
        for f in glob.glob(os.path.join(S, "*.so")):
            copyfile(f, STIGMEE_BUILD_PATH)
        for f in glob.glob(os.path.join(S, "*.so.*")):
            copyfile(f, STIGMEE_BUILD_PATH)
    elif OSTYPE == "Windows":
        # cp CEF_PATH/Release/*.bin CEF_PATH/Release/*.dll STIGMEE_BUILD_PATH
        S = os.path.join(CEF_PATH, CEF_TARGET)
        copyfile(os.path.join(S, "v8_context_snapshot.bin"), STIGMEE_BUILD_PATH)
        for f in glob.glob(os.path.join(S, "*.dll")):
            copyfile(f, STIGMEE_BUILD_PATH)
        # cp CEF_PATH/Resources/*.pak *.dat locales/* STIGMEE_BUILD_PATH
        S = os.path.join(CEF_PATH, "Resources")
        copyfile(os.path.join(S, "icudtl.dat"), STIGMEE_BUILD_PATH)
        for f in glob.glob(os.path.join(S, "*.pak")):
            copyfile(f, STIGMEE_BUILD_PATH)
        for f in glob.glob(os.path.join(S, "locales/*")):
            copyfile(f, locales)
    elif OSTYPE == "Darwin":
        # For Mac OS X rename cef_sandbox.a to libcef_sandbox.a since Scons search
        # library names starting by lib*
        os.chdir(os.path.join(CEF_PATH, CEF_TARGET))
        shutil.copyfile("cef_sandbox.a", "libcef_sandbox.a")
        S = os.path.join(CEF_PATH, CEF_TARGET, "Chromium Embedded Framework.framework")
        for f in glob.glob(S + "/Libraries*.dylib"):
            copyfile(f, STIGMEE_BUILD_PATH)
        for f in glob.glob(S + "/Resources/*"):
            copyfile(f, STIGMEE_BUILD_PATH)
    else:
        fatal("Unknown architecture " + OSTYPE + ": I dunno how to extract CEF artifacts")

###############################################################################
### Download prebuild Chromium Embedded Framework if folder is not present
def download_cef():
    if OSTYPE == "Linux":
        if ARCHI == "x86_64":
            CEF_ARCHI = "linux64"
        else:
            CEF_ARCHI = "linuxarm"
    elif OSTYPE == "darwin":
        if ARCHI == "x86_64":
            CEF_ARCHI = "macosx64"
        else:
            CEF_ARCHI = "macosarm64"
    elif OSTYPE == "Windows":
        if ARCHI == "x86_64" or ARCHI == "AMD64":
            CEF_ARCHI = "windows64"
        else:
            CEF_ARCHI = "windowsarm64"
    else:
        fatal("Unknown archi " + OSTYPE + ": Cannot download Chromium Embedded Framework")

    # CEF already installed ? Installed with a different version ?
    # Compare our desired version with the one stored in the CEF README
    if grep(os.path.join(CEF_PATH, "README.txt"), CEF_VERSION) != None:
        info(CEF_VERSION + " already downloaded")
    else:
        # Replace the '+' chars by URL percent encoding '%2B'
        CEF_URL_VERSION = CEF_VERSION.replace("+", "%2B")
        CEF_TARBALL = "cef_binary_" + CEF_URL_VERSION + "_" + CEF_ARCHI + ".tar.bz2"
        info("Downloading Chromium Embedded Framework into " + CEF_PATH + " ...")

        # Remove the CEF folder if exist and partial downloaded folder
        mkdir(GDCEF_THIRDPARTY_PATH)
        os.chdir(GDCEF_THIRDPARTY_PATH)
        rmdir("cef_binary")

        # Download CEF at https://cef-builds.spotifycdn.com/index.html
        URL = "https://cef-builds.spotifycdn.com/" + CEF_TARBALL
        info(URL)
        download(URL)
        download(URL + ".sha1")
        if compute_sha1(CEF_TARBALL) != read_sha1_file(CEF_TARBALL + ".sha1"):
            os.remove(CEF_TARBALL)
            os.remove(CEF_TARBALL + ".sha1")
            fatal("Downloaded CEF tarball does not match expected SHA1. Please retry!")

        # Simplify the folder name by removing the complex version number
        untarbz2(CEF_TARBALL, CEF_PATH)

        # Remove useless files
        os.remove(CEF_TARBALL)
        os.remove(CEF_TARBALL + ".sha1")

###############################################################################
### Compile Chromium Embedded Framework cefsimple example if not already made
def compile_cef():
    if os.path.isdir(CEF_PATH):
        os.chdir(CEF_PATH)
        info("Compiling Chromium Embedded Framework in " + CEF_TARGET +
             " mode (inside " + CEF_PATH + ") ...")

        # Apply patches for Windows
        if OSTYPE == "Windows":
            shutil.copyfile(os.path.join(STIGMEE_INSTALL_PATH, "patch", "CEF", "win", "libcef_dll_wrapper_cmake"),
                            "CMakeLists.txt")

        # Windows: force compiling CEF as static library.
        if OSTYPE == "Windows":
            run(["cmake", "-DCEF_RUNTIME_LIBRARY_FLAG=/MD", "-DCMAKE_BUILD_TYPE=" + CEF_TARGET, "."], check=True)
            run(["cmake", "--build", ".", "--config", CEF_TARGET], check=True)
        else:
           mkdir("build")
           os.chdir("build")
           # Compile CEF if Ninja is available else use default GNU Makefile
           if shutil.which('ninja') != None:
               run(["cmake", "-G", "Ninja", "-DCMAKE_BUILD_TYPE=" + CEF_TARGET, ".."], check=True)
               run(["ninja", "-v", "-j" + NPROC, "cefsimple"], check=True)
           else:
               run(["cmake", "-G", "Unix Makefiles", "-DCMAKE_BUILD_TYPE=" + CEF_TARGET, ".."], check=True)
               run(["make", "cefsimple", "-j" + NPROC], check=True)
        install_cef_assets()

###############################################################################
### Common Scons command for compiling our Godot gdnative modules
def gdnative_scons_cmd(plateform):
    if OSTYPE == "Darwin":
        run(["scons", "workspace=" + WORKSPACE_STIGMEE,
             "godot_version=" + GODOT_VERSION,
             "target=" + GODOT_CPP_TARGET, "--jobs=" + NPROC,
             "arch=" + ARCHI, "platform=" + plateform], check=True)
    else: # FIXME "arch=" + ARCHI not working
        run(["scons", "workspace=" + WORKSPACE_STIGMEE,
             "godot_version=" + GODOT_VERSION,
             "target=" + GODOT_CPP_TARGET, "--jobs=" + NPROC,
             "platform=" + plateform], check=True)

###############################################################################
###
def compile_gdnative_ipfs():
    info("Compiling Godot IPFS module (inside " + IPFS_GDNATIVE_PATH + ") ...")
    os.chdir(IPFS_GDNATIVE_PATH)
    if OSTYPE == "Linux":
        gdnative_scons_cmd("x11")
    elif OSTYPE == "Darwin":
        gdnative_scons_cmd("osx")
    elif OSTYPE == "Windows" or OSTYPE == "MinGW":
        gdnative_scons_cmd("windows")
    else:
        fatal("Unknown archi " + OSTYPE + ": I dunno how to compile CEF module primary process")

###############################################################################
### Compile Godot CEF module named GDCef and its subprocess
def compile_gdnative_cef(path):
    info("Compiling Godot CEF module (inside " + path + ") ...")
    os.chdir(path)
    if OSTYPE == "Linux":
        gdnative_scons_cmd("x11")
    elif OSTYPE == "Darwin":
        gdnative_scons_cmd("osx")
    elif OSTYPE == "Windows" or OSTYPE == "MinGW":
        gdnative_scons_cmd("windows")
    else:
        fatal("Unknown archi " + OSTYPE + ": I dunno how to compile CEF module primary process")

###############################################################################
### Compile Godot CEF module named GDCef
def compile_gdnative_stigmark():
    LIB_STIGMARK = os.path.join(STIGMARK_GDNATIVE_PATH, "target", "debug", "libstigmark_client")
    info("Compiling Godot stigmark (inside " + STIGMARK_GDNATIVE_PATH + ") ...")
    os.chdir(os.path.join(STIGMARK_GDNATIVE_PATH, "examples", "console"))
    if OSTYPE == "Linux" or OSTYPE == "MinGW":
        run(["./build-linux.sh"], check=True)
        os.chdir(os.path.join(STIGMARK_GDNATIVE_PATH, "gdstigmark"))
        gdnative_scons_cmd("x11")
        copyfile(LIB_STIGMARK + ".so", STIGMEE_BUILD_PATH)
    elif OSTYPE == "Darwin":
        run(["./build-macosx.sh"], check=True)
        os.chdir(os.path.join(STIGMARK_GDNATIVE_PATH, "gdstigmark"))
        gdnative_scons_cmd("osx")
        copyfile(LIB_STIGMARK + ".dylib", STIGMEE_BUILD_PATH)
    else:
        run(["build-windows.cmd"], check=True)
        os.rename("target\debug\stigmark_client.dll", "target\debug\libstigmark_client.dll")
        os.rename("target\debug\stigmark_client.lib", "target\debug\libstigmark_client.lib")
        os.chdir(os.path.join(STIGMARK_GDNATIVE_PATH, "gdstigmark"))
        gdnative_scons_cmd("windows")
        copyfile(LIB_STIGMARK + ".dll", STIGMEE_BUILD_PATH)

###############################################################################
### Godot export command (they shall match names used inside the Godot project)
def godot_export_command():
    if OSTYPE == "Linux":
        return "Linux/X11"
    elif OSTYPE == "Darwin":
        return "Mac OSX"
    elif OSTYPE == "Windows":
        return "Windows Desktop"
    else:
        fatal("Unknown archi " + OSTYPE)
    return None

###############################################################################
### Create the Stigmee executable
def export_stigmee():
    info("Compiling Stigmee (inside " + STIGMEE_PROJECT_PATH + ") ...")
    os.chdir(STIGMEE_PROJECT_PATH)
    STIGMEE_ALIAS = os.path.join(WORKSPACE_STIGMEE, "stigmee-" + STIGMEE_TARGET + EXEC)
    run([GODOT_EDITOR_ALIAS, "--no-window", "--export",
         godot_export_command(), os.path.join(STIGMEE_BUILD_PATH,
         STIGMEE_EXCEC_NAME)], check=True)
    symlink(os.path.join(STIGMEE_BUILD_PATH, STIGMEE_EXCEC_NAME), STIGMEE_ALIAS)
    symlink(STIGMEE_BUILD_PATH, CEF_GODOT_EXAMPLE_BUILD)
    symlink(STIGMEE_BUILD_PATH, STIGMARK_GODOT_EXAMPLE_BUILD)
    symlink(STIGMEE_BUILD_PATH, IPFS_GODOT_EXAMPLE_BUILD)

###############################################################################
### Deploy the Stigmee executable to our SFTP server
def deploy_stigmee():
    # Example of tarball name: Stigmee-Linux-2022-04-28.tar.bz2
    date = datetime.now().strftime("%Y-%m-%d")
    NEW_NAME = os.path.join(STIGMEE_PROJECT_PATH, "Stigmee-" + OSTYPE + "-" + date)
    STIGMEE_TARBALL = NEW_NAME + ".tar.bz2"
    STIGMEE_TARBALL_SHA1 = STIGMEE_TARBALL + ".sha1"
    info("Packaging Stigmee as " + STIGMEE_TARBALL + " ...")
    # Remove the tarball if already existing
    if os.path.exists(NEW_NAME):
        os.remove(NEW_NAME)
    # Rename temporary the build folder with the Stigmee name
    os.chdir(STIGMEE_PROJECT_PATH)
    os.rename("build", NEW_NAME)
    # For Windows: use rar
    tarbz2(STIGMEE_TARBALL, NEW_NAME)
    os.rename(NEW_NAME, "build")
    # Create the SHA1 file
    open(STIGMEE_TARBALL_SHA1, "w").write(compute_sha1(STIGMEE_TARBALL)).close()
    # Transfer tarball and SHA1 file to our SFTP server.
    deploy([STIGMEE_TARBALL, STIGMEE_TARBALL_SHA1])

###############################################################################
### Entry point
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Script for compiling Stigmee')
    parser.add_argument('--sync', action='store_true', help='synchronize the workspace')
    parser.add_argument('--install-packages', action='store_true', help='Install needed operating system packages (as sudo)')
    parser.add_argument('--dont-compile-godot-editor', action='store_true', help='Do not compile Godot editor and install templates')
    parser.add_argument('--dont-compile-gdnative', action='store_true', help='Do not compile Godot natives')
    parser.add_argument('--dont-export-stigmee', action='store_true', help='Do not export Stigmee')
    parser.add_argument('--deploy-stigmee', action='store_true', help='Deploy Stigmee to a SFTP server')
    parser.add_argument('--clean', action='store_true', help='Clean the project')
    parser.add_argument('--debug', action='store_true', help='Compile Stigmee in debug mode (default: relase mode)')
    args = parser.parse_args()

    if args.sync:
        os.chdir(WORKSPACE_STIGMEE)
        sync_repositories()
        sys.exit(0)
    elif args.clean:
        err("Clean TBD")
        sys.exit(0)
    if args.install_packages:
        install_system_packages()
    else:
        info("[USER REQUEST] Skip installing needed operating system packages")
    set_compile_mode(args.debug)
    create_stigmee_workspace()
    check_cmake_version("3.19")
    check_compiler()
    if not args.dont_compile_gdnative:
        recreate_build_dir()
        compile_godot_cpp()
        download_cef()
        compile_cef()
        # Fix the libcurl missing dependency for Windows before uncommenting it
        # compile_gdnative_ipfs()
        compile_gdnative_cef(GDCEF_PATH)
        compile_gdnative_cef(GDCEF_PROCESSES_PATH)
        compile_gdnative_stigmark()
    if not args.dont_compile_godot_editor:
        compile_godot_editor()
        install_godot_templates()
    else: # TODO use the installed Godot
        info("[USER REQUEST] Skip compiling Godot editor and installing its templates")
    if not args.dont_export_stigmee:
        export_stigmee()
    if args.deploy_stigmee:
        deploy_stigmee()
    else:
        info("[USER REQUEST] Skip deploy Stigmee")
    info("Cool! Stigmee project compiled with success!")
