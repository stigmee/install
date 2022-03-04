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

### Third part versions
GODOT_VERSION="3.4.2-stable"
CEF_VERSION="98.2.0+g78c653a+chromium-98.0.4758.102"

### Set pathes
STIGMEE_PROJECT_PATH=$WORKSPACE_STIGMEE/stigmee
STIGMEE_BUILD_PATH=$STIGMEE_PROJECT_PATH/build
GODOT_ROOT_PATH=$WORKSPACE_STIGMEE/godot/$GODOT_VERSION
GODOT_CPP_PATH=$GODOT_ROOT_PATH/cpp
GODOT_EDITOR_PATH=$GODOT_ROOT_PATH/editor
GODOT_EDITOR_BIN_PATH=$GODOT_EDITOR_PATH/bin
GODOT_EDITOR_ALIAS=$WORKSPACE_STIGMEE/godot-editor
GODOT_GDNATIVE_PATH=$WORKSPACE_STIGMEE/godot/gdnative
CEF_GDNATIVE_PATH=$GODOT_GDNATIVE_PATH/browser
CEF_GODOT_EXAMPLE_BUILD=$CEF_GDNATIVE_PATH/example/build
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
    GODOT_EDITOR_TARGET=debug
    GODOT_CPP_TARGET=debug
    CEF_TARGET=Debug
elif [ "$TARGET" == "release" ]; then
    msg "Compilation in release mode"
    GODOT_EDITOR_TARGET=release_debug
    GODOT_CPP_TARGET=release
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
             libasound2-dev libpulse-dev libudev-dev libxi-dev libxrandr-dev ninja-build \
             libgtk-3-dev libssl-dev rustc
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        sudo pkg install py37-scons pkgconf xorg-libraries libXcursor libXrandr \
             libXi xorgproto libGLU alsa-lib pulseaudio yasm ninja-build libssl-dev rustc
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install scons yasm cmake ninja openssl rust rustup
    elif [[ "$OSTYPE" == "msys"* ]]; then
        pacman -S --noconfirm --needed tar git make mingw-w64-x86_64-toolchain mingw-w64-x86_64-cmake \
               mingw-w64-x86_64-ninja mingw-w64-x86_64-python3-pip mingw-w64-x86_64-scons \
               mingw-w64-x86_64-gcc openssl-devel rust
    else
        err "Unknown architecture $OSTYPE: I dunno what to install as system packages"
        exit 1
    fi

    python3 -m pip install scons
    python3 -m pip install tsrc
    python3 -m pip install requests

    # Check if cmake version is >= 3.19
    CMAKE_CURRENT_VERSION=`cmake --version | head -n1 | cut -d" " -f3`
    CMAKE_MIN_VERSION="3.19"
    if [ "$CMAKE_MIN_VERSION" = "`echo -e "$CMAKE_CURRENT_VERSION\n$CMAKE_MIN_VERSION" | sort -r -V | head -n1`" ]; then
        err "Your CMake version is $CMAKE_CURRENT_VERSION but shall be >= $CMAKE_MIN_VERSION"
        err "See $WORKSPACE_STIGMEE/doc/internal/doc/install_latest_cmake.sh to update it before running this script"
    fi
}

### Remove and clear the Stigmee's build folder.
### Failed if trying to delete something which is not a folder.
### Removing the folder will remove GPUCache, logs and Stigmee binary
### that we do not want since we want to compute MD5 on files.
function create_build_dir
{
    if [ -d $STIGMEE_BUILD_PATH ]; then
        rm -fr $STIGMEE_BUILD_PATH
    fi
    mkdir -p $STIGMEE_BUILD_PATH
}

