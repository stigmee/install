# Stigmee compilation and continous actions

## Operating systems

Stigmee can be compiled for Linux, Windows 10, and MacOS X. Stigmee is not yet working for MacOS X.

For compiling Stigmee, you will need an operating system with > 2 Gb of RAM and > 14 Gb of free disk space.
The Stigmee binary once compiled is ~300 Mb on your disk (plus the cache of visited pages) and need ~300 Mb
of RAM when running.

## Prerequisites to compile Stigmee

### Repository manifest

First, please read and follow instruction depicted in this [repository](https://github.com/stigmee/manifest)
to install the tool that will help you to keep up-to-date the Stigmee workspace. This document will also tell
you which system packages needed to make it work and also how to set up your SSH connection.

### Other system packages

Install the following tools: `g++`, `ninja`, `cmake` (greater or equal to 3.21.0), `rust` (and Visual Studio for Windows).

- For Linux, depending on your distribution you can use `sudo apt-get install`. To upgrade your cmake you can see this [script](https://github.com/stigmee/doc-internal/blob/master/doc/install_latest_cmake.sh).
- For MacOS X you can install [homebrew](https://brew.sh/index_fr).
- For Windows user you will have to install:
  - CMake: https://cmake.org/download/
  - Ninja: https://ninja-build.org/
  - Visual Studio: https://visualstudio.microsoft.com/en/vs/

You will have to install the following python3 modules:
```
python3 -m pip install packaging pysftp python3_wget scons tsrc
```

On Debian, Ubuntu you probably have to compile and install by yourself a newer version of CMake. You can follow this
[bash script](https://github.com/stigmee/doc-internal/blob/master/doc/install_latest_cmake.sh).

## Set Stigmee's environment variables

- For Linux and MacOS X, you have this environment variable in your `~/.bashrc` file
(or any equivalent file), the environment variable `$WORKSPACE_STIGMEE` referring to
the workspace folder for compiling Stigmee. It is used by our internal scripts:

```bash
export WORKSPACE_STIGMEE=/your/desired/path/for/workspace_stigmee
```

- For Windows, you can either save this variable inside the "System Properties" as
"Environnement Variables" like depicted by the following figure:

![winreg](https://github.com/stigmee/doc-internal/blob/master/doc/winreg.png)

Or set the path for the workspace everytime you open a console (this is up to you!):

```
set WORKSPACE_STIGMEE c:\workspace_stigmee
```

**Linux Workaround:** For the moment Godot does not find correctly the libcef.so while indicated in the
gdnlib file. So for the moment:

```bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$WORKSPACE_STIGMEE/stigmee/build
```

## Download Stigmee workspace

For more information on how to keep your workspace up-to-date see this [document](https://github.com/stigmee/manifest). To initialize your workspace

- For Linux and MacOS X:

```bash
mkdir $WORKSPACE_STIGMEE
cd $WORKSPACE_STIGMEE
tsrc --verbose init git@github.com:stigmee/manifest.git
tsrc --verbose sync
```

- For Windows (x64 Native Tools Command Prompt for VS 2022):

```
mkdir %WORKSPACE_STIGMEE%
cd %WORKSPACE_STIGMEE%
tsrc --color=never --verbose init git@github.com:stigmee/manifest.git
tsrc --color=never --verbose sync
```

This will setup the appropriate subfolder structures for all stigmee modules, which is mandatory in order to use the below scripts. If everything is working well, you will have the following workspace for
Stigmee (may change):

```
📦workspace_stigmee
 ┣ 📂stigmee             ➡️ Main Stigmee project
 ┃ ┗ 📂build             ➡️ (Generated) Stigmee binaries
 ┃   ┗ 📦stigmee         ➡️ (Generated) Stigmee application
 ┣ 📂doc
 ┃ ┣ 📂API               ➡️ Public documentation
 ┃ ┗ 📂internal          ➡️ Stigmee documention
 ┣ 📂godot
 ┃ ┣ 📂3.4.2
 ┃ ┃ ┣ 📂editor          ➡️ To compile the Godot editor
 ┃ ┃ ┗ 📂cpp             ➡️ Godot C++ API
 ┃ ┗ 📂gdnative          ➡️ Stigmee modules as Godot native modules
 ┃   ┣ 📂stigmark        ➡️ Client for workspace_stigmee/stigmark
 ┃   ┗ 📂browser         ➡️ Chromium Embedded Framework
 ┣ 📂packages
 ┃ ┣ 📂install           ➡️ Scripts for building and continous integration
 ┃ ┃ ┗ 📜build.py        ➡️ Main build script for compiling Stigmee
 ┃ ┣ 📂manifest          ➡️ Manifest knowing all Stigmee git repositories
 ┃ ┣ 📂beebots           ➡️ AI to "bookmark" tabs
 ┃ ┗ 📂stigmark          ➡️ Browser extensions to "bookmark" tabs on private server
 ┣ 📜README.md           ➡️ Link to the installation guide
 ┗ 📜build.py            ➡️ Link to packages/install/build.sh for compiling Stigmee
```

## Compile Stigmee for Unix systems

To compile Stigmee for Linux (BSD untested) and MacOS X, either in debug mode:

```bash
export $WORKSPACE_STIGMEE=<workspace_home>
cd $WORKSPACE_STIGMEE
./build.py debug
```

Or in release mode:

```bash
export $WORKSPACE_STIGMEE=<workspace_home>
cd $WORKSPACE_STIGMEE
./build.py release
```

Once done, Stigmee binary is present in the `$WORKSPACE_STIGMEE/stigmee/build/` folder (for example for Linux `Stigmee.x11.debug.64`).

**Note:** This command will also install localy a Godot editor (version 3.4.2-stable). Used it to develop the Stigmee
application and to export (aka compiling) Stigmee binaries.

## Compile Stigmee for Windows

To compile Stigmee for Windows, (only in release mode for now) :
- Ensure VS2022 is installed
- Open an **x64 Native Tools Command Prompt for VS 2022**, with **Administrator** privilege (this should be available in the start menu under Visual Studio 2022). This ensures the environment is correctly set to use the VS tools.
- Run the below commands from this command line :

```bash
set WORKSPACE_STIGMEE=<workspace_home>
cd %WORKSPACE_STIGMEE%
build.py
```

**Note:** The following files are only used for the Windows build: `libcef_dll_wrapper_cmake` and `cef_variables_cmake`.
The build script installs the compiled libraries into both the build directory (for final executable run) and the godot editor directory (mandatory for running cef from a development project). Also not that for the moment, the final Stigmee executable is not generated (this will be included soon)

## Continous integration and continous deployment

(In gestation) Made with GitHub actions inside the `.github/workflows` folder and read its [README](.github/workflows/README.md) for more
information.
