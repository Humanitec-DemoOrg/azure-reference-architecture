# By CLI

Tools needed:
- `az`
- `yq`
- `jq`
- `helm`
- `gh`
- `curl`

```bash
export HUMANITEC_ORG=FIXME
export AZURE_SUBCRIPTION_ID=FIXME
export AZURE_SUBCRIPTION_TENANT_ID=FIXME
export GITHUB_ORG=FIXME
```

```bash
RESOURCE_GROUP=${HUMANITEC_ORG}
LOCATION=eastus

az account set \
    -s ${AZURE_SUBCRIPTION_ID}

az group create \
    -n ${RESOURCE_GROUP} \
    -l ${LOCATION}
```

## AKS in Azure

```bash
CLUSTER_NAME=ref-arch-aks
CLUSTER_NODE_COUNT=3
CLUSTER_NODE_SIZE=Standard_DS2_v2 # Bigger size like Standard_D8s_v3 could be used if you have ~20 participants
HUMANITEC_IP_ADDRESSES="34.159.97.57/32,35.198.74.96/32,34.141.77.162/32,34.89.188.214/32,34.159.140.35/32,34.89.165.141/32"

az aks create \
    -g ${RESOURCE_GROUP} \
    -n ${CLUSTER_NAME} \
    -l ${LOCATION} \
    --node-count ${CLUSTER_NODE_COUNT} \
    --node-vm-size ${CLUSTER_NODE_SIZE} \
    --api-server-authorized-ip-ranges ${HUMANITEC_IP_ADDRESSES} \
    --no-ssh-key
```

```bash
az aks get-credentials \
    -g ${RESOURCE_GROUP} \
    -n ${CLUSTER_NAME}
```

```bash
helm upgrade \
    --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
```

```bash
INGRESS_IP=$(kubectl get svc ingress-nginx-controller \
    -n ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[*].ip}")
echo ${INGRESS_IP}
```

```bash
AKS_ADMIN_SP_NAME=humanitec-to-${CLUSTER_NAME}

AKS_ADMIN_SP_CREDENTIALS=$(az ad sp create-for-rbac \
    -n ${AKS_ADMIN_SP_NAME})
AKS_ADMIN_SP_ID=$(echo ${AKS_ADMIN_SP_CREDENTIALS} | jq -r .appId)
AKS_ID=$(az aks show \
    -n ${CLUSTER_NAME} \
    -g ${RESOURCE_GROUP} \
    -o tsv \
    --query id)
az role assignment create \
    --role "Azure Kubernetes Service RBAC Cluster Admin" \
    --assignee ${AKS_ADMIN_SP_ID} \
    --scope ${AKS_ID}
```

```bash
ACR_NAME=containers$(shuf -i 1000-9999 -n 1)
ACR_ID=$(az acr create \
    -g ${RESOURCE_GROUP} \
    -n ${ACR_NAME} \
    -l ${LOCATION} \
    --sku basic \
    --query id \
    -o tsv)
```

```bash
az aks update \
    -n ${CLUSTER_NAME} \
    -g ${RESOURCE_GROUP}\
    --attach-acr ${ACR_ID}
```

## Terraform Driver resources

```bash
TERRAFORM_CONTRIBUTOR_SP_NAME=humanitec-terraform
TERRAFORM_CONTRIBUTOR_SP_CREDENTIALS=$(az ad sp create-for-rbac \
    -n ${TERRAFORM_CONTRIBUTOR_SP_NAME})
TERRAFORM_CONTRIBUTOR_SP_ID=$(echo ${TERRAFORM_CONTRIBUTOR_SP_CREDENTIALS} | jq -r .appId)
TERRAFORM_CONTRIBUTOR_SP_PASSWORD=$(echo ${TERRAFORM_CONTRIBUTOR_SP_CREDENTIALS} | jq -r .password)
az role assignment create \
    --role "Contributor" \
    --assignee ${TERRAFORM_CONTRIBUTOR_SP_ID} \
    --scope "/subscriptions/${AZURE_SUBSCRIPTION_ID}"
```