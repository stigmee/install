# Apt-get Meta Packages Creation

On many GitHub projects, you can read on README documents that for compiling their applications, you will have to install **manually** several `apt-get` packages (`sudo apt-get install foo bar ...`). This is a poor way of doing it! Indeed, once you have installed these packages and if you are bored of the application, you usually do not remember which packages to remove and which one is already used by another application. In addition this has to be done one by one. Meta packages is just a simple Debian/Ubuntu package that just refering to other packages. Once installed, if you want later to remove it, the packager is aware of the graph dependency of your package and therfore can remove uneeded packages.

## Steps for creating your own meta package

This section should be seen as a quick tutorial. The deb package is already present.

```bash
equivs-control <project-name>
```

For example `equivs-control stigmee-developpers`.

A `stigmee-developpers.cfg` file should has been created.
Edit it and fill the important following fields: `Package`, `Version`, `Depends` `Description`. **The list of depending packages shall be separated by commas.** For example (this is a very basic example):
```
- Package: stigmee-developpers
- Version: 1.0
- Depends: openssh-server, gedit
- Description: This package installes ...
```

Finally, build the package by running:
```bash
equivs-build stigmee-developpers.cfg
```

The `stigmee-developpers_1.0_all.deb` shall have been created. To install it, type:
```bash
sudo dpkg -i stigmee-developpers_1.0_all.deb
```
