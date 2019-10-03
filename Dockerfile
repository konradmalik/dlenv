# ==================================================================
# module list
# ------------------------------------------------------------------
# python                    3.7    (apt)
# jupyter hub+lab           latest (pip)
# pytorch                   latest (pip)
# ax                        latest (pip)
# tensorflow                latest (pip)
# opencv                    4.1.1  (git)
# OpenAI gym                latest (pip)
# MLflow		            latest (pip)
# Spark/pySpark/toree       2.4.4  (apt+pip)
# ==================================================================

FROM ubuntu:18.04
ENV LANG C.UTF-8
ENV APT_INSTALL="DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --fix-missing"
ENV PIP_INSTALL="python -m pip --no-cache-dir install --upgrade"
ENV GIT_CLONE="git clone --depth 10"
ENV PYTHON_COMPAT_VERSION=3.7

RUN rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get update

# ==================================================================
# tools
# ------------------------------------------------------------------
RUN $APT_INSTALL \
        build-essential \
        apt-utils \
        ca-certificates \
        wget \
        git \
        vim \
        curl \
        unzip \
        unrar \
        cmake \
		tmux

# ==================================================================
# python
# ------------------------------------------------------------------
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    $APT_INSTALL \
        software-properties-common \
        python${PYTHON_COMPAT_VERSION} \
        python${PYTHON_COMPAT_VERSION}-dev \
        python3-distutils-extra \
		libblas-dev liblapack-dev libatlas-base-dev gfortran \
        && \
    wget -O ~/get-pip.py \
        https://bootstrap.pypa.io/get-pip.py && \
    python${PYTHON_COMPAT_VERSION} ~/get-pip.py && \
    ln -s /usr/bin/python${PYTHON_COMPAT_VERSION} /usr/local/bin/python3 && \
    ln -s /usr/bin/python${PYTHON_COMPAT_VERSION} /usr/local/bin/python && \
    $PIP_INSTALL \
        setuptools \
        numpy \
        scipy \
        pandas \
        cloudpickle \
        scikit-learn \
		joblib \
        matplotlib \
        Cython \
        h5py

# ==================================================================
# jupyter hub
# ------------------------------------------------------------------
RUN $APT_INSTALL \
    npm  nodejs && \
    npm install -g configurable-http-proxy && \
    $PIP_INSTALL \
        jupyterhub jupyterlab && \
        jupyterhub --generate-config

# ==================================================================
# pytorch
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
		torch==1.2.0+cpu torchvision==0.4.0+cpu -f https://download.pytorch.org/whl/torch_stable.html
        
# ==================================================================
# ax
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
        ax-platform

# ==================================================================
# tensorflow
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
        tensorflow

# ==================================================================
# opencv
# ------------------------------------------------------------------
RUN $APT_INSTALL \
        libatlas-base-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-serial-dev \
        libleveldb-dev \
        liblmdb-dev \
        libprotobuf-dev \
        libsnappy-dev \
        protobuf-compiler \
        && \
    $GIT_CLONE --branch 4.1.1 https://github.com/opencv/opencv ~/opencv && \
    mkdir -p ~/opencv/build && cd ~/opencv/build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D WITH_IPP=OFF \
          -D WITH_CUDA=OFF \
          -D WITH_OPENCL=OFF \
          -D BUILD_TESTS=OFF \
          -D BUILD_PERF_TESTS=OFF \
          .. && \
    make -j"$(nproc)" install && \
    ln -s /usr/local/include/opencv4/opencv2 /usr/local/include/opencv2

# ==================================================================
# OpenAI GYM
# ------------------------------------------------------------------
RUN $APT_INSTALL \
        python3-dev \
        zlib1g-dev \
        libjpeg-dev \
        cmake \
        swig \
        python-pyglet \
        python3-opengl \
        libboost-all-dev \
        libsdl2-dev \
        libosmesa6-dev \
        patchelf \
        ffmpeg \
        xvfb \
        && \
    $PIP_INSTALL \
        gym \
		'gym[atari]' \
		'gym[box2d]'
    
# ==================================================================
# MLflow 
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
		mlflow && \
		sed -i 's/127.0.0.1/0.0.0.0/g' /usr/local/lib/python${PYTHON_COMPAT_VERSION}/dist-packages/mlflow/cli.py && \
        curl -LO http://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
        bash Miniconda3-latest-Linux-x86_64.sh -p /miniconda -b && \
        rm Miniconda3-latest-Linux-x86_64.sh
ENV PATH=/miniconda/bin:${PATH}

# ==================================================================
# Spark
# ------------------------------------------------------------------
ARG SPARK_ARCHIVE=https://www-eu.apache.org/dist/spark/spark-2.4.4/spark-2.4.4-bin-hadoop2.7.tgz
RUN curl -s $SPARK_ARCHIVE | tar -xz -C /usr/local/

ENV SPARK_HOME /usr/local/spark-2.4.4-bin-hadoop2.7
ENV PATH $PATH:$SPARK_HOME/bin

RUN DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        openjdk-8-jdk \
		scala \
        && \
    $PIP_INSTALL \
		pyspark \
		findspark

# install apache toree in jupyterlab
RUN $PIP_INSTALL \ 
    toree && \
    jupyter toree install --spark_home=$SPARK_HOME --interpreters=Scala,SQL

# ==================================================================
# config & cleanup
# ------------------------------------------------------------------
RUN ldconfig && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*

# add default user
RUN groupadd -r dlenv && \
    useradd -r -p $(openssl passwd -1 dlenv) -g dlenv dlenv
RUN mkdir -p /home/dlenv && \
    chown -R dlenv:dlenv /home/dlenv
    
# make sure data folder has proper permissions
VOLUME /home/dlenv
WORKDIR /home/dlenv
# run as non-root
USER dlenv

EXPOSE 8888 6006 5000

# change below for toree on remote spark
ENV SPARK_OPTS='--master=local[*]'
ENV JUPYTER_LAB_TOKEN="dlenv"
CMD ["jupyter","lab","--no-browser","--ip=0.0.0.0","--NotebookApp.token=$JUPYTER_LAB_TOKEN","--notebook-dir='/home/dlenv'"]
