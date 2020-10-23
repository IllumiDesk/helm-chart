# IllumiDesk Infrastructure setup


# Overview

Use this [helm chart](https://helm.sh/docs/topics/charts/) to install IllumiDesk into your Cluster. This chart depends on the [jupyterhub](https://zero-to-jupyterhub.readthedocs.io/en/latest/).

This setup pulls images defined in the `illumidesk/values.yaml` file from `DockerHub`. To push new versions of these images or to change the image's tag(s) (useful for testing), then follow the instructions in the [build images section](#build-images).  


## Create a namespace

Create a namespace for your chart to install on:
  * kubernetes namespace defaults to the ```default ``` namespace

        $ kubectl create namespace $NAMESPACE

# AWS Setup

## OIDC Provider

AWS EKS uses the OpenID Connect protocol in order to create ISRA's.

  * If you have a cluster managed by EKSCTL, associate the IAM-OIDC-PROVIDER to your cluster
    
        eksctl utils associate-iam-oidc-provider --region=us-east-2 --cluster={YOUR_CLUSTER}  --approve

## ALB Ingress Infrastructure Setup
For ALB Ingress you will need to create an IRSA the ALB Ingress Controller

#### THE EKSCTL WAY
  *  Create **IAM policy** using aws cli for alb ingress policy
        ```Bash    
            `aws iam create-policy \
            --policy-name ALBIngressControllerIAMPolicy \
            --policy-document file://IAM/alb-policy.json` 
        ```

  * create an IAM service account and attach it to your cluster
        
        eksctl create iamserviceaccount --cluster={YOUR_CLUSTER} --name=alb-ingress-controller --namespace={YOUR_NAMESPACE} --attach-policy-arn=arn:aws:iam::XXXXXXXXXXXX:policy/ALBIngressControllerIAMPolicy

### The HARD WAY
  * Add the following Environment variables to your terminal or bash_profile
        
        AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
        OIDC_PROVIDER=$(aws eks describe-cluster --name <cluster-name> --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
  * Create a trust relationship file and pass in your environment variables
    
        read -r -d '' TRUST_RELATIONSHIP <<EOF
        {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                "${OIDC_PROVIDER}:sub": "system:serviceaccount:<namespace>:alb-ingress-controller"
                }
            }
            }
        ]
        }
        EOF
        echo "${TRUST_RELATIONSHIP}" > trust_for_alb.json

  * Create an IAM role with your trust relationship for your alb-ingress-controller service account
        
        aws iam create-role --role-name alb-ingress-role --assume-role-policy-document file://trust_for_alb.json --description "ISRA for ALB Ingress Controller"
  * Attach IAM policy to the IAM Role for your alb-ingress-controller
        
        aws iam attach-role-policy --role-name alb-ingress-role --policy-arn=arn:aws:iam::860100747351:policy/ALBIngressControllerIAMPolicy
  
  * Pass your role arn as an annotation for the alb-ingress-controller service account
        
        albIngressController
            serviceAccount:
                annotations:
                eks.amazonaws.com/role-arn: arn:aws:iam::XXXXXXXXX:role/alb-ingress-role


## External DNS Setup

### THE EKSCTL WAY

For the external dns deployment you need to create an IRSA the External DNS
  *  Create **IAM policy** using aws cli for alb ingress policy
        ```Bash    
            `aws iam create-policy \
            --policy-name AllowExternalDNSUpdates \
            --policy-document file://IAM/dns-policy.json` 
        ```
  * create an IAM service account and attach it to your cluster
        
        eksctl create iamserviceaccount --cluster={YOUR_CLUSTER} --name=external-dns --namespace={YOUR_NAMESPACE} --attach-policy-arn=arn:aws:iam::XXXXXXXXXXXX:policy/AllowExternalDNSUpdates

### The HARD WAY
  * Add the following Environment variables to your terminal or bash_profile
        
        AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
        OIDC_PROVIDER=$(aws eks describe-cluster --name <cluster-name> --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
  * Create a trust relationship file and pass in your environment variables and namespace
    
        read -r -d '' TRUST_RELATIONSHIP <<EOF
        {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                "${OIDC_PROVIDER}:sub": "system:serviceaccount:<namespace>:external-dns"
                }
            }
            }
        ]
        }
        EOF
        echo "${TRUST_RELATIONSHIP}" > trust_for_dns.json

  * Create an IAM role with your trust relationship for your external-dns service account
        
        aws iam create-role --role-name alb-ingress-role --assume-role-policy-document file://trust_for_dns.json --description "ISRA for External DNS"
  
  * Attach IAM policy to the IAM Role for your external-dns
        
        aws iam attach-role-policy --role-name external-dns-role --policy-arn=arn:aws:iam::XXXXXXXXXXXX:policy/AllowExternalDNSUpdates

 * Pass your role arn as an annotation for the external-dns service account

        serviceAccount:
            annotations:
                eks.amazonaws.com/role-arn: arn:aws:iam::860100747351:role/external-dns-role

## Validate the Helm Chart

* For nodeport you will need to use your one of your node ips and also the port you defined in your values file. 
  * Open up your browser and use the **NODE_IP:NODE_PORT**
  * Use the following command to list out your nodes:
        
        $ kubectl get nodes -o wide 
          

* For load balancer you will need to get the external IP for proxy-public 
  * Use this command to view your services and then paste the loadbalancer dns that is is the external ip of proxy-public

            $ kubectl get svc -n $NAMESPACE

* For Application Load Balancer, you must have specified the host in your values file
    *  Verify the dns has propgates your domain
           
            $ dig $HOST 
    * Open up your browser and paste the value for your host






