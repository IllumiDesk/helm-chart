# IllumiDesk Helm Chart

:warning: Draft Status :warning:

## Overview

Use this [helm chart](https://helm.sh/docs/topics/charts/) to install IllumiDesk on AWS EKS. This chart depends on the [jupyterhub](https://zero-to-jupyterhub.readthedocs.io/en/latest/).

This setup pulls images defined in the `illumidesk/values.yaml` file from `DockerHub`. To push new versions of these images or to change the image's tag(s) (useful for testing), then follow the instructions in the [build images section](#build-images).  

## Requirements

- [helm >= v3](https://github.com/kubernetes/helm)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [Amazon EKS vended KUBECTL](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html)
- [EKSCTL](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html)
- (Optional) [Docker](https://docs.docker.com/get-docker/)
- (Optional) [Python 3.6+](https://www.python.org/downloads/)
  
## Assumptions

1. Install [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
   * Steps
     1. ```curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"```
     2. ```sudo installer -pkg AWSCLIV2.pkg -target /```
     3. Test the version: ```aws --version```
        * AWS Cli version should be 2.0.46 or later
2. Access Key has been setup 
   * Steps
     1. Login to aws console go to the IAM Service
        * Services->IAM->Users
     2. Select your username and click the security credentials tab
     3. Click the **Create access key** and download the excel file consisting of your **AWS Access Key ID** and **AWS Secret Access Key**   
3. A key pair has been created
4. Install and configure [EKSCTL](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html) based on your OS 
   * Verify it works: ```eksctl version```
   * The output should show eksctl version 0.27.0
5. Install and configure [Amazon EKS vended KUBECTL](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html) based on your OS 
   *  Verify the Kubectl version
      *  ```kubectl version --short --client```
      *  The output should show an kubectl version is 1.17
6. Install and configure [HELM 3](https://github.com/kubernetes/helm) based on your OS
   * Verify it works: ```helm version --client --short```
   * View existing charts: ```helm list```
7. Create EFS System
   1. Get the vpc using the following command
       * ```aws eks describe-cluster --name cluster_name --query "cluster.resourcesVpcConfig.vpcId" --output text```
   2. get the CIDR of VPC using this command
       * ```aws ec2 describe-vpcs --vpc-ids vpc-XXXXXXXXXs --query "Vpcs[].CidrBlock" --output text```
   3. In console or CLI create a file system EFS for your cluster vpc
   4. Under once created add mount targets for the public cluster subnets for each availablity zone
   5. For each mount target select the ```eks-cluster-sg-$clustername``` security group to allow nfs access. 
      * NOTE: SG will have the following description
        * ```eks-cluster-sg-{clusterName}-#########```
        * ```EKS created security group applied to ENI that is attached to EKS Control Plane master nodes, as well as any managed workloads.``` 

## Setup your EKS Cluster 

1. Use ```aws configure``` to configure aws CLI 
   * configure the following:
     * | Key                   | Description                      |
       | --------------------- | -------------------------------- |
       | AWS Access Key ID     | AWS key for account              |
       | AWS Secret Access Key | AWS Secret token to use aws cli  |
       | Default region name   | main region for aws resources    |
       | Default output format | output format of aws commands    |
       

2. Create IAM polices for your ALB Ingress Controller and External DNS. 
   *  Create **IAM policy** using aws cli for alb ingress policy
      * `aws iam create-policy \
       --policy-name ALBIngressControllerIAMPolicy \
       --policy-document file://IAM/alb-policy.json`
   * Create **IAM policy** using aws cli for external dns policy
       * `aws iam create-policy \
           --policy-name AllowExternalDNSUpdates \
           --policy-document file://IAM/dns-policy.json` 
3.  Open _**cluster/custer.yaml**_ and update the following:
    *   Attached ARN policies for the **alb-ingress-controller** and **external-dns**
        *   format: ```arn:aws:iam::XXXXXXXXX:policy/AllowExternalDNSUpdates```
    *   Public Key Path of public key used in your aws environment
        *   [AWS KEY Pair Guide ](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
        *   Steps:
            1.  Create a key pair and output it into the pem file 
                *  ```aws ec2 create-key-pair --key-name MyKeyPair --query 'KeyMaterial' --output text > MyKeyPair.pem```
            2.  Generate the public key(pub) from the private key(pem)
                * ```ssh-keygen -y -f MyKeyPair.pem > MyKeyPair.pub```
            3.  Update the permisson of your pub file to only give read acess to the owner of the file
                * ```chmod 400 MyKeyPair.pub```  
            4. Pass the path to the public key file into cluster.yaml as the value for the **publicKeyPath**
    *   Name and AWS Region of your eks cluster
4.  Create the eks cluster
    * ```eksctl create cluster -f cluster/cluster.yaml```
    * This command will create the following:
      * The EKS Cluster
      * EKS Cluster role which is used to create aws resources for the kubernetes clusters
      * Managed Node Groups that consists of EC2 Instances that are your worker nodes
      * VPC, Public and private subnets
      * Security groups for the control plane master nodes, load balancer, and communication between all nodes in the cluster
      * IAM Roles for Service Accounts that allow cluster operators to map aws IAM roles to Kubernetes Service Account
        * Current Service Accounts mapped:
          * **alb-ingress-controller**
          * **external-dns**
        * NOTE: Use command below to show Roles created by EKSCTL with OIDC
          * ```eksctl get iamserviceaccount --cluster cluster_name```

## Installation of Illumidesk Helm Chart 

1. Verify that helm exists: ```helm list```
2. Create a namespace for your helm chart
   * ```kubectl create namespace $NAMESPACE```
3. Create a values yaml file locally and pass the chart values that you would like to override
    * 
    * You must override the following:
    * | Key         | Description                                      | Command Line to get value  |
      | ----------- | ------------------------------------------------ | -------------------------- |
      |   awsAccessKey     | Access Key created for your account       | ```aws configure get aws_access_key_id``` |
      | awsSecretToken     | Secret token provided by aws              | ```aws configure get aws_secret_access_key``` |
      | secretToken     | Secret token for proxy generated by oppenssl           | ```openssl rand -hex 32```    |
      | clusterName     | name of EKS cluster created from eksctl            | ```eksctl get cluster ``` |
      | clusterVPC     | VPC ID of vpc generated by eksctl for your cluster         | ```aws eks describe-cluster --name cluster_name --query "cluster.resourcesVpcConfig.vpcId" --output text```
      | awsRegion     | aws region where your cluster is located              | ```aws configure region```
      | subnets     | subnets that are part of your cluster vpc. At least 2 required            | ```aws ec2 describe-subnets --filter "Name=vpc-id,Values=vpc-xxxxxxxxxxxx" "Name=tag:Name,Values=*Public*"  --query "Subnets[*].SubnetId"``` |
      | domainFilter     | your aws route 53 hosted zonezone              | `aws route53 list-hosted-zones --query "HostedZones[*].Name"`|
      | txtOwnerID     | identifies externalDNS instance            | set to a unique value that doesn't change during the lifetime of your cluster |
      | efs     | efs file system url           | ```Go to console->EFS, Find the file system whose mounted targets are in the same vpc as the cluster``` |
4. Using your values yaml file create the helm chart in your helm chart namespace 
    * ```helm upgrade --install $RELEASE ./illumidesk/ --namespace $NAMESPACE --values path/to/file/values.yaml```
5. Once complete, verify the url 
   * ```dig jhub.example.com```
6. Run ```df -HT```in your notebook container to view your mount targets 

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

6. Install IllumiDesk with ```helm``` as inatructed in the first section.