### Compile godot-cpp
function compile_godot_cpp
{
    msg "Compiling Godot C++ API (inside $GODOT_CPP_PATH) ..."
    if [ ! -f $GODOT_CPP_PATH/bin/libgodot-cpp*$GODOT_CPP_TARGET* ]; then
        (cd $GODOT_CPP_PATH
         if [[ "$OSTYPE" == "linux-gnu"* ]]; then
             scons platform=linux target=$GODOT_CPP_TARGET --jobs=$NPROC
         elif [[ "$OSTYPE" == "freebsd"* ]]; then
             scons platform=linux target=$GODOT_CPP_TARGET --jobs=$NPROC
         elif [[ "$OSTYPE" == "darwin"* ]]; then
             ARCHI=`uname -m`
             if [[ "$ARCHI" == "x86_64" ]]; then
                 scons platform=osx macos_arch=x86_64 target=$GODOT_CPP_TARGET --jobs=$NPROC
             else
                 scons platform=osx macos_arch=arm64 target=$GODOT_CPP_TARGET --jobs=$NPROC
             fi
         elif [[ "$OSTYPE" == "msys"* ]]; then
             scons platform=windows use_mingw=True target=$GODOT_CPP_TARGET --jobs=$NPROC
         else
             err "Unknown architecture $OSTYPE: I dunno how to compile Godot-cpp"
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
         # Check if we are not running inside GitHub actions docker
         if [ -z "$GITHUB_ACTIONS" -a -z "$CI" ]; then
             if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                 scons platform=linux target=$GODOT_EDITOR_TARGET --jobs=$NPROC
             elif [[ "$OSTYPE" == "freebsd"* ]]; then
                 scons platform=linux target=$GODOT_EDITOR_TARGET --jobs=$NPROC
             elif [[ "$OSTYPE" == "darwin"* ]]; then
                 ARCHI=`uname -m`
                 if [[ "$ARCHI" == "x86_64" ]]; then
                     scons platform=osx macos_arch=x86_64 target=$GODOT_EDITOR_TARGET --jobs=$NPROC
                 else
                     scons platform=osx macos_arch=arm64 target=$GODOT_EDITOR_TARGET --jobs=$NPROC
                 fi
             elif [[ "$OSTYPE" == "msys"* ]]; then
                 scons platform=windows use_mingw=True target=$GODOT_EDITOR_TARGET --jobs=$NPROC
             else
                 err "Unknown architecture $OSTYPE: I dunno how to compile Godot editor"
                 exit 1
             fi
         else
             # Compile a Godot editor without X11 (godot --no-window does not
             # work with Linux but only on Windows)
             echo "Compiling Godot in headless mode ..."
             scons plateform=x11 tools=no vulkan=no x11=no target=$GODOT_EDITOR_TARGET --jobs=$NPROC
         fi
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

    # CEF already installed ? Installed with a different version ?
    # Compare our desired version with the one stored in the CEF README
    FOUND=`grep "$CEF_VERSION" "$CEF_PATH/README.txt" || echo ""`
    if [ ! -z "$FOUND" ]; then
        msg "Chromium Embedded Framework $CEF_VERSION already installed"
    else
        msg "Downloading Chromium Embedded Framework $CEF_VERSION $ARCHI to $CEF_PATH ..."
        mkdir -p "$GDCEF_THIRDPARTY_PATH"
        (cd $GDCEF_THIRDPARTY_PATH
         # Remove the CEF folder if exist and partial downloaded folder
         rm -fr cef_binary* || echo ""

         # Replace the '+' chars by URL percent encoding '%2B'
         CEF_URL_VERSION=`echo "$CEF_VERSION" | sed -e 's/+/%2B/g'`
         CEF_TARBALL="cef_binary_$CEF_URL_VERSION""_$ARCHI.tar.bz2"

         # Download CEF at https://cef-builds.spotifycdn.com/index.html
         # and untaring it at the same time
         WEBSITE=https://cef-builds.spotifycdn.com
         wget -c $WEBSITE/$CEF_TARBALL -O- | tar -xj
         sleep 1

         # Simplify the folder name by removing the complex version number
         mv cef_binary* $CEF_PATH
        )
    fi

    ### Compile Chromium Embedded Framework if not already made
    if [ -d $CEF_PATH ]; then
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
    fi
}

### Copy CEF assets to Stigmee build folder
function install_cef_assets
{
    ### For Mac OS X rename cef_sandbox.a to libcef_sandbox.a since Scons search for lib*
    if [[ "$OSTYPE" == "darwin"* ]]; then
        (cd $CEF_PATH/Debug && cp cef_sandbox.a libcef_sandbox.a)
        (cd $CEF_PATH/Release && cp cef_sandbox.a libcef_sandbox.a)
    fi

    ### Get all CEF compiled stuffs needed for Godot
    msg "Installing Chromium Embedded Framework to $STIGMEE_BUILD_PATH ..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        S="$CEF_PATH/$CEF_TARGET/Chromium Embedded Framework.framework/Libraries"
        cp -R "$S/"*.dylib $STIGMEE_BUILD_PATH

        S="$CEF_PATH/$CEF_TARGET/Chromium Embedded Framework.framework/Resources"
        cp -R "$S/" $STIGMEE_BUILD_PATH
    else
        S="$CEF_PATH/build/tests/cefsimple/$CEF_TARGET"
        cp --verbose "$S/v8_context_snapshot.bin" "$S/icudtl.dat" $STIGMEE_BUILD_PATH
        cp --verbose -R "$S/"*.pak "$S/"*.so* "$S/locales" $STIGMEE_BUILD_PATH
        cp --verbose "$S/"*.dll $STIGMEE_BUILD_PATH 2> /dev/null || echo ""
    fi
}

### Common Scons command for compiling our Godot modules
function cef_scons_cmd
{
    VERBOSE=1 scons workspace=$WORKSPACE_STIGMEE \
           godot_version=$GODOT_VERSION target=$GODOT_CPP_TARGET --jobs=$NPROC \
           arch=`uname -m` platform=$1
}

### Compile Godot CEF module named GDCef and its subprocess
function compile_godot_cef
{
    msg "Compiling Godot CEF module (inside $1) ..."

    (cd $1
     if [[ "$OSTYPE" == "linux-gnu"* ]]; then
         cef_scons_cmd "x11"
     elif [[ "$OSTYPE" == "freebsd"* ]]; then
         cef_scons_cmd "x11"
     elif [[ "$OSTYPE" == "darwin"* ]]; then
         cef_scons_cmd "osx"
     elif [[ "$OSTYPE" == "msys"* ]]; then
         cef_scons_cmd "windows"
     else
         err "Unknown archi $OSTYPE: I dunno how to compile CEF module primary process"
         exit 1
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
         (cd src-stigmarkmod && cef_scons_cmd "x11")
         cp --verbose $LIB_STIGMARK.so $STIGMEE_BUILD_PATH
     elif [[ "$OSTYPE" == "darwin"* ]]; then
         ./build-macosx.sh
         (cd src-stigmarkmod && cef_scons_cmd "osx")
         cp --verbose $LIB_STIGMARK.dylib $STIGMEE_BUILD_PATH
     else
         ./build-windows.cmd
         (cd src-stigmarkmod && cef_scons_cmd "windows")
         cp --verbose $LIB_STIGMARK.dll $STIGMEE_BUILD_PATH
     fi
    )
}

### Download and install Godot export tempates
function install_godot_templates
{
    msg "Downloading Godot templates ..."

    # Check the folder in where templates shall be installed
    TEMPLATES_PATH=
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        TEMPLATES_PATH="$HOME/.local/share/godot/templates/"
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        TEMPLATES_PATH="$HOME/.local/share/godot/templates/"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        err "Unknown archi: darwin"
        exit 1
    else
        err "Unknown archi: $OSTYPE"
        exit 1
    fi

    # From "3.4.2-stable" separate "3.4.2" and "stable" we need
    # both of them and convert the '-' to '.'
    V=`echo $GODOT_VERSION | cut -d"-" -f1`
    S=`echo $GODOT_VERSION | cut -d"-" -f2`
    TEMPLATE_FOLDER_NAME="$V"
    if [ ! -z "$S" ]; then
        TEMPLATE_FOLDER_NAME+=".$S"
    fi

    # Download the tpz file (zip) if folder is not present
    if [ ! -d "$TEMPLATES_PATH/$TEMPLATE_FOLDER_NAME" ]; then
        msg "Downloading Godot templates into $TEMPLATES_PATH ..."

        # Where to download the zip file
        WEBSITE="https://downloads.tuxfamily.org/godotengine/$V"
        TEMPLATES_TARBALL="Godot_v$GODOT_VERSION""_export_templates.tpz"

        # Contrary to CEF we cannot unzip while downloading.
        mkdir -p "$TEMPLATES_PATH"
        (cd $TEMPLATES_PATH
         wget -O templates-$GODOT_VERSION.zip $WEBSITE/$TEMPLATES_TARBALL
         unzip templates-$GODOT_VERSION.zip
         # In addition the folder name inside the zip is "templates" but
         # shall be the Godot version: so rename it after and beware to
         # convert the '-' to '.'
         mv templates "$TEMPLATE_FOLDER_NAME"
        )
    fi
}

### Create the Stigmee executable
function compile_stigmee
{
    msg "Compiling Stigmee (inside $STIGMEE_PROJECT_PATH) ..."
    STIGMEE_BIN=
    EXPORT_CMD=
    (cd $STIGMEE_PROJECT_PATH
     if [[ "$OSTYPE" == "linux-gnu"* ]]; then
         STIGMEE_BIN=Stigmee.x11.$GODOT_CPP_TARGET.64
         EXPORT_CMD="Linux/X11"
     elif [[ "$OSTYPE" == "freebsd"* ]]; then
         STIGMEE_BIN=Stigmee.x11.$GODOT_CPP_TARGET.64
         EXPORT_CMD="Linux/X11"
     elif [[ "$OSTYPE" == "darwin"* ]]; then
         STIGMEE_BIN=Stigmee.osx.$GODOT_CPP_TARGET.64
         EXPORT_CMD="Mac OSX"
     else
         STIGMEE_BIN=Stigmee.win.$GODOT_CPP_TARGET.64.exe
         EXPORT_CMD="Windows Desktop"
         err "Unknown archi."
         exit 1
     fi

     STIGMEE_ALIAS=$WORKSPACE_STIGMEE/stigmee-$TARGET
     $GODOT_EDITOR_ALIAS --no-window --export "$EXPORT_CMD" $STIGMEE_BUILD_PATH/$STIGMEE_BIN
     if [ ! -L $STIGMEE_ALIAS ] || [ ! -e $STIGMEE_ALIAS ]; then
         ln -s $STIGMEE_BUILD_PATH/$STIGMEE_BIN $STIGMEE_ALIAS
     fi
     if [ ! -L $CEF_GODOT_EXAMPLE_BUILD ] || [ ! -e $CEF_GODOT_EXAMPLE_BUILD ]; then
         ln -s $STIGMEE_BUILD_PATH $CEF_GODOT_EXAMPLE_BUILD
     fi
    )
}

### Script entry point
install_prerequisite
create_build_dir
compile_godot_cpp
compile_godot_editor
compile_prebuilt_cef
install_cef_assets
compile_godot_cef "$GDCEF_PATH"
compile_godot_cef "$GDCEF_PROCESSES_PATH"
compile_stigmark
install_godot_templates
compile_stigmee
msg "Cool! Stigmee project compiled with success!"
