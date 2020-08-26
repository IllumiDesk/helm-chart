ARG BASE_IMAGE=python:3.8-buster
FROM $BASE_IMAGE AS builder

ARG JUPYTERHUB_HASH_COMMIT=e58c34129035cbf9c49c8b737a7d9ae4c8afe94d

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV JUPYTERHUB_HASH_COMMIT=$JUPYTERHUB_HASH_COMMIT

RUN apt-get update \
 && apt-get install -yq --no-install-recommends \
    build-essential \
    locales \
    nodejs \
    npm \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# copy everything except whats in .dockerignore, its a
# compromise between needing to rebuild and maintaining
# what needs to be part of the build
WORKDIR /src

RUN git clone https://github.com/jupyterhub/jupyterhub
WORKDIR /src/jupyterhub
RUN git checkout -b builder "${JUPYTERHUB_HASH_COMMIT}"

RUN python3.8 -m pip install --upgrade setuptools pip wheel

# Build client component packages (they will be copied into ./share and
# packaged with the built wheel.)
RUN npm install
RUN python3.8 -m pip wheel --wheel-dir wheelhouse .


FROM $BASE_IMAGE

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -yq --no-install-recommends \
    gnupg \
    locales \
    nodejs \
    npm \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment \
 && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
 && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
 && locale-gen en_US.UTF-8

ENV SHELL=/bin/bash \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# always make sure pip is up to date!
RUN python3.8 -m pip install --no-cache --upgrade setuptools pip

# install chp
RUN npm install -g configurable-http-proxy@^4.2.0 \
 && rm -rf ~/.npm

# install the wheels we built in the first stage
COPY --from=builder /src/jupyterhub/wheelhouse /tmp/wheelhouse
RUN python3.8 -m pip install --no-cache /tmp/wheelhouse/*

# add additional packages used with k8s
WORKDIR /tmp/
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install -r /tmp/requirements.txt

RUN mkdir -p /srv/jupyterhub/
WORKDIR /srv/jupyterhub/

EXPOSE 8000
EXPOSE 8081

LABEL maintainer="IllumiDesk <hello@illumidesk.com>"

CMD ["jupyterhub", "-f", "/etc/jupyterhub/jupyterhub_config.py"]
