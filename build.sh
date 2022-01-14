#!/bin/bash -e
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
### This bash script allows to compile Stigmee project for Linux, MacOS X.
###
###############################################################################

### Green color message
function msg
{
    echo -e "\033[32m*** $*\033[00m"
}

### Red color message
function err
{
    echo -e "\033[31m*** $*\033[00m"
}

### Check if $WORKSPACE_STIGMEE is defined
if [ -z "$WORKSPACE_STIGMEE" ]; then
    err "Please export the environement variable WORKSPACE_STIGMEE and recall this script:"
    err "  export WORKSPACE_STIGMEE=<path/to/stigmee/workspace>"
    exit
fi

### Set pathes

STIGMEE_PROJECT_PATH=$WORKSPACE_STIGMEE/stigmee/stigmee
STIGMEE_BUILD_PATH=$STIGMEE_PROJECT_PATH/build

GODOT_VERSION=3.4.2-stable
GODOT_ROOT_PATH=$WORKSPACE_STIGMEE/godot/$GODOT_VERSION
GODOT_CPP_PATH=$GODOT_ROOT_PATH/cpp
GODOT_EDITOR_PATH=$GODOT_ROOT_PATH/editor
GODOT_EDITOR_BIN_PATH=$GODOT_EDITOR_PATH/bin
GODOT_EDITOR_ALIAS=$WORKSPACE_STIGMEE/godot-editor

GODOT_GDNATIVE_PATH=$WORKSPACE_STIGMEE/godot/gdnative
CEF_GDNATIVE_PATH=$GODOT_GDNATIVE_PATH/browser
STIGMARK_GDNATIVE_PATH=$GODOT_GDNATIVE_PATH/stigmark

GDCEF_PATH=$CEF_GDNATIVE_PATH/gdcef
GDCEF_PROCESSES_PATH=$CEF_GDNATIVE_PATH/gdcef_subprocess
GDCEF_THIRDPARTY_PATH=$CEF_GDNATIVE_PATH/thirdparty
CEF_PATH=$GDCEF_THIRDPARTY_PATH/cef_binary

### Check if pathes exist
# TODO

### Cleaning the project ?
TARGET="$1"
if [ "$TARGET" == "clean" ]; then
    rm -fr $STIGMEE_BUILD_PATH
    (cd $CEF_GDNATIVE_PATH && rm -fr thirdparty)
    (cd $GODOT_EDITOR_PATH && scons clean)
    (cd $GODOT_CPP_PATH && scons clean)
    exit 0
fi

### Compile the project in debug or release mode ?
if [ "$TARGET" == "debug" ]; then
    msg "Compilation in debug mode"
    GODOT_TARGET=debug
    CEF_TARGET=Debug
elif [ "$TARGET" == "release" ]; then
    msg "Compilation in release mode"
    GODOT_TARGET=release
    CEF_TARGET=Release
else
    err "Invalid target. Shall be debug or release"
    exit 1
fi

### Number of CPU cores
NPROC=
if [[ "$OSTYPE" == "darwin"* ]]; then
    NPROC=`sysctl -n hw.logicalcpu`
else
    NPROC=`nproc`
fi

### Instal system packages needed for compiling Godot
function install_prerequisite
{
    msg "Installing prerequesite packages on your system ..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get install build-essential yasm scons pkg-config libx11-dev \
             libxcursor-dev libxinerama-dev libgl1-mesa-dev libglu-dev \
             libasound2-dev libpulse-dev libudev-dev libxi-dev libxrandr-dev ninja-build
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        sudo pkg install py37-scons pkgconf xorg-libraries libXcursor libXrandr \
             libXi xorgproto libGLU alsa-lib pulseaudio yasm ninja-build
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install scons yasm cmake ninja
    elif [[ "$OSTYPE" == "msys"* ]]; then
        pacman -S --noconfirm --needed tar git make mingw-w64-x86_64-toolchain mingw-w64-x86_64-cmake \
               mingw-w64-x86_64-ninja mingw-w64-x86_64-python3-pip mingw-w64-x86_64-scons \
               mingw-w64-x86_64-gcc
        python -m pip install scons
    else
        err "Unknown architecture $OSTYPE: I dunno what to install as system packages"
        exit 1
    fi
}

### Compile godot-cpp
function compile_godot_cpp
{
    msg "Compiling Godot C++ API (inside $GODOT_CPP_PATH) ..."
    if [ ! -f $GODOT_CPP_PATH/bin/libgodot-cpp*$GODOT_TARGET* ]; then
        (cd $GODOT_CPP_PATH
         if [[ "$OSTYPE" == "linux-gnu"* ]]; then
             scons platform=linux target=$GODOT_TARGET --jobs=$NPROC
         elif [[ "$OSTYPE" == "freebsd"* ]]; then
             scons platform=linux target=$GODOT_TARGET --jobs=$NPROC
         elif [[ "$OSTYPE" == "darwin"* ]]; then
             ARCHI=`uname -m`
             if [[ "$ARCHI" == "x86_64" ]]; then
                 scons platform=osx macos_arch=x86_64 target=$GODOT_TARGET --jobs=$NPROC
             else
                 scons platform=osx macos_arch=arm64 target=$GODOT_TARGET --jobs=$NPROC
             fi
         elif [[ "$OSTYPE" == "msys"* ]]; then
             scons platform=windows use_mingw=True target=$GODOT_TARGET --jobs=$NPROC
         else
             err "Unknown architecture $OSTYPE: I dunno how install Godot-cpp"
             exit 1
         fi
        )
    fi
}

