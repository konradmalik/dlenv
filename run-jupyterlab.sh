#!/bin/bash

docker run --rm -it \
    --name dlenv \
    --publish 8888:8888 \
	--publish 4040:4040 \
    --ipc host \
    --volume `pwd`/data:/home/dlenv/data \
	konradmalik/dlenv

