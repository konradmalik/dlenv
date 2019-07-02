# DLEnv

Container for ML, AI, Deep Learning, reinforcement learning etc.

Inspired by <https://github.com/ufoym/deepo> but modified to my liking.

If you are not familiar with VIM/do not want VIM-like bindings in jupyter, then you need to delete Dockerfile lines marked as "jupyter vim bindings".

Build container using "make":

```bash
$ make build
```

Then run either bash shell or jupyter server using provided shell scripts.

**REMEMBER** to change data folder path to the container in the scripts. Data folder will be shared between the host and container. Save your scripts, data, files etc. there to have access to them from the container or to persist them.

Run scripts are currently set up to autodelete after exit so all data that is not in the "data" folder will be lost!
