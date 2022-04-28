# Dockerfile for compiling Stigmee

(in gestation)

The environment variable `$WORKSPACE_STIGMEE` is not necessary in this case. Simply create the folder you desire to
hold the workspace and go to this folder (in my case `/tmp/stigmee`). Then run the docker [stigmee](https://hub.docker.com/r/lecrapouille/stigmee) against your folder.

```bash
mkdir <WORKSPACE_STIGMEE>
cd <WORKSPACE_STIGMEE>
docker run --rm -it -v $(pwd):$(pwd) -w $(pwd) stigmee:latest
```

You will see the Docker prompt where the Docker user name is `stigmeer`:
```bash
stigmeer@cc03e4088369:/tmp/stigmee$
```

If your workspace, you can type the following commands:
```bash
tsrc --color=never --verbose init git@github.com:stigmee/manifest.git
tsrc --color=never --verbose sync
```

Then, still from the Docker, compile Stigmee:

```bash
./build.py
```

Inside your folder `/tmp/stigmee`, the Docker, even as user `stigmeer`, will download, create folders, create files, create binaraies, with the same user id and with the same permission than your folder. It will not work if your folderis owned by `root`.

Note: The docker image can be compiled as:
```bash
cd $WORKSPACE_STIGMEE/packages/install/docker/
docker build -t stigmee .
```

But this can take some time to compile, therefore you can download directly at:
https://hub.docker.com/r/lecrapouille/stigmee (around 1 GB).
