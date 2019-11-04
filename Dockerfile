# ==================================================================
# module list
# ------------------------------------------------------------------
# python                    3.7    (apt)
# jupyter hub+lab           latest (pip)
# pytorch                   latest (pip)
# ax                        latest (pip)
# tensorflow +(keras-tuner) latest (pip)
# opencv                    4.1.1  (git)
# OpenAI gym                latest (pip)
# MLflow		            latest (pip)
# Spark+py+koalas+toree     2.4.4  (apt+pip)
# polynote                  latest (github tar)
# ==================================================================

FROM ubuntu:18.04
ENV LANG C.UTF-8
ARG APT_INSTALL="apt-get install -y --no-install-recommends --fix-missing"
ARG PIP_INSTALL="python -m pip --no-cache-dir install --upgrade"
ARG GIT_CLONE="git clone --depth 10"
ARG PYTHON_COMPAT_VERSION=3.7
ARG JAVA_VERSION=8
ARG SPARK_VERSION=2.4.4
ARG POLYNOTE_VERSION=0.2.11
ARG TORCHVISION_VERSION=0.4.1
ARG TORCH_VERSION=1.3.0

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
        sudo \
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
RUN DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        software-properties-common && \
	add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
	$APT_INSTALL \
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
RUN DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
    npm  nodejs && \
    npm install -g configurable-http-proxy && \
    $PIP_INSTALL \
        jupyterhub jupyterlab && \
        jupyterhub --generate-config

# ==================================================================
# pytorch
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
		torch==$TORCH_VERSION+cpu torchvision==$TORCHVISION_VERSION+cpu -f https://download.pytorch.org/whl/torch_stable.html
        
# ==================================================================
# ax
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
        ax-platform

# ==================================================================
# tensorflow with keras tuner
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
        tensorflow keras-tuner

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
# Spark (with pyspark and koalas)
# ------------------------------------------------------------------
ARG SPARK_ARCHIVE=https://www-eu.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz
RUN curl -s $SPARK_ARCHIVE | tar -xz -C /usr/local/

ENV SPARK_HOME /usr/local/spark-$SPARK_VERSION-bin-hadoop2.7
ENV PATH $PATH:$SPARK_HOME/sbin

RUN DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        openjdk-$JAVA_VERSION-jdk \
		scala \
        && \
    $PIP_INSTALL \
		pyspark \
		findspark \
        koalas
ENV JAVA_HOME /usr/lib/jvm/java-$JAVA_VERSION-openjdk-amd64

#Also, make sure your PYTHONPATH can find the PySpark and Py4J under $SPARK_HOME/python/lib:
# not sure if needed but polynote installation guide specifies this
RUN cp $(ls $SPARK_HOME/python/lib/py4j*) $SPARK_HOME/python/lib/py4j-src.zip
ENV PYTHONPATH $SPARK_HOME/python/lib/pyspark.zip:$SPARK_HOME/python/lib/py4j-src.zip:$PYTHONPATH

# install apache toree in jupyterlab
RUN $PIP_INSTALL \ 
    toree && \
    jupyter toree install --spark_home=$SPARK_HOME --interpreters=Scala,SQL

# ==================================================================
# Polynote
# ------------------------------------------------------------------
ARG POLYNOTE_ARCHIVE=https://github.com/polynote/polynote/releases/download/$POLYNOTE_VERSION/polynote-dist.tar.gz
RUN curl -sL $POLYNOTE_ARCHIVE | tar -zx -C /usr/local/
ENV POLYNOTE_HOME /usr/local/polynote

RUN $PIP_INSTALL \ 
    jep jedi pyspark virtualenv

# ==================================================================
# config & cleanup
# ------------------------------------------------------------------
RUN ldconfig && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*

# add default user
RUN groupadd -r dlenv && \
    useradd -r -p $(openssl passwd -1 dlenv) -g dlenv -G sudo dlenv
RUN mkdir -p /home/dlenv && \
    chown -R dlenv:dlenv /home/dlenv
    
# run as non-root
USER dlenv

# make sure data folder has proper permissions
RUN mkdir -p /home/dlenv/data
VOLUME /home/dlenv/data
WORKDIR /home/dlenv

# jupyterlab
EXPOSE 8888
# jupyterhub
EXPOSE 8000
# spark ui
EXPOSE 4040
#polynote
EXPOSE 8192

# change below for toree on remote spark
ENV SPARK_OPTS='--master=local[*]'
ENV JUPYTER_LAB_TOKEN="dlenv"
CMD ["sh", "-c", "jupyter lab --no-browser --ip=0.0.0.0 --NotebookApp.token=$JUPYTER_LAB_TOKEN --notebook-dir='/home/dlenv'"]
