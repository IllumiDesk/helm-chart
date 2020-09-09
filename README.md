# IllumiDesk Helm Chart

:warning: Draft Status :warning:

## Overview

Use this [helm chart](https://helm.sh/docs/topics/charts/) to install IllumiDesk on AWS EKS. This chart depends on the [jupyterhub](https://zero-to-jupyterhub.readthedocs.io/en/latest/).

This setup pulls images defined in the `illumidesk/values.yaml` file from `DockerHub`. To push new versions of these images or to change the image's tag(s) (useful for testing), then follow the instructions in the [build images section](#build-images).  

## Requirements

- [helm >= v3](https://github.com/kubernetes/helm)
- (Optional) [Docker](https://docs.docker.com/get-docker/)
- (Optional) [Python 3.6+](https://www.python.org/downloads/)


## Installation

1. Add the IllumiDesk chart repository:

```bash
    helm repo add illumidesk https://illumidesk.github.io/helm-chart/
    helm repo update
```

2. Install IllumiDesk:

```shell
    helm install illumidesk/illumidesk --version=<version> --name=<release name> --namespace=<namespace> -f /path/to/custom/values.yaml
```

3. Apply changes:

```bash
    helm upgrade <release name> pangeo/pangeo -f /path/to/custom/values.yaml
```

## Cleanup

```bash
    helm delete <release name> --purge
```

## Images

### Singleuser Images

By default this chart sets the `singleuser` image to [illumidesk/base-notebook](https://hub.docker.com/r/illumidesk/base-notebook). However, any image maintained in the [illumidesk/docker-stacks](https://github.com/illumidesk/docker-stacks) repo is compatible with this chart.

The `illumidesk/docker-stacks` images are based off of the `jupyterh/docker-stacks` conventions. You can therefore use any of the images in the `jupyterh/docker-stacks` repo which are [also available in dockerhub](https://hub.docker.com/u/jupyter).

To set an alternate image for end-users, update the `singleuser.image` key in the `illumidesk/values.yaml` file.

### JupyterHub Images

There are two Dockerfiles to create two version of the JupyterHub image (`illumidesk/jupyterhub`):

- `illumidesk/jupyterhub`: standard JupyterHub image that uses Python 3.8 and installs the illumidesk package. The illumidesk package contains customized authenticators and spawners.
- `illumidesk/k8s-hub`: inherits from the above image and defines the `NB_USER`, `NB_UID`, and `NB_GID` to run the container.

#### Quick Build/Push

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

5. Update `jupyterhub.image.name` with image name. The image name should include the full image namespace and tag.

6. Install IllumiDesk with `helm` as inatructed in the first section.

# Helm Setup

## Setup Cluster
1. Install [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
2. Use `aws configure` to configure aws CLI 
3.  Create **IAM policy** using aws cli for alb ingress policy
   * `aws iam create-policy \
    --policy-name ALBIngressControllerIAMPolicy \
    --policy-document file://IAM/alb-policy.json` 
4.   Create **IAM policy** using aws cli for external dns policy
   * `aws iam create-policy \
    --policy-name AllowExternalDNSUpdates \
    --policy-document file://IAM/dns-policy.json` 
5.  Open _**cluster/custer.yaml**_ and update the following:
    *   Attached ARN policies for the **alb-ingress-controller** and **external-dns**
        *   format: `arn:aws:iam::XXXXXXXXX:policy/AllowExternalDNSUpdates`
    *   Public Key Path of public key used in your aws environment
        *   [AWS KEY Pair Guide ](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
    *   Name and AWS Region of your eks cluster
6.  Create the eks cluster
    * `eksctl create cluster -f cluster/cluster.yaml`

## Helm Chart setup

1. Install [Helm 3](https://helm.sh/docs/intro/install/#helm)
2. Verify it works using `helm list`
3. Create a namespace for your helm chart
   * `kubectl create namespace $NAMESPACE`
4. Create a values yaml file locally and pass the chart values that you would like to override
    * You must override the following:
    * | Key         | Description                                      |
      | ----------- | ------------------------------------------------ |
      |   awsAccessKey     | Access Key created for your account       |
      | awsSecretToken     | Secret token provided by aws              |
      | secretToken     | Secret token for proxy generated by oppenssl           |
      | clusterName     | name of EKS cluster created from eksctl            |
      | clusterVPC     | VPC ID of vpc generated by eksctl for your cluster         |
      | awsRegion     | aws region where your cluster is located              |
      | subnets     | subnets that are part of your cluster vpc. At least 2 required            |
      | domainFilter     | your aws route 53 hosted zonezone              |
      | txtOwnerID     | identifies externalDNS instance            |
5. Using your values yaml file create the helm chart in your helm chart namespace 
    * `helm upgrade --install $RELEASE ./illumidesk/ --namespace $NAMESPACE --values path/to/file/values.yaml`
5. Once complete, verify the url 
   * `dig jhub.example.com`