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

## Steps to setup argo on a new cluster

```bash
helm install argo argo/argo-workflows -n argo --create-namespace
```

```bash
helm install argo-events argo/argo-events --set singleNamespace=false --set namespace=''  -n argo-events --create-namespace
```

```bash
helm install argo-events-nats nats/nats --set cluster.enabled=true -n argo-events
```

```bash
helm install argo-events-stan nats/stan --set stan.nats.url=nats://argo-events-nats.argo-events.svc.cluster.local:4222 --set stan.clusterID=argo-events-stan --set cluster.enabled=true -n argo-events
```

## Uninstall the Chart

```bash
    helm uninstall $RELEASE -n $NAMESPACE
```

## Configuration

> Note: Please follow instructions to install the [Cert Manager]('https://github.com/jetstack/cert-manager/releases/download/v1.0.2/cert-manager.yaml') if you are using the ALB or Nginx Ingress Controller

> Note: Please follow instructions to setup [external dns]('https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.1/examples/echo_server/#setup-external-dns-to-manage-dns-automatically'), if you plan to use this resource

> Note: Please follow reference guides in the values.yaml in order to properly configure the resource during a deployment

> NOTE: The following envars must be set:
  *  `Jupyterhub.hub.extraEnvar.POSTGRES_NBGRADER_PASSWORD` 
  *  `Jupyterhub.hub.extraEnvar.POSTGRES_JUPYTERHUB_PASSWORD` 
  *  `Jupyterhub.hub.extraEnvar.JUPYTERHUB_API_TOKEN` 
  *  `Jupyterhub.hub.extraEnvar.JUPYTERHUB_CRYPT_KEY`

> NOTE: The following envars must be set depending on autentication type
  * `Jupyterhub.hub.extraEnvar.LTI_SHARED_SECRET`
  * `Jupyterhub.hub.extraEnvar.OIDC_CLIENT_SECRET`


| Parameter                                                                  | Description                                                                           | Default                                                                             |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| allowLocal.enabled                                                         | Enable local file system (confirm your instance has /illumidesk-nb-exchange-directory | FALSE                                                                               |
| and /illumidesk-courses directory)                                         | FALSE                                                                                 | arn:aws:iam::XXXXXXXXXX:role/eks-irsa-external-dns                                  |
| allowNFS.enabled                                                           | Enables creation of NFS pv and pvc                                                    | FALSE                                 |
| allowNFS.path                                                              | Configure NFS base path                                                               | /                                                                                   |
| allowNFS.server                                                              | provide fs-XXXXXX for aws efs                                                       | fs-XXXXXX                                                                                   |
| allowLocal.enabled                                                         | local for local testing or efs for aws                                                | local                                                                               |
| postgresql.enabled                                                         | Enables creation of postgresql manifests                                              | FALSE                                                                               |
| postgresql.postgresqlUsername                                              | Username for postgres                                                                 | postgres                                                                            |
| postgresql.postgresqlPostgresPassword                                      | Postgresql admin password                                                             |                                                                                     |
| postgresql.postgresqlPassword                                              | Postgresql password                                                                   |                                                                                     |
| postgresql.postgresqlDatabase                                              | Postgresql Database                                                                   | illumidesk                                                                          |
| postgresql.existingSecret                                                  | Existing Kubernetes Secret that exists in the namespace                               | illumidesk-secret                                                                   |       |
| postgresql.service.port                                                    | Database port                                                                         |  5432                                                                               |
| externalDatabase.enabled                                                   | Enables External Database                                                             | FALSE                                                                               |
| externalDatabase.existingSecret                                            | Existing Kubernetes Secret that exists in the namespace                               | illumidesk-secret                                                                   |
| externalDatabase.host                                                      | Host name of the external database server                                             |                                                                                     |
| externalDatabase.database                                                  | Database name                                                                         | illumidesk                                                                          |
| externalDatabase.port                                                      | Database port                                                                         | 5432                                                                                |
| externalDatabase.databaseUser                                              | Database user                                                                         | postgres                                                                            |
| externalDatabase.databasePassword                                          | Database password                                                                     | postgres123                                                                         |
| graderSetupService.enabled                                                 | Enables Grader Setup Service                                                          | FALSE                                                                               |
| graderSetupService.graderSpawnerImage                                      | Grader Image Name                                                                     | illumidesk/illumidesk-grader:latest                                                 |
| graderSetupService.graderSpawnerCPU                                        | CPU Allocated for each grader                                                         | 200m                                                                                |
| graderSetupService.graderSpawnerMem                                        | Memory Allocated for each grader                                                      | 400Mi                                                                                |
| graderSetupService.graderSpawnerStorage                                    | Storage Allocated for each grader                                                     | 500Mi                                                                                 |
| graderSetupService.graderSpawnerCpuGuarantee                               | CPU allocated for each grader                                                         | 200m                                                                                |
| graderSetupService.graderSpawnerCpuLimit                                   | Max CPU allocation for each grader                                                         | 400m                                                                                |
| graderSetupService.graderSpawnerMemGuarantee                               | Memory allocated for each grader                                                      | 400Mi                                                                                |
| graderSetupService.graderSpawnerMemLimit                                   | Max memory allocated for each grader                                                      | 800Mi                                                                                |
| graderSetupService.graderSetupImage                                        | Grader Setup Service Image Name                                                       | illumidesk/grader-setup-app:latest                                                  |
| graderSetupService.postgresNBGraderPassword                                | Provide Postgres Password                                                             | None                                                                                |
| graderSetupService.graderCpuGuarantee                                     | Provide CPU allocation for Grader Setup Service                                       | 200m                                                                                   |
| graderSetupService.graderCpuLimit                                          | Provide Max CPU allocation for Grader Setup Service                                   |  400m                                                                                 |
| graderSetupService.graderMemGuarantee                                       | Provide Memory allocation for Grader Setup Service                                    | 400Mi                                                                               |
| graderSetupService.graderMemLimit                                          | Provide Max Memory allocation allowed for Grader Setup Service                        |  800Mi                                                                                   |
| graderSetupService.StorageCapacity                                         | Provide storage capacity the Grader Setup Service can use                             | 200Mi                                                                                |
| graderSetupService.StorageRequests                                         | Provide initial storage allocated for the Grader Setup Service                        | 1Gi                                                                                |
| graderSetupService.pullPolicy                                              | Image pull policy for grader setup service                                            | IfNotPresent                                                                                |
| graderSetupService.graderSpawnerPullPolicy                                 | Image pull policy for grader notebook                                            | IfNotPresent                                                                                |


