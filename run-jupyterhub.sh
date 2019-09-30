#!/bin/bash

docker run --rm -it \
    --name dlenv \
    --publish 8000:8000 \
	--publish 5000:5000 \
	--publish 4040:4040 \
    --ipc host \
    --user root:root \
    --volume /home/konrad/Software/DLEnv/data:/home/dlenv \
	dlenv jupyterhub --ip=0.0.0.0 --no-ssl

