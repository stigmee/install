# Stigmee compilation and continuous actions

## Operating systems

Stigmee can be compiled for Linux, Windows >= 10 (and with the administration
rights), and MacOS X. Stigmee is not yet functional for MacOS X.  Stigmee is not
supported for Windows 9 and older or Windows 10 without administration
rights. In the future Stigmee is expected to run for Android and IOS
devices. Your help is welcome!

For compiling Stigmee, you will need an operating system with > 2 Gb of RAM and
> 14 Gb of free disk space.  The Stigmee binary once compiled is ~300 Mb on
Linux (~100 Mb on Windows) your disk (plus the cache of visited pages) and need
~300 Mb of RAM when running (Linux).

## Prerequisites to compile Stigmee

### Step 1: Set the Stigmee environment variable

For any operating systems (Linux, MacOS X, Windows), you will need the
environment variable `WORKSPACE_STIGMEE` set to the path of your workspace (the
folder in which you will download all code source).

- For Linux and MacOS X:

For Linux and MacOS X, you have this environment variable in your `~/.bashrc`
file (or any equivalent file), the environment variable `$WORKSPACE_STIGMEE`
referring to the workspace folder for compiling Stigmee. It is used by our
internal scripts:

```bash
export WORKSPACE_STIGMEE=/your/desired/path/for/workspace_stigmee
```

- For Windows 10:

For Windows, you can either save this variable inside the "System Properties" as
"Environment Variables" like depicted by the following figure:

