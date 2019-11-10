#!/bin/bash

# jupyterhub needs to be run as root
docker run --rm -it \
    --name dlenv \
    --publish 8000:8000 \
	--publish 4040:4040 \
    --ipc host \
    --user root:root \
	konradmalik/dlenv jupyterhub --ip=0.0.0.0 --no-ssl --Spawner.default_url='/lab' --Spawner.env_keep="['PATH', 'PYTHONPATH', 'SPARK_HOME', 'CONDA_ROOT', 'CONDA_DEFAULT_ENV', 'VIRTUAL_ENV', 'LANG', 'LC_ALL']"
