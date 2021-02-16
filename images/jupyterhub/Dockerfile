ARG BASE_IMAGE=jupyterhub/k8s-hub:0.11.1
FROM "${BASE_IMAGE}"

ARG ILLUMIDESK_VERSION=1.1.1

USER root

# ensure pip is up to date
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install unzip wget \
 && python3 -m pip install --upgrade pip

COPY requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt

USER "${NB_UID}"

WORKDIR /tmp
RUN wget "https://github.com/IllumiDesk/illumidesk/archive/v${ILLUMIDESK_VERSION}.zip" -O /tmp/illumidesk.zip \
 && unzip /tmp/illumidesk.zip \
 && python3 -m pip install --upgrade --force-reinstall "/tmp/illumidesk-${ILLUMIDESK_VERSION}/src/illumidesk/."

COPY --chown=1000:100 illumidesk-80.png /srv/jupyterhub/illumidesk-80.png

WORKDIR /srv/jupyterhub
