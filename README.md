# IllumiDesk Helm Chart

## Overview

Use this [helm chart](https://helm.sh/docs/topics/charts/) to install IllumiDesk into your Cluster. This chart depends on the [jupyterhub](https://zero-to-jupyterhub.readthedocs.io/en/latest/).

This setup pulls images defined in the `illumidesk/values.yaml` file from `DockerHub`. To push new versions of these images or to change the image's tag(s) (useful for testing), then follow the instructions in the [build images section](#build-images).  

## TL;DR

```bash
  helm repo add illumidesk https://illumidesk.github.io/helm-chart/
  helm repo update
  helm upgrade --install $RELEASE illumidesk --namespace $NAMESPACE --values example-config/values.yaml
```

![Load Balancer Example](https://illumidesk-storage.s3-us-west-2.amazonaws.com/TLDR.gif)

## Prerequsites

- [helm >= v3](https://github.com/kubernetes/helm)
- [Kubectl >= 1.17](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## Installing the chart

Create a copy of _**example-config/values.yaml.example**_ file and update it with your setup. 

> NOTE: to get a token use  `openssl rand -hex 32`:

Here is an example of a basic load balancer setup setup:

```yaml
  jupyterhub:
    proxy:
    secretToken: your_token
    service:
    type: LoadBalancer
  albIngressController:
  enabled: false
  allowExternalDNS: 
  enabled: false
  allowNFS: 
  enabled: false
```

- Here is another example of a basic setup using nodeport

```yaml
  jupyterhub:
    proxy:
      secretToken: your_token
      service:
      type: NodePort
      nodePorts:
        http: 30791
        https: 30792
  albIngressController:
    enabled: false
  allowExternalDNS:
    enabled: false
  allowNFS:
    enabled: false
```

- Add Illumidesk repository to HELM:

```bash
    helm repo add illumidesk https://illumidesk.github.io/helm-chart/
    helm repo update
```

- Install a release of the illumidesk helm chart:

```bash
  RELEASE=illumidesk
  NAMESPACE=illumidesk
  helm upgrade \
    --install $RELEASE \
    illumidesk \
    --namespace $NAMESPACE \
    --values my-custom-config.yaml
```

## Uninstall the Chart

```bash
    helm uninstall $RELEASE -n $NAMESPACE
```

## Configuration

The following tables lists the configurable parameters of the chart and their default values.

| Parameter                                                                  | Description                                                                                                                              | Default                                                                             |
| -------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| rbac.enabled                                                               | gives applications only as much access they need to the kubernetes API                                                                   | TRUE                                                                                |
| jupyterhub.proxy.secretToken                                               | 32-byte cryptographically secure randomly generated string used to secure communications between the hub and the configurable-http-proxy | Generate a random 32 bit hexadecimal value                                          |
| jupyterhub.proxy.service.type                                              | Kubernetes service to use to access jupyterhub                                                                                           | LoadBalancer                                                                        |
| albIngressController.enabled                                               | allows creation of aws application load balancer                                                                                         | FALSE                                                                               |
| albIngressController.enableIRSA                                            | allow passing of IAM role arn if you are not using eksctl                                                                                | FALSE                                                                               |
| albIngressController.awsAccessKey                                          | AWS Access Key used to authenticate with aws API                                                                                         | XXXXXXXXXXXXXXXXXXXX (AWS Access Key)                                               |
| albIngressController.awsSecretToken                                        | AWS Secret Token used to authenticate with aws API                                                                                       | XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX (AWS Secret Token)                         |
| albIngressController.clusterName                                           | EKS Cluster where aws resources should be created                                                                                        | illumidesk                                                                          |
| albIngressController.clusterVPC                                            | Cluster VPC ID alb ingress controller uses to create aws resources                                                                       | vpc-XXX                                                                             |
| albIngressController.awsRegion                                             | aws region where your cluster is located                                                                                                 | us-east-1                                                                           |
| albIngressController.host                                                  | Host name configured by ingress resource that uses alb                                                                                   | XXXXX.illumidesk.com                                                                |
| albIngressController.serviceAccount.annotations.eks.amazonaws.com/role-arn | assuming 'enableIRSA:true' pass the role arn for the alb ingress controller                                                              | arn:aws:iam::XXXXXXXXXX:role/eks-irsa-alb-ingress-controller                        |
| albIngress.host                                                            | Host name configured by ingress resource that uses alb                                                                                   | XXXXX.illumidesk.com                                                                |
| albIngress.ingress.annotations.kubernetes.io/ingress.class                 | determines which controller the ingress manifest uses                                                                                    | ALB                                                                                 |
| albIngress.ingress.annotations.alb.ingress.kubernetes.io/target-type       | determines how to create target groups                                                                                                   | IP                                                                                  |
| albIngress.ingress.annotations.alb.ingress.kubernetes.io/scheme            | determines whether the load balancer is internal or internet facing                                                                      | internet-facing                                                                     |
| albIngress.ingress.annotations.alb.ingress.kubernetes.io/subnets           | subnets that are part of your cluster vpc. At least 2 required                                                                           | [] (subnets for cluster vpc)                                                        |
| albIngress.ingress.annotations.alb.ingress.kubernetes.io/tags              | ingress tags to tag ALB/Target Groups/Security group                                                                                     | {}                                                                                  |
| albIngress.ingress.annotations.alb.ingress.kubernetes.io/certificate-arn   | certificate managaged by aws                                                                                                             | arn:aws:acm:us-east-1:XXXXXXXXXXXX:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX |
| albIngress.ingress.annotations.alb.ingress.kubernetes.io/group.name        | ingress group name to associate ingress files to alb-ingress-controller                                                                  |                                                                                     |
| allowExternalDNS.enabled                                                   | makes Kubernetes resources discoverable via public DNS Servers                                                                           | FALSE                                                                               |
| allowExternalDNS.enableIRSA                                                | allow passing of IAM role arn if you are not using eksctl                                                                                | FALSE                                                                               |
| allowExternalDNS.domainFilter                                              | AWS route 53 hosted zonezone                                                                                                             | illumidesk.com                                                                      |
| allowExternalDNS.txtOwnerID                                                | Identifies externalDNS instance                                                                                                          | illumidesk                                                                          |
| allowExternalDNS.serviceAccount.annotations.eks.amazonaws.com/role-arn     | Assuming 'enableIRSA:true' pass the role arn for the external dns                                                                        | FALSE                                                                               |
| allowNFS.enabled                                                           | Enables creation of NFS pv and pvc                                                                                                       | arn:aws:iam::XXXXXXXXXX:role/eks-irsa-external-dns                                  |
| allowNFS.server                                                            | NFS Server URL or IP                                                                                                                     | fs-XXXXXXXX.efs.us-east-1.amazonaws.com (Network File System DNS or IP)             |
| allowNFS.path                                                              | Configure NFS base path                                                                                                                  | /                                                                                   |
| nginxIngressController.enabled                                             | Allows creation of nginx ingress controller                                                                                              | FALSE                                                                               |
| nginxIngressController.certificateArn                                      | Certificate arn managaged by aws                                                                                                         | arn:aws:acm:us-east-1:XXXXXXXXXXXX:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX |
| nginxIngressController.vpcCIDR                                             | CIDR of your cluster vpc                                                                                                                 | XXX.XXX.XXX/XX                                                                      |
| nginxIngress.enabled                                                       | Enable creating of nginx ingress resource                                                                                                | FALSE                                                                               |
| nginxIngress.host                                                          | Host name configured by ingress resource that uses nginx                                                                                 | xxxxx.illumidesk.com                                                                |
| postgresql.enabled                                                         | Enables creation of postgresql manifests                                                                                                 | FALSE                                                                               |
| postgresql.postgresqlUsername                                              | Username for postgres                                                                                                                    | postgres                                                                            |
| postgresql.postgresqlPostgresPassword                                      | Postgresql admin password                                                                                                                |                                                                                     |
| postgresql.postgresqlPassword                                              | Postgresql password                                                                                                                      |                                                                                     |
| postgresql.postgresqlDatabase                                              | Postgresql Database                                                                                                                      | illumidesk                                                                          |
| datadog.enabled                                                            | Enables datadog                                                                                                                          | FALSE                                                                               |
| datadog.datadog.apiKey                                                     | API Key                                                                                                                                 |                                                                                     |
| datadog.datadog.clusterName                                                | Name of EKS cluster                                                                                                                      |                                                                                     |
| datadog.datadog.clusterAgent.enable                                        | Enable Cluster Agent                                                                                                                     | FALSE                                                                              |
| datadog.datadog.clusterAgent.token                                         | API token for Cluster Agent                                                                                                              |                                                                                     |
| datadog.datadog.clusterAgent.metricsProvider                               | Enable Metrics provider for cluster agent                                                                                                | FALSE                                                                               |
| graderSetupService.enabled                                                 | Enables Grader Setup Service                                                                                                             | FALSE                                                                               |
| graderSetupService.graderImage                                             | Grader Image Name                                                                                                                        | illumidesk/illumidesk-grader:latest                                                 |
| graderSetupService.graderSetupImage                                        | Grader Setup Service Image Name                                                                                                          | illumidesk/grader-setup-app:latest                                                  |
| graderSetupService.postgresNBGraderHost                                    | Provide Host Postgres Server                                                                                                             | illumidesk.XXXXXXXXXXXX.us-east-1.rds.amazonaws.com                                 |
| graderSetupService.postgresNBGraderUser                                    | Provide Postgres User                                                                                                                    | postgres                                                                            |
| graderSetupService.postgresNBGraderPassword                                | Provide Postgres Password                                                                                                                | None                                                                                |

## Validate the Helm Chart

- For nodeport you will need to use your one of your node ips and also the port you defined in your values file. 
  - Open up your browser and use the **NODE_IP:NODE_PORT**
  - Use the following command to list out your nodes:

```bash
   kubectl get nodes -o wide
```

- For load balancer you will need to get the external IP for proxy-public 
  - Use this command to view your services and then paste the loadbalancer dns that is is the external ip of proxy-public

```bash
  kubectl get svc -n $NAMESPACE
```

- For Application Load Balancer, you must have specified the host in your values file
  - Verify the dns has propgates your domain

```bash
    dig $HOST 
```

- Open up your browser and paste the value for your host

## Cleanup

```bash
  helm delete <release name> --purge
```