### Compile Godot editor
function compile_godot_editor
{
    msg "Compiling Godot Editor (inside $GODOT_EDITOR_PATH) ..."
    if [ ! -e $GODOT_EDITOR_ALIAS ]; then
        (cd $GODOT_EDITOR_PATH
         scons -j$NPROC
         if [ ! -L $GODOT_EDITOR_ALIAS ] || [ ! -e $GODOT_EDITOR_ALIAS ]; then
             ln -s $GODOT_EDITOR_BIN_PATH/godot.* $GODOT_EDITOR_ALIAS
         fi
        )
    fi
}

### Clone prebuild Chromium Embedded Framework and compile it
function compile_prebuilt_cef
{
    # Download and decompress if folder is not present
    if [ ! -d $CEF_PATH ]; then
        UNAMEM=`uname -m`
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if [[ "$UNAMEM" == "x86_64" ]]; then
                ARCHI="linux64"
            else
                ARCHI="linuxarm"
            fi
        elif [[ "$OSTYPE" == "freebsd"* ]]; then
            if [[ "$UNAMEM" == "x86_64" ]]; then
                ARCHI="linux64"
            else
                ARCHI="linuxarm"
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            if [[ "$UNAMEM" == "x86_64" ]]; then
                ARCHI="macosx64"
            else
                ARCHI="macosarm64"
            fi
        elif [[ "$OSTYPE" == "msys"* ]]; then
            if [[ "$UNAMEM" == "x86_64" ]]; then
                ARCHI="windows64"
            else
                ARCHI="windowsarm64"
            fi
        else
            err "Unknown archi $$OSTYPE: Cannot download Chromium Embedded Framework"
            exit 1
        fi

        # https://cef-builds.spotifycdn.com/index.html
        msg "Downloading Chromium Embedded Framework v96 for archi $ARCHI to $CEF_PATH ..."
        WEBSITE=https://cef-builds.spotifycdn.com
        CEF_TARBALL=cef_binary_96.0.14%2Bg28ba5c8%2Bchromium-96.0.4664.55_$ARCHI.tar.bz2

        # Download and simplify the folder name
        mkdir -p $GDCEF_THIRDPARTY_PATH
        (cd $GDCEF_THIRDPARTY_PATH
         wget -c $WEBSITE/$CEF_TARBALL -O- | tar -xj
         mv cef_binary* $CEF_PATH
        )
    fi

    ### Compile Chromium Embedded Framework if not already made
    msg "Compiling Chromium Embedded Framework in $CEF_TARGET mode (inside $CEF_PATH) ..."
    (cd $CEF_PATH
     mkdir -p build
     cd build
     # Compile with ninja or make
     if [ -x "$(which ninja)" ]; then
         cmake -G "Ninja" -DCMAKE_BUILD_TYPE=$CEF_TARGET ..
         VERBOSE=1 ninja -j$NPROC cefsimple
     else
         cmake -DCMAKE_BUILD_TYPE=$CEF_TARGET ..
         VERBOSE=1 make -j$NPROC cefsimple
     fi
    )

    ### For Mac OS X rename cef_sandbox.a to libcef_sandbox.a since Scons search for lib*
    if [[ "$OSTYPE" == "darwin"* ]]; then
        (cd $CEF_PATH/Debug && cp cef_sandbox.a libcef_sandbox.a)
        (cd $CEF_PATH/Release && cp cef_sandbox.a libcef_sandbox.a)
    fi

    ### Get all CEF compiled stuffs needed for Godot
    msg "Installing Chromium Embedded Framework to $STIGMEE_BUILD_PATH ..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        S="$CEF_PATH/$CEF_TARGET/Chromium Embedded Framework.framework/Libraries"
        cp --verbose -R "$S/"*.dylib $STIGMEE_BUILD_PATH

        S="$CEF_PATH/$CEF_TARGET/Chromium Embedded Framework.framework/Resources"
        cp --verbose -R "$S/" $STIGMEE_BUILD_PATH
    else
        S="$CEF_PATH/build/tests/cefsimple/$CEF_TARGET"
        cp --verbose "$S/v8_context_snapshot.bin" "$S/icudtl.dat" $STIGMEE_BUILD_PATH
        cp --verbose -R "$S/"*.pak "$S/"*.so* "$S/locales" $STIGMEE_BUILD_PATH
        cp --verbose "$S/"*.dll $STIGMEE_BUILD_PATH 2> /dev/null || echo ""
    fi
}

