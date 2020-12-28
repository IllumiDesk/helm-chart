FROM jupyterhub/k8s-hub:0.9.1

# ensure pip is up to date
RUN python3 -m pip install --upgrade pip

COPY requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt
