# IllumiDesk Helm Chart

IllumiDesk helm chart for Kubernetes setup

## Build Base JupyterHub Images

### Quick Build/Push

    make build-push-jhubs

### Build `docker build ...`

1. Build base image (illumidesk/jupyterhub:py3.8):

    cd images/jupyterhub
    docker build -t illumidesk/k8s-jhub:py3.8

2. Build Kubernetes image (illumidesk/k8s-jhub:py3.8):

    cd images/jupyterhub
    docker build -t illumidesk/k8s-jhub:py3.8 -f Dockerfile.k8s images/jupyterhub/.

3. Push images to registry (DockerHub by default):

    docker push illumidesk/jupyterhub:py3.8
    docker push illumidesk/k8s-jhub:py3.8

## Build Custom JupyterHub Images

1. 