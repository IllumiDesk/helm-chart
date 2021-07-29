# IllumiDesk Helm Chart

## Overview

Use this [helm chart](https://helm.sh/docs/topics/charts/) to install IllumiDesk into your Cluster. This chart depends on the [jupyterhub](https://zero-to-jupyterhub.readthedocs.io/en/latest/).

This setup pulls images defined in the `illumidesk/values.yaml` file from `DockerHub`. To push new versions of these images or to change the image's tag(s) (useful for testing), then follow the instructions in the [build images section](#build-images).  

## TL;DR

```bash
  helm repo add illumidesk https://illumidesk.github.io/helm-chart/
  helm repo update
  helm upgrade --install $RELEASE illumidesk/illumidesk --version $SEMVER --namespace $NAMESPACE --values example-config/values.yaml --debug
```

## Prerequsites

- [helm >= v3](https://github.com/kubernetes/helm)
- [Kubectl >= 1.17](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## Testing Locally

  1. Install Kind
  2. Create a directory called `illumidesk-nb-exchange`
  3. Inside that directory create a sub directory called `illumidesk-courses`
  4. Create a cluster with the following YAML config
```yml
      kind: Cluster
      apiVersion: kind.x-k8s.io/v1alpha4
      nodes:
      - role: control-plane
        extraMounts:
        - hostPath: ./illumidesk-nb-exchange
          containerPath: "/illumidesk-nb-exchange"
        - hostPath: ./illumidesk-nb-exchange/illumidesk-courses
          containerPath: "/illumidesk-courses"
  ```
  5. Run the following command to create the cluster
     *  `kind create cluster --name {cluster name} --config test-cluster.yaml ` 
  6. Load images as needed into local Kind cluster
     *  `kind load docker-image illumidesk/grader-notebook:712 --name {cluster name}`
  7. Create namespace in kubernetes
     * `kubectl create namespace {}` 
  8. If testing locally, fetch pull request and cd into root directory, **helm-chart**
  9. To Deploy: 
     * `helm upgrade --install {name} charts/illumidesk/ -n {namespace} -f bar-us-west-2-config_go_grader.yaml --debug --dry-run`  
     * NOTE: `name` and `namespace` should match  
     * NOTE: remove `--dry-run` flag to run deploy illumidesk stack
  10. Port forward with 
     * `kubectl port-forward svc/proxy-public  -n {namespace} 8000:80`

  **Troubleshooting**

    * Get logs
      * `kubectl logs {pod} -n {namespace}`
    * Exec into pod
      * `kubectl exec -it {pod} -n {namespace} -- /bin/bash`
    * If helm chart is hanging, it is likely beacuse you need to load the docker image locally
      * `kubectl get pods -n {namespace}`
        * NOTE: if the `hook-image-puller` is in `init` status, log the pod and see if there are images that the cluster cannot pull

## Installing the chart

Create _**config.yaml**_ file and update it with your setup.

> NOTE: to get a token use  `openssl rand -hex 32`:

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
    illumidesk/illumidesk \
    --version 3.2.0
    --namespace $NAMESPACE \
    --values my-custom-config.yaml
```

- Install a release wtihout  _**config.yaml**_ file

```bash
kubernetes create namespace test
helm upgrade --install test --set proxy.secretToken=XXXXXXXXXX illumidesk/illumidesk --version 3.2.0 -n test
```

## Uninstall the Chart

```bash
    helm uninstall $RELEASE -n $NAMESPACE
```

## Configuration

> Note: Please follow instructions to install the [Cert Manager]('https://github.com/jetstack/cert-manager/releases/download/v1.0.2/cert-manager.yaml') if you are using the ALB or Nginx Ingress Controller

> Note: Please follow instructions to setup [external dns]('https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.1/examples/echo_server/#setup-external-dns-to-manage-dns-automatically'), if you plan to use this resource

> Note: Please follow reference guides in the values.yaml in order to properly configure the resource during a deployment

The following tables lists the configurable parameters of the chart and their default values.

| Parameter                                                                  | Description                                                                           | Default                                                                             |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| albIngress.host                                                            | Host name configured by ingress resource that uses alb                                | XXXXX.illumidesk.com                                                                |
| albIngress.ingress.annotations.alb.ingress.kubernetes.io/certificate-arn   | certificate managaged by aws                                                          | arn:aws:acm:us-east-1:XXXXXXXXXXXX:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX |
| albIngress.ingress.annotations.alb.ingress.kubernetes.io/group.name        | ingress group name to associate ingress files to alb-ingress-controller               |                                                                                     |
| albIngress.ingress.annotations.alb.ingress.kubernetes.io/scheme            | determines whether the load balancer is internal or internet facing                   | internet-facing                                                                     |
| albIngress.ingress.annotations.alb.ingress.kubernetes.io/subnets           | subnets that are part of your cluster vpc. At least 2 required                        | [] (subnets for cluster vpc)                                                        |
| albIngress.ingress.annotations.alb.ingress.kubernetes.io/tags              | ingress tags to tag ALB/Target Groups/Security group                                  | {}                                                                                  |
| albIngress.ingress.annotations.alb.ingress.kubernetes.io/target-type       | determines how to create target groups                                                | IP                                                                                  |
| albIngress.ingress.annotations.kubernetes.io/ingress.class                 | determines which controller the ingress manifest uses                                 | ALB                                                                                 |
| albIngressController.awsRegion                                             | aws region where your cluster is located                                              | us-east-1                                                                           |
| albIngressController.clusterName                                           | EKS Cluster where aws resources should be created                                     | illumidesk                                                                          |
| albIngressController.clusterVPC                                            | Cluster VPC ID alb ingress controller uses to create aws resources                    | vpc-XXX                                                                             |
| albIngressController.enabled                                               | allows creation of aws application load balancer                                      | FALSE                                                                               |
| albIngressController.enableIRSA                                            | allow passing of IAM role arn if you are not using eksctl                             | FALSE                                                                               |
| albIngressController.host                                                  | Host name configured by ingress resource that uses alb                                | XXXXX.illumidesk.com                                                                |
| albIngressController.kube2iam                                              | pass kube2iam arn to securely pass AWS credentials into alb ingress controller pod    | arn:aws:iam::XXXXXXXXXX:role:instance-profile/k8s-alb-controller                    |
| albIngressController.serviceAccount.annotations.eks.amazonaws.com/role-arn | assuming 'enableIRSA:true' pass the role arn for the alb ingress controller           | arn:aws:iam::XXXXXXXXXX:role/eks-irsa-alb-ingress-controller                        |
| allowExternalDNS.domainFilter                                              | AWS route 53 hosted zonezone                                                          | illumidesk.com                                                                      |
| allowExternalDNS.enabled                                                   | makes Kubernetes resources discoverable via public DNS Servers                        | FALSE                                                                               |
| allowExternalDNS.enableIRSA                                                | allow passing of IAM role arn if you are not using eksctl                             | FALSE                                                                               |
| allowExternalDNS.serviceAccount.annotations.eks.amazonaws.com/role-arn     | Assuming 'enableIRSA:true' pass the role arn for the external dns                     | FALSE                                                                               |
| allowExternalDNS.txtOwnerID                                                | Identifies externalDNS instance                                                       | illumidesk                                                                          |
| allowLocal.enabled                                                         | Enable local file system (confirm your instance has /illumidesk-nb-exchange-directory | FALSE                                                                               |
| and /illumidesk-courses directory)                                         | FALSE                                                                                 | arn:aws:iam::XXXXXXXXXX:role/eks-irsa-external-dns                                  |
| allowNFS.enabled                                                           | Enables creation of NFS pv and pvc                                                    | arn:aws:iam::XXXXXXXXXX:role/eks-irsa-external-dns                                  |
| allowNFS.path                                                              | Configure NFS base path                                                               | /                                                                                   |
| allowLocal.enabled                                                         | local for local testing or efs for aws                                                | local                                                                               |
| postgresql.enabled                                                         | Enables creation of postgresql manifests                                              | FALSE                                                                               |
| postgresql.postgresqlUsername                                              | Username for postgres                                                                 | postgres                                                                            |
| postgresql.postgresqlPostgresPassword                                      | Postgresql admin password                                                             |                                                                                     |
| postgresql.postgresqlPassword                                              | Postgresql password                                                                   |                                                                                     |
| postgresql.postgresqlDatabase                                              | Postgresql Database                                                                   | illumidesk                                                                          |
| datadog.enabled                                                            | Enables datadog                                                                       | FALSE                                                                               |
| datadog.apiKey                                                             | API key created for datadog agent to send data back and forth to datadog instance     |                                                                                     |
| datadog.clusterAgentToken                                                  | Randomly generated cluster agent token                                                |                                                                                |
| graderSetupService.enabled                                                 | Enables Grader Setup Service                                                          | FALSE                                                                               |
| graderSetupService.graderSpawnerImage                                      | Grader Image Name                                                                     | illumidesk/illumidesk-grader:latest                                                 |
| graderSetupService.graderSpawnerCPU                                        | CPU Allocated for each grader                                                         | 200m                                                                                |
| graderSetupService.graderSpawnerMem                                        | Memory Allocated for each grader                                                      | 400Mi                                                                                |
| graderSetupService.graderSpawnerStorage                                    | Storage Allocated for each grader                                                     | 500Mi                                                                                 |
| graderSetupService.graderSpawnerCpuGuarantee                               | CPU allocated for each grader                                                         | 200m                                                                                |
| graderSetupService.graderSpawnerCpuLimit                                   | Max CPU allocation for each grader                                                         | 400m                                                                                |
| graderSetupService.graderSpawnerMemGuarantee                               | Memory allocated for each grader                                                      | 400Mi                                                                                |
| graderSetupService.graderSpawnerMemLimit                                   | Max memory allocated for each grader                                                      | 800Mi                                                                                |
| graderSetupService.graderSpawnerStorage                                    | Max storage allocation for each grader                                                     | 500Mi                                                                                 |
| graderSetupService.graderSetupImage                                        | Grader Setup Service Image Name                                                       | illumidesk/grader-setup-app:latest                                                  |
| graderSetupService.postgresNBGraderPassword                                | Provide Postgres Password                                                             | None                                                                                |
| graderSetupService.graderCpuGuarantee                                       | Provide CPU allocation for Grader Setup Service                                       | 200m                                                                                   |
| graderSetupService.graderCpuLimit                                          | Provide Max CPU allocation for Grader Setup Service                                   |  400m                                                                                 |
| graderSetupService.graderMemGuarantee                                       | Provide Memory allocation for Grader Setup Service                                    | 400Mi                                                                               |
| graderSetupService.graderMemLimit                                          | Provide Max Memory allocation allowed for Grader Setup Service                        |  800Mi                                                                                   |
| graderSetupService.StorageCapacity                                         | Provide storage capacity the Grader Setup Service can use                             | 200Mi                                                                                |
| graderSetupService.StorageRequests                                         | Provide initial storage allocated for the Grader Setup Service                        | 1Gi                                                                                |

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
