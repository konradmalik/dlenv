[![Build Status](https://travis-ci.com/konradmalik/dlenv.svg?branch=master)](https://travis-ci.com/konradmalik/dlenv)
# DLEnv

Container for ML, AI, Deep Learning, reinforcement learning etc.

For contents, included libraries etc. see the first couple of lines of the Dockerfile.

Inspired by <https://github.com/ufoym/deepo> but modified to my liking.

Build container using "make":

```bash
$ make build
```

Then run either bash shell or jupyter server using provided shell scripts.

Run scripts are currently set up to autodelete after exit so all data that is not in the "data" folder will be lost!
