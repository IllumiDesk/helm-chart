# IllumiDesk's JupyterHub

## Overview

JupyterHub built as a docker image meant for deployment with IllumiDesk's Kubernetes-based
stack.

## Local Development

Images are built and tagged automatically by DockerHub. The instructions below are useful for local builds required
for testing.

### Build Docker Image

```bash
docker build --build-arg BASE_IMAGE=jupyterhub/k8s-hub:0.9.1 illumidesk/jupyterhub:latest
```

### Run the Image

Run the image locally with docker:

```bash
docker run -it --rm -p 80:80 illumidesk/jupyterhub:latest
```

Then navigate to http://localhost/.

### Update Dependencies

Update requirements.txt with pip-compile:

```bash
pip-compile requirements.in
```
