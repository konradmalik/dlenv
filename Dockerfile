# ==================================================================
# module list
# ------------------------------------------------------------------
# python                    3.7    (apt)
# java+scala                8;2.12 (apt)
# jupyter hub+lab           latest (pip)
# pytorch                   latest (pip)
# ax                        latest (pip)
# tensorflow +(keras-tuner) latest (pip)
# NLP (spacy, nltk)         latest (pip)
# opencv                    4.1.1  (git)
# OpenAI gym                latest (pip)
# MLflow		            latest (pip)
# Spark+utility             2.4.5  (apt+pip)
# ==================================================================

FROM konradmalik/spark:latest

# ==================================================================
# python
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
        setuptools \
        numpy \
        scipy \
        pandas \
        cloudpickle \
        scikit-learn \
        joblib \
        matplotlib \
        Cython \
        h5py \
        onnx onnxruntime

# ==================================================================
# jupyter hub
# ------------------------------------------------------------------
RUN eval $APT_INSTALL \
    npm  nodejs && \
    npm install -g configurable-http-proxy && \
    $PIP_INSTALL \
        jupyterhub jupyterlab && \
    mkdir -p /etc/jupyterhub
COPY configs/jupyterhub_config.py /etc/jupyterhub/jupyterhub_config.py

# ==================================================================
# pytorch
# ------------------------------------------------------------------
ENV TORCHVISION_VERSION=0.5.0
ENV TORCH_VERSION=1.4.0
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
# NLP tools
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
        nltk spacy fuzzywuzzy[speedup] gensim && \
        python -m nltk.downloader popular -d /usr/share/nltk_data && \
        python -m spacy download en

# ==================================================================
# opencv
# ------------------------------------------------------------------
RUN eval $APT_INSTALL \
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
    $GIT_CLONE --branch 4.2.0 https://github.com/opencv/opencv ~/opencv && \
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
RUN eval $APT_INSTALL \
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
ENV PATH=${PATH}:/miniconda/bin
RUN conda init && \
        conda config --set auto_activate_base false

# ==================================================================
# Polynote
# ------------------------------------------------------------------
ENV POLYNOTE_VERSION=0.3.3
ENV POLYNOTE_ARCHIVE=https://github.com/polynote/polynote/releases/download/$POLYNOTE_VERSION/polynote-dist.tar.gz
RUN curl -sL $POLYNOTE_ARCHIVE | tar -zx -C /usr/local/
ENV POLYNOTE_HOME /usr/local/polynote

RUN $PIP_INSTALL \ 
    jep jedi virtualenv

# ==================================================================
# config & cleanup
# ------------------------------------------------------------------
RUN ldconfig && \
    apt-get clean && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*

# add default user
ENV DEFAULT_USER=dlenv
COPY scripts/add-user.sh add-user.sh
RUN chmod +x add-user.sh && ./add-user.sh $DEFAULT_USER

# make spark dir owned by that user
RUN chown -R $DEFAULT_USER:$DEFAULT_USER $SPARK_HOME

# make jupyter notebook token equal to username by default
ENV JUPYTER_LAB_TOKEN=$DEFAULT_USER

# copy run scripts
COPY scripts/run-* /
RUN chmod +x /run-*

# run as non-root
USER $DEFAULT_USER

# make sure data folder has proper permissions
RUN mkdir -p /home/$DEFAULT_USER/data
VOLUME /home/$DEFAULT_USER/data

# jupyterlab
EXPOSE 8888
# jupyterhub
EXPOSE 8000
# spark ui
EXPOSE 4040
# spark master
EXPOSE 7077
# spark worker
EXPOSE 8081
