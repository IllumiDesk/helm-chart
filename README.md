# IllumiDesk Helm Chart

IllumiDesk helm chart for Kubernetes setup

## Build Base JupyterHub Images

### Requirements

- Docker
- Python (nice-to-have v3.8)

### Overview

The `illumdesk/jupyterhub` images are built as follows:

- Base `illumidesk/jupyterhub:py3.8`: standard Jupyterhub image that builds from [source](https://github.com/jupyterhub/jupyterhub) using python3.8 and installs additional packages with pip.
- Sets user to `NB_USER=jovyan`, `NB_UID=1000`, and `NB_GID=100` and runs the JupyterHub service with this user.

> `Python 3.8` is used handle samesite cookie requirements and improved support for async.

### Quick Build/Push

    make build-push-jhubs

This command creates requirements.txt with `pip-compile`, builds docker images, and pushes them to the DockerHub registry.

Enter `make help` for additional options.

### The Hard Way

1. Setup virtualenv:

```bash
    virtualenv -p python3 venv
    source venv/bin/activate
    python3 -m pip install dev-requirements.txt
```

1. Build requirements.txt:

```bash
    pip-compile images/jupyterhub/requirements.in
```

> **Note**: The above command will overwrite the existing requirements.txt file.

2. Build the base JupyterHub image (illumidesk/jupyterhub:py3.8):

```bash
    docker build -t illumidesk/jupyterhub:py3.8 \
      images/jupyterhub/.
```

3. Build the JupyterHub Kubernetes image (illumidesk/k8s-hub:py3.8):

```bash
    docker build -t illumidesk/k8s-hub:py3.8 -f \
      images/jupyterhub/Dockerfile.k8s \
      images/jupyterhub/.
```

4. Push images to registry (DockerHub by default):

```bash
    docker push illumidesk/jupyterhub:py3.8
    docker push illumidesk/k8s-hub:py3.8
```
