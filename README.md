# Stigmee compilation and continous actions

## Prerequisites

First, please read and follow instruction depicted in this [repository](https://github.com/stigmee/manifest).
For example be sure this variable `$WORKSPACE_STIGMEE` is defined.

## Compile Stigmee

To compile Stigmee, for Linux and MacOS X (but not for Windows yet), either in debug mode:

```bash
./build.sh debug
```

Or in release mode:

```bash
./build.sh release
```

Once done, Stigmee binary is present in the `$WORKSPACE_STIGMEE/stigmee/build/` folder (for example for Linux `Stigmee.x11.debug.64`).

**Note:** This command will also install localy a Godot editor (version 3.4.2-stable). Used it to develop the Stigmee
application and to export (aka compiling) Stigmee binaries.

## Continous integration and continous deployment

(In gestation) Made with GitHub actions inside the `.github/workflows` folder and read its [README](.github/workflows/README.md) for more
information.
