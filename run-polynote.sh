#!/bin/bash

docker run --rm -it \
    --name dlenv \
    --publish 8192:8192 \
	--publish 4040:4040 \
    --ipc host \
	konradmalik/dlenv /usr/local/polynote/polynote.py