### Compile Godot CEF module named GDCef
function compile_godot_cef
{
    msg "Compiling Godot CEF module (inside $GDCEF_PATH) ..."
    (cd $GDCEF_PATH
     if [[ "$OSTYPE" == "linux-gnu"* ]]; then
         VERBOSE=1 scons platform=linux target=$GODOT_TARGET --jobs=$NPROC
     elif [[ "$OSTYPE" == "freebsd"* ]]; then
         VERBOSE=1 scons platform=linux target=$GODOT_TARGET --jobs=$NPROC
     elif [[ "$OSTYPE" == "darwin"* ]]; then
         ARCHI=`uname -m`
         if [[ "$ARCHI" == "x86_64" ]]; then
             VERBOSE=1 scons platform=osx arch=x86_64 target=$GODOT_TARGET --jobs=$NPROC
         else
             VERBOSE=1 scons platform=osx arch=arm64 target=$GODOT_TARGET --jobs=$NPROC
         fi
     elif [[ "$OSTYPE" == "msys"* ]]; then
         VERBOSE=1 scons platform=windows target=$GODOT_TARGET --jobs=$NPROC
     else
         err "Unknown archi $$OSTYPE: I dunno how to compile CEF module primary process"
         exit 1
     fi
    )
}

### Compile Godot CEF module named GDCef
function compile_cef_process
{
    msg "Compiling Godot CEF secondary process (inside $GDCEF_PROCESSES_PATH) ..."
    (cd $GDCEF_PROCESSES_PATH
     if [[ "$OSTYPE" == "linux-gnu"* ]]; then
         VERBOSE=1 scons platform=linux target=$GODOT_TARGET --jobs=$NPROC
     elif [[ "$OSTYPE" == "freebsd"* ]]; then
         VERBOSE=1 scons platform=linux target=$GODOT_TARGET --jobs=$NPROC
     elif [[ "$OSTYPE" == "darwin"* ]]; then
         ARCHI=`uname -m`
         if [[ "$ARCHI" == "x86_64" ]]; then
             VERBOSE=1 scons platform=osx arch=x86_64 target=$GODOT_TARGET --jobs=$NPROC
         else
             VERBOSE=1 scons platform=osx arch=arm64 target=$GODOT_TARGET --jobs=$NPROC
         fi
     else
         VERBOSE=1 scons platform=windows target=$GODOT_TARGET --jobs=$NPROC
     fi
    )
}

### Compile Godot CEF module named GDCef
function compile_stigmark
{
    LIB_STIGMARK=target/debug/libstigmark_client
    msg "Compiling Godot stigmark (inside $STIGMARK_GDNATIVE_PATH) ..."
    (cd $STIGMARK_GDNATIVE_PATH
     if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "freebsd"* || "$OSTYPE" == "msys"* ]]; then
        ./build-linux.sh
        cp --verbose $LIB_STIGMARK.so $STIGMEE_BUILD_PATH
     elif [[ "$OSTYPE" == "darwin"* ]]; then
        ./build-macosx.sh
        cp --verbose $LIB_STIGMARK.dylib $STIGMEE_BUILD_PATH
     else
        ./build-windows.cmd
        cp --verbose $LIB_STIGMARK.dll $STIGMEE_BUILD_PATH
     fi
    )
}

### Create the Stigmee executable
function compile_stigmee
{
    msg "Compiling Stigmee (inside $STIGMEE_PROJECT_PATH) ..."
    STIGMEE_BIN=
    EXPORT_CMD=
    (cd $STIGMEE_PROJECT_PATH
     if [[ "$OSTYPE" == "linux-gnu"* ]]; then
         STIGMEE_BIN=Stigmee.x11.$GODOT_TARGET.64
         EXPORT_CMD="Linux/X11"
     elif [[ "$OSTYPE" == "freebsd"* ]]; then
         STIGMEE_BIN=Stigmee.x11.$GODOT_TARGET.64
         EXPORT_CMD="Linux/X11"
     elif [[ "$OSTYPE" == "darwin"* ]]; then
         STIGMEE_BIN=Stigmee.osx.$GODOT_TARGET.64
         EXPORT_CMD="Mac OSX"
     else
         STIGMEE_BIN=Stigmee.win.$GODOT_TARGET.64.exe
         EXPORT_CMD="Windows Desktop"
         err "Unknown archi."
         exit 1
     fi

     STIGMEE_ALIAS=$WORKSPACE_STIGMEE/$STIGMEE_BIN
     $GODOT_EDITOR_ALIAS --export "$EXPORT_CMD" $STIGMEE_BUILD_PATH/$STIGMEE_BIN
     if [ ! -L $STIGMEE_ALIAS ] || [ ! -e $STIGMEE_ALIAS ]; then
        ln -s $STIGMEE_BUILD_PATH/$STIGMEE_BIN $STIGMEE_ALIAS
     fi
    )
}

### Script entry point
mkdir -p $STIGMEE_BUILD_PATH
install_prerequisite
compile_godot_cpp
compile_godot_editor
compile_prebuilt_cef
compile_godot_cef
compile_cef_process
compile_stigmark
compile_stigmee
msg "Cool! Stigmee project compiled with success!"
