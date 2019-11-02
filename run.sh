#!/bin/bash

docker run --rm -it \
	--name dlenv \
    --volume `pwd`/data:/home/dlenv/data \
    --publish 8888:8888 \
	--publish 5000:5000 \
	--publish 4040:4040 \
    --ipc host \
	konradmalik/dlenv bash 
