# Termux Synapse Guide
This guide will show you how to setup synapse to host your matrix server on termux.
It is just a way of following the official documentations while applying the workarounds that has to be done in termux to survive the harsh Android environment.

## matrix-synapse
It is possible to install [Synapse as a Python module](https://matrix-org.github.io/synapse/latest/setup/installation.html#installing-as-a-python-module-from-pypi) from PyPI (which is what were are going to do).  
First install the platform-specific prerequisites
```
$ pkg install build-essential binutils python rust libffi sqlite openssl  libjpeg-turbo
$ pip install virtualenv
```
One of the dependencies of the `matrix-synapse` python module is the [cryptography](https://cryptography.io/en/latest/) which will be built via rust. In most cases, rust will not be able to build it since it cannot determine the build target see [termux-packages#8037](https://github.com/termux/termux-packages/issues/8037).  
The build target can be specified via the `CARGO_BUILD_TARGET` environment variable.  
You can use the command `rustc --print target-list | grep android` to see the target list that you can choose from based on your architecture (ps: You can check your architecture via the command `uname -m`)
Here we will use armv7 architecture as an example.
```
$ export CARGO_BUILD_TARGET=armv7-linux-androideabi
```
Now we can carry on with the rest of the official installation instructions. Here we will have the synapse folder under `$PREFIX/opt`
```sh
$ mkdir -p $PREFIX/opt/synapse
$ cd $PREFIX/opt/synapse
$ virtualenv -p python3 env
$ source ./env/bin/activate
$ pip install --upgrade pip
$ pip install --upgrade setuptools
$ pip install matrix-synapse
```

Then it's now time to generate a configuration file. In the same directory (and while the virtual environment is activated). Execute the following:
```sh
$ python -m synapse.app.homeserver \
    --server-name my.domain.name \
    --config-path homeserver.yaml \
    --generate-config \
    --report-stats=<yes/now>
```
Replace `my.domain.name` with your domain name, and choose weather you'd like to report usage statictics to the developers using the flag `--report-stats=` [read more about this in the official synaps docs](https://matrix-org.github.io/synapse/latest/setup/installation.html#installing-as-a-python-module-from-pypi)

One last step I prefer to add (you can ignore this if you like and use what's provided in the official docs) is to have synctl binary that does what synctl should do in the virtualenv.
add a file in your `$PREFIX/bin/` (or anywhere in your path) called `synctl` and add the following to it:
```
#!/data/data/com.termux/files/usr/bin/bash

cd $PREFIX/opt/synapse
source ./env/bin/activate
./env/bin/synctl "$@"
```
Don't forget to make it executable by running the command `chmod +x $PREFIX/bin/synctl`
**NOTE:** It is generally not recommended to add executables to your `$PREFIX/bin`. If you want to do this right, you might want to consider using `$HOME/.local/bin` and adding it to your path.

## Finally
This guide is incomplete. Over the next few days. I will continue adding the rest of the steps to have a complete synapse matrix server running on your phone. Until that time, you are somewhat on your own. Consider the guides online (their numbers are huge even though non of them is considering termux) and try to improvise.
