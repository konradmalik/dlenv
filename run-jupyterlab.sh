#!/bin/bash

docker run --rm -it \
    --name dlenv \
    --publish 8888:8888 \
	--publish 5000:5000 \
	--publish 4040:4040 \
    --ipc host \
	dlenv

    #--volume /home/konrad/Software/DLEnv/data:/home/dlenv \