![winreg](https://github.com/stigmee/doc-internal/blob/master/doc/winreg.png)

Or set the path for the workspace every time you open a console (this is up to you!):

```
set WORKSPACE_STIGMEE c:\workspace_stigmee
```

### Step 2: Install Python3 packages

Our `build.py` script is made in **Python3** to be usable for any operating
systems (Linux, MacOS X, Windows). Please do not use Python 2. To make the
installation possible, you will have to install the following python3 modules:

```
python3 -m pip install packaging python3_wget scons tsrc pysftp
```

- `scons` is a Makefile made in Python and it is needed to compile Godot.
- `tsrc` is needed to download all GitHub repos needed. First, please read and
  follow instruction depicted in this
  [repository](https://github.com/stigmee/manifest) to install the tool that
  will help you to keep up-to-date the Stigmee workspace.
- `python3_wget` and `packaging` are needed to download and unarchive some tarballs.
- `pysftp` is optional and only needed for deploying releases our SFTP server.

### Step 3: Install system packages

Install the following tools: `g++`, `ninja`, `cmake` (greater or equal to
3.21.0), `rust` (and Visual Studio for Windows).

- For Linux, depending on your distribution you can use `sudo apt-get install`.
  To upgrade your cmake you can see this
  [script](https://github.com/stigmee/doc-internal/blob/master/doc/install_latest_cmake.sh).
- For MacOS X you can install [homebrew](https://brew.sh/index_fr).
- For Windows user you will have to install:
  - Visual Studio: https://visualstudio.microsoft.com/en/vs/ (mandatory)
  - Python3: https://www.python.org/downloads/windows/
  - CMake: https://cmake.org/download/
  - Ninja: https://ninja-build.org/
  - Git: https://git-scm.com/download/win
  - cURL: https://curl.se/windows/microsoft.html
  - Rust: https://www.rust-lang.org/tools/install (For Windows users:
    https://doc.rust-lang.org/cargo/getting-started/installation.html install
    rustup-init.exe with administrator rights).

**Still experimental:**
The Stigmee Python3 build script `$WORKSPACE_STIGMEE/build.py`, through the
command line `--install-packages`, can install system packages needed to compile
Stigmee. You will need sudo and apt-get install for Linux, homebrew for MacOs
X ...

### Step 4: Checkout your CMake version

On Debian, Ubuntu you probably have to compile and install by yourself a newer
version of CMake needed to compile the Chromium Embedded Framework (>=
3.22). You can follow this [bash
script](https://github.com/stigmee/doc-internal/blob/master/doc/install_latest_cmake.sh).

### Step 5: Have a SSH connexion to GitHub

To download Stigmee workspace, we have set the manifest file for `tsrc` tool to
use SSH connexion ot GitHub.  A manifest is a file holding info such as git
repos the project needs and where in the workspace to download them. For more
information see this [document](https://github.com/stigmee/manifest).

If you still preferring using HTTPS, you can configure your git settings:
```
git config --global url."https://github".insteadOf git://github
```

See here for more information: https://ricostacruz.com/til/github-always-ssh
(but it may conflicts with Rust when installing its own packages by git
cloning).

## Download Stigmee workspace

For more information on how to keep your workspace up-to-date see this
[document](https://github.com/stigmee/manifest).  To initialize the workspace
for Stigmee for the first time, you will have to type:

- For Linux and MacOS X:

```bash
mkdir $WORKSPACE_STIGMEE
cd $WORKSPACE_STIGMEE
tsrc --color=never --verbose init git@github.com:stigmee/manifest.git
tsrc --color=never --verbose sync
```

- For Windows 10:

**Mandatory:** You **shall** to use **x64 Native Tools Command Prompt for VS
2022** (installed when you have installed Visual Studio 2022) with
**administrator** permissions to allow the creation of aliases!

```
mkdir %WORKSPACE_STIGMEE%
cd %WORKSPACE_STIGMEE%
tsrc --color=never --verbose init git@github.com:stigmee/manifest.git
tsrc --color=never --verbose sync
```

This will setup the appropriate subfolder structures for all Stigmee modules,
which is mandatory in order to use the below scripts. If everything is working
well, you will have the following workspace for Stigmee (may change):

```
📦workspace_stigmee
 ┣ 📂stigmee             ➡️ Main Stigmee project
 ┃ ┗ 📂build             ➡️ (Generated) Stigmee binaries
 ┃   ┗ 📦stigmee         ➡️ (Generated) Stigmee application
 ┣ 📂doc
 ┃ ┣ 📂API               ➡️ Public documentation
 ┃ ┗ 📂internal          ➡️ Stigmee documention
 ┣ 📂godot
 ┃ ┣ 📂3.4.3
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
 ┗ 📜build.py            ➡️ Link to packages/install/build.py for compiling Stigmee
```

## Compile Stigmee for Unix systems

### Straight method

To compile Stigmee for Linux (BSD untested) and MacOS X, either in release mode:

```bash
export $WORKSPACE_STIGMEE=<workspace_home>
cd $WORKSPACE_STIGMEE
./build.py
```

Or in debug mode:

```bash
export $WORKSPACE_STIGMEE=<workspace_home>
cd $WORKSPACE_STIGMEE
./build.py --debug
```

Once done, Stigmee binary is present in the `$WORKSPACE_STIGMEE/stigmee/build/`
folder (for example for Linux `Stigmee.x11.debug.64`).

**Note:** If the `build.py` fails by indicating it does not know to access to
`from helper import *` please check:
- if `build.py` is an alias (Windows user shall have administrator rights).
- Call `build.py` from the folder `$WORKSPACE_STIGMEE/packages/install`.

**Note:** This command will also compile locally a Godot editor (version
3.4.3-stable) and use it. Used it to develop the Stigmee application and to
export (aka compiling) Stigmee binaries.

**Workaround:** For Linux, for the moment, Stigmee does not find correctly the
`libcef.so` while indicated in the `gdnlib` file. So for the moment:

```bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$WORKSPACE_STIGMEE/stigmee/build
```

### With Dockerfile (experimental)

You can compile Stigmee through a Docker. See this [document](docker/README.md).

## Compile Stigmee for Windows

To compile Stigmee for Windows:
- Ensure VS2022 is installed
- Open an **x64 Native Tools Command Prompt for VS 2022**, with
  **Administrator** privilege (this should be available in the start menu under
  Visual Studio 2022). This ensures the environment is correctly set to use the
  VS tools.
- Run the below commands from this command line :

```bash
set WORKSPACE_STIGMEE=<workspace_home>
cd %WORKSPACE_STIGMEE%
build.py
```

**Note:** The following files are only used for the Windows build:
`libcef_dll_wrapper_cmake` and `cef_variables_cmake`.  The build script installs
the compiled libraries into both the build directory (for final executable run)
and the Godot editor directory (mandatory for running CEF from a development
project). Also not that for the moment, the final Stigmee executable is not
generated (this will be included soon)

## Update your workspace to be synchronized with your coworkers latest changes

This section is for Stigmee developers. Simply, go in any folder in your
workspace and type:

```
cd $WORKSPACE_STIGMEE
tsrc sync
```

### Bash script helper

This section is for Stigmee developers. Here is a small utility to help
initializing or synchronizing your Stigmee workspace for Unix. You can add it in
your `~/.bashrc` file.

```bash
export WORKSPACE_STIGMEE=/your/desired/path/for/workspace_stigmee
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$WORKSPACE_STIGMEE/stigmee/build

function update_stigmee()
{
    if [ "$WORKSPACE_STIGMEE" == "" ]; then
        echo "Please export WORKSPACE_STIGMEE to refer to your desired folder."
        echo "The save the export command in your .bashrc file"
        exit 1
    fi

    if [ -d "$WORKSPACE_STIGMEE/.tsrc" ]; then
        cd "$WORKSPACE_STIGMEE"
        tsrc sync
    else
        mkdir -p "$WORKSPACE_STIGMEE" || exit 1
        cd "$WORKSPACE_STIGMEE"
        tsrc --verbose init git@github.com:stigmee/manifest.git
        tsrc sync
    fi

    ./build.py
}
```

## build.py command line

The `./build.py` have command line. You can type `./build.py -h` to show the
help.

## Continuous integration and continuous deployment

This section is for Stigmee developers. (In gestation) Made with GitHub actions
inside the `.github/workflows` folder and read its
[README](.github/workflows/README.md) for more information.