## Cluster Helm Chart
### EFS CSI Driver

  1. Navigate to the `policy folder' and create a policy for EFS
  2. Create a policy for EFS CSI driver using the policy document
  ```bash
        aws iam create-policy \
      --policy-name AmazonEKS_EFS_CSI_Driver_Policy \
      --policy-document file://policy/iam-policy-efs-csi-driver.json
   ```
  3. Get the region-code and oidc-id to pass into trust policy
  ```bash
      aws eks describe-cluster --name {cluster} --query "cluster.identity.oidc.issuer" --output text
  ```
  4. Use the example `policy/trust-efs-csi-driver-policy-example.json` to create the trust policy for efs csi driver
  ```bash
      aws iam create-role \
    --role-name AmazonEKS_EFS_CSI_DriverRole \
    --assume-role-policy-document file://"policy/trust-efs-csi-driver-policy-example.json"
   ```
5. Attach efs csi driver IAM policy to the role created in the previous step

  ```bash
  aws iam attach-role-policy \
    --policy-arn arn:aws:iam::{account_id}:policy/AmazonEKS_EFS_CSI_Driver_Policy \
    --role-name AmazonEKS_EFS_CSI_DriverRole
  ```

6. Deploy Cluster level resources 
  
  ```bash
    helm upgrade --install {release} illumidesk/cluster --namespace kube-system -f {cluster-stage-custom-config}.yaml --debug --dry-run
  ```

### AWS Resources(SecretsManager) IAM Steps

1. Navigate to the `policy folder' and create a policy for Secrets Manager
2. Create a policy for secretsmananger using the policy document,`iam-policy-secrets-manager.json`
  ```
  aws iam create-policy --policy-name AmazonEKS_SecretsManager_CSI_Driver_Policy --policy-document file://policy/iam-policy-secrets-manager.json
  ```
3. Get the region-code and oidc-id to pass into trust policy
  ```bash
      aws eks describe-cluster --name {cluster} --query "cluster.identity.oidc.issuer" --output text
  ```
4. Create aws resources role with appropriate trust policy

aws iam create-role \
  --role-name AmazonEKS_Resources_Role \
  --assume-role-policy-document file://"policy/trust-aws-resources-policy-example.json"

5. Attach efs csi driver IAM policy to the role created in the previous step

  ```bash
  aws iam attach-role-policy \
    --policy-arn arn:aws:iam::{account_id}:policy/AmazonEKS_SecretsManager_CSI_Driver_Policy \
    --role-name AmazonEKS_Resources_Role
  ```

6. Pass Role ARN to grader-setup-service service account and hub service account with the following annotation

```
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::860100747351:role/AmazonEKS_Resources_Role
```
## Configuration

  | Parameter             | Description                     | Default       |
  | --------------------- | ------------------------------- | ------------- |
  | efsCSIDriver.enabled  | Enables EFS CSI Driver          |  false        |
  | efsCSIDriver.passARN   | enable pass csi arn to service account manifest          |  false        |
  | efsCSIDriver.roleARN   | pass csi arn to service account manifest          |  ""        |


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
