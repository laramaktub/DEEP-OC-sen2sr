# Dockerfile has two Arguments: tag, branch
# tag - tag for Tensorflow Image (default: 1.12.0-py3)
# branch - user repository branch to clone (default: master, other option: test)

ARG tag=1.12.0-py3

FROM tensorflow/tensorflow:${tag}
LABEL maintainer="Ignacio Heredia (CSIC) <iheredia@ifca.unican.es>"
LABEL version="0.1"
LABEL description="DEEP as a Service Container: Sentinel-2 super-resolution"

# What user branch to clone (!)
ARG branch=master

# Install ubuntu updates and python related stuff
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get upgrade -y  && \
    apt-get install -y --no-install-recommends \
         git \
         curl \
         wget \
         python3-setuptools \
         python3-pip \
         python3-wheel && \ 
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/*


# Set LANG environment
ENV LANG C.UTF-8

# Set the working directory
WORKDIR /srv

# install rclone
RUN wget https://downloads.rclone.org/rclone-current-linux-amd64.deb && \
    dpkg -i rclone-current-linux-amd64.deb && \
    apt install -f && \
    mkdir /srv/.rclone/ && touch /srv/.rclone/rclone.conf && \
    rm rclone-current-linux-amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/*

# Install FLAAT (FLAsk support for handling Access Tokens)
RUN pip install --no-cache-dir flaat && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/*

# Disable FLAAT authentication by default
ENV DISABLE_AUTHENTICATION_AND_ASSUME_AUTHENTICATED_USER yes

# For the time being we will use the test_args branch from DEEPaaS until DEEPaaS 1.0 is released
RUN git clone -b test-args https://github.com/indigo-dc/deepaas && \
    cd  deepaas && \
    pip install --no-cache-dir -e . && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/* && \
    cd ..

# Install DEEPaaS from PyPi:
# RUN pip install --no-cache-dir deepaas && \
#    rm -rf /root/.cache/pip/* && \
#    rm -rf /tmp/*

# Install spatial packages
RUN add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable && \
	apt update && \
	apt install -y gdal-bin python-gdal python3-gdal

## Install user app
RUN git clone -b ${branch} https://github.com/deephdc/sen2sr && \
    cd  sen2sr && \
    pip install --no-cache-dir -e . && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/* && \
    cd ..

# Open DEEPaaS port
EXPOSE 5000

# Open Monitoring port
EXPOSE 6006

# Account for OpenWisk functionality (deepaas >=0.3.0)
CMD ["sh", "-c", "deepaas-run --openwhisk-detect --listen-ip 0.0.0.0"]
