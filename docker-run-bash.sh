#!/bin/bash

docker run --rm -it \
	--name dlenv \
    --volume `pwd`/data:/home/dlenv/data \
	--publish 4040:4040 \
    --ipc host \
    --user root:root \
	konradmalik/dlenv bash 
