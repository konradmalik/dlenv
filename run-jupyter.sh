#!/bin/bash

docker run --rm -it \
    --name dlenv \
    --volume /home/konrad/Software/DLEnv/data:/data \
    --publish 8888:8888 \
    --ipc host \
	dlenv jupyter notebook --no-browser --ip=0.0.0.0 --allow-root --NotebookApp.token= --notebook-dir='/root'
