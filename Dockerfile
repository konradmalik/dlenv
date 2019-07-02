# ==================================================================
# module list
# ------------------------------------------------------------------
# python        3.6    (apt)
# jupyter       latest (pip) - with vim binding, remove this if you are not familiar with VIM
# pytorch       latest (pip)
# ax            latest (pip)
# tensorflow    latest (pip)
# opencv        4.1.0  (git)
# OpenAI gym    latest (pip)
# MLflow		latest (pip)
# Spark/pySpark 2.4.3  (apt+pip)
# ==================================================================

FROM ubuntu:18.04
ENV LANG C.UTF-8
ENV APT_INSTALL="apt-get install -y --no-install-recommends"
ENV PIP_INSTALL="python -m pip --no-cache-dir install --upgrade"
ENV GIT_CLONE="git clone --depth 10"

RUN rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get update

# ==================================================================
# tools
# ------------------------------------------------------------------

RUN DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        build-essential \
        apt-utils \
        ca-certificates \
        wget \
        git \
        vim \
        curl \
        unzip \
        unrar \
        cmake

# ==================================================================
# python
# ------------------------------------------------------------------

RUN DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        software-properties-common \
        && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        python3.6 \
        python3.6-dev \
        python3-distutils-extra \
        && \
    wget -O ~/get-pip.py \
        https://bootstrap.pypa.io/get-pip.py && \
    python3.6 ~/get-pip.py && \
    ln -s /usr/bin/python3.6 /usr/local/bin/python3 && \
    ln -s /usr/bin/python3.6 /usr/local/bin/python && \
    $PIP_INSTALL \
        setuptools \
        && \
    $PIP_INSTALL \
        numpy \
        scipy \
        pandas \
        cloudpickle \
        scikit-learn \
        matplotlib \
        Cython \
        h5py

# ==================================================================
# jupyter
# ------------------------------------------------------------------

RUN $PIP_INSTALL \
        jupyter \
        && \

# ==================================================================
# jupyter vim binding
# ------------------------------------------------------------------
    # Create required directory in case (optional)
    mkdir -p $(jupyter --data-dir)/nbextensions && \
    # Clone the repository
    cd $(jupyter --data-dir)/nbextensions && \
    git clone https://github.com/lambdalisue/jupyter-vim-binding vim_binding && \
    # Activate the extension
    jupyter nbextension enable vim_binding/vim_binding

# ==================================================================
# pytorch
# ------------------------------------------------------------------

RUN $PIP_INSTALL \
    	https://download.pytorch.org/whl/cpu/torch-1.1.0-cp36-cp36m-linux_x86_64.whl && \
    $PIP_INSTALL \
        https://download.pytorch.org/whl/cpu/torchvision-0.3.0-cp36-cp36m-linux_x86_64.whl
        
# ==================================================================
# ax
# ------------------------------------------------------------------
        
RUN $PIP_INSTALL \
        ax-platform

# ==================================================================
# tensorflow
# ------------------------------------------------------------------

RUN $PIP_INSTALL \
        tensorflow==2.0.0-beta1

# ==================================================================
# opencv
# ------------------------------------------------------------------

RUN DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
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

    $GIT_CLONE --branch 4.1.0 https://github.com/opencv/opencv ~/opencv && \
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

RUN DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
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
		'gym[algorithmic]' \
		'gym[atari]' \
		'gym[box2d]' \
		'gym[classic_control]' \
		'gym[toy_text]'
    
# ==================================================================
# MLflow 
# ------------------------------------------------------------------

RUN $PIP_INSTALL \
		mlflow

# ==================================================================
# Spark
# ------------------------------------------------------------------

ARG SPARK_ARCHIVE=https://www-eu.apache.org/dist/spark/spark-2.4.3/spark-2.4.3-bin-hadoop2.7.tgz
RUN curl -s $SPARK_ARCHIVE | tar -xz -C /usr/local/

ENV SPARK_HOME /usr/local/spark-2.4.3-bin-hadoop2.7
ENV PATH $PATH:$SPARK_HOME/bin

RUN DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        openjdk-8-jdk \
		scala \
        && \

    $PIP_INSTALL \
		pyspark \
		findspark

# ==================================================================
# config & cleanup
# ------------------------------------------------------------------

RUN ldconfig && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*

EXPOSE 8888 6006
