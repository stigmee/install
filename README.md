# Stigmee compilation and continous actions

## Prerequisites

First, please read and follow instruction depicted in this [repository](https://github.com/stigmee/manifest).
For example be sure the `WORKSPACE_STIGMEE` variable is defined.
It is recommanded to used tsrc to synchornise with the up-to-date stigmee repositories

```bash
cd <workspace_home>
tsrc --color=never init git@github.com:stigmee/manifest.git
tsrc --color=never sync
```

This will setup the appropriate subfolder structures for all stigmee modules, which is mandatory in order to use the below scripts.

## Compile Stigmee for Unix systems

To compile Stigmee for Linux (BSD untested) and MacOS X, either in debug mode:

```bash
export $WORKSPACE_STIGMEE=<workspace_home>
cd <workspace_home>
./build_unix.sh debug
```

Or in release mode:

```bash
export $WORKSPACE_STIGMEE=<workspace_home>
cd <workspace_home>
./build_unix.sh release
```

Once done, Stigmee binary is present in the `$WORKSPACE_STIGMEE/stigmee/build/` folder (for example for Linux `Stigmee.x11.debug.64`).

**Note:** This command will also install localy a Godot editor (version 3.4.2-stable). Used it to develop the Stigmee
application and to export (aka compiling) Stigmee binaries.

## Compile Stigmee for Windows

To compile Stigmee for Windows, (only in release mode for now) :

```bash
set WORKSPACE_STIGMEE=<workspace_home>
cd <workspace_home>
./build_win.bat
```

**Note:** The following files are used for the Windows build: `checkenv.py`, `libcef_dll_wrapper_cmake` and `cef_variables_cmake`.
The build script installs the compiled libraries into both the build directory (for final executable run) and the godot editor directory (mandatory for running cef from a development project). Also not that for the moment, the final Stigmee executable is not generated (this will be included soon)

## Continous integration and continous deployment

(In gestation) Made with GitHub actions inside the `.github/workflows` folder and read its [README](.github/workflows/README.md) for more
information.
