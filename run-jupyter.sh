#!/bin/bash

docker run --rm -it \
    --name dlenv \
    --volume /home/konrad/Software/DLEnv/data:/data \
    --publish 8888:8888 \
	--publish 5000:5000 \
	--publish 4040:4040 \
	--ipc host \
	dlenv jupyter notebook --no-browser --ip=0.0.0.0 --allow-root --NotebookApp.token= --notebook-dir='/data'
