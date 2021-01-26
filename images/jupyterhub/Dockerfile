ARG BASE_IMAGE=jupyterhub/k8s-hub:0.11.1
FROM "${BASE_IMAGE}"

# ensure pip is up to date
RUN python3 -m pip install --upgrade pip

COPY requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt

COPY --chown=1000:100 illumidesk-80.png /srv/jupyterhub/illumidesk-80.png
