[![ci](https://github.com/Humanitec-DemoOrg/azure-reference-architecture/actions/workflows/ci.yaml/badge.svg)](https://github.com/Humanitec-DemoOrg/azure-reference-architecture/actions/workflows/ci.yaml)

# azure-reference-architecture

Snippets for the first draft of the Azure Reference Architecture.

ToC:
- [AKS in Azure](#aks-in-azure)
- [GitHub Actions](#github-actions)
- [AKS in Humanitec](#aks-in-humanitec)
- [In-cluster MySQL database](#in-cluster-mysql-database)
- [Terraform Driver resources](#terraform-driver-resources)
  - [Azure Blob Storage](#azure-blob-storage)
  - [Azure MySQL](#azure-mysql)

Tools needed:
- [`humctl`](https://developer.humanitec.com/platform-orchestrator/cli/)
- `az`
- `jq`
- `helm`
- `gh`
- `curl`

Roles needed:
- `Application Administrator`
- `Application Developer`

```bash
export HUMANITEC_ORG=FIXME
export AZURE_SUBSCRIPTION_ID=FIXME
export AZURE_SUBSCRIPTION_TENANT_ID=FIXME
export GITHUB_ORG=FIXME
```

```bash
RESOURCE_GROUP=${HUMANITEC_ORG}
LOCATION=eastus

az account set \
    -s ${AZURE_SUBSCRIPTION_ID}

az group create \
    -n ${RESOURCE_GROUP} \
    -l ${LOCATION}
```

```bash
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.ContainerRegistry
```

## AKS in Azure

```bash
CLUSTER_NAME=${RESOURCE_GROUP}-ref-arch-aks
CLUSTER_NODE_COUNT=3
CLUSTER_NODE_SIZE=Standard_DS2_v2 # Bigger size like Standard_D8s_v3 could be used if you have ~20 participants
HUMANITEC_IP_ADDRESSES="34.159.97.57/32,35.198.74.96/32,34.141.77.162/32,34.89.188.214/32,34.159.140.35/32,34.89.165.141/32"
LOCAL_IP_ADRESS=$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')

az aks create \
    -g ${RESOURCE_GROUP} \
    -n ${CLUSTER_NAME} \
    -l ${LOCATION} \
    --node-count ${CLUSTER_NODE_COUNT} \
    --node-vm-size ${CLUSTER_NODE_SIZE} \
    --api-server-authorized-ip-ranges ${HUMANITEC_IP_ADDRESSES},${LOCAL_IP_ADRESS}/32 \
    --no-ssh-key
```

```bash
az aks get-credentials \
    -g ${RESOURCE_GROUP} \
    -n ${CLUSTER_NAME}
```

```bash
az network public-ip create \
    -g ${RESOURCE_GROUP} \
    -n ${CLUSTER_NAME}-ingress-nginx \
    --sku Standard \
    --allocation-method Static
```

```bash
INGRESS_IP=$(az network public-ip show \
    -g ${RESOURCE_GROUP} \
    -n ${CLUSTER_NAME}-ingress-nginx \
    --query ipAddress \
    -o tsv)
```

```bash
AKS_CLIENT_ID=$(az aks show \
    -n ${CLUSTER_NAME} \
    -g ${RESOURCE_GROUP} \
    -o tsv \
    --query identity.principalId)
RG_SCOPE=$(az group show \
    --name ${RESOURCE_GROUP} \
    --query id \
    -o tsv)
az role assignment create \
    --assignee ${AKS_CLIENT_ID} \
    --role "Network Contributor" \
    --scope ${RG_SCOPE}
```

```bash
helm upgrade \
    --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-ipv4"=${INGRESS_IP} \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-resource-group"=${RESOURCE_GROUP} \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
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

## GitHub Actions

```bash
ACR_PUSH_SP_NAME=github-to-${ACR_NAME}
ACR_PUSH_SP_CREDENTIALS=$(az ad sp create-for-rbac \
    -n ${ACR_PUSH_SP_NAME})
ACR_PUSH_SP_ID=$(echo ${ACR_PUSH_SP_CREDENTIALS} | jq -r .appId)
az role assignment create \
    --role acrpush \
    --assignee ${ACR_PUSH_SP_ID} \
    --scope ${ACR_ID}
ACR_PUSH_SP_PASSWORD=$(echo ${ACR_PUSH_SP_CREDENTIALS} | jq -r .password)
```

```bash
gh secret set ACR_PUSH_SP_ID -b"${ACR_PUSH_SP_ID}" -o ${GITHUB_ORG}
gh secret set ACR_PUSH_SP_PASSWORD -b"${ACR_PUSH_SP_PASSWORD}" -o ${GITHUB_ORG}
gh secret set ACR_SERVER_NAME -b"${ACR_NAME}.azurecr.io" -o ${GITHUB_ORG}
```

Then the GitHub Actions needs to be updated to include this step to push the container images in ACR:
```yaml
echo "${{ secrets.ACR_PUSH_SP_PASSWORD }}" | docker login \
        ${{ secrets.ACR_SERVER_NAME }} \
        -u ${{ secrets.ACR_PUSH_SP_ID }} \
        --password-stdin
```

## AKS in Humanitec

```bash
HUMANITEC_TOKEN=FIXME
HUMANITEC_ENVIRONMENT=development

cat <<EOF > ${CLUSTER_NAME}.yaml
apiVersion: entity.humanitec.io/v1b1
kind: Definition
metadata:
  id: ${CLUSTER_NAME}
entity:
  name: ${CLUSTER_NAME}
  type: k8s-cluster
  driver_type: humanitec/k8s-cluster-aks
  driver_inputs:
    values:
      loadbalancer: ${INGRESS_IP}
      name: ${CLUSTER_NAME}
      resource_group: ${RESOURCE_GROUP}
      subscription_id: ${AZURE_SUBSCRIPTION_ID}
    secrets:
      credentials: ${AKS_ADMIN_SP_CREDENTIALS}
  criteria:
    - env_id: ${HUMANITEC_ENVIRONMENT}
EOF
humctl create \
    -f ${CLUSTER_NAME}.yaml
```

## In-cluster MySQL database

```bash
humctl create \
    -f resources/mysql-incluster-resource.yaml
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

### Azure Blob Storage

```bash
cat <<EOF > azure-blob-terraform.yaml
apiVersion: entity.humanitec.io/v1b1
kind: Definition
metadata:
  id: azure-blob-terraform
entity:
  name: azure-blob-terraform
  type: azure-blob
  driver_type: humanitec/terraform
  driver_inputs:
    values:
      append_logs_to_error: true
      source:
        path: resources/terraform/azure-blob/
        rev: refs/heads/main
        url: https://github.com/Humanitec-DemoOrg/azure-reference-architecture.git
      variables:
        storage_account_location: ${LOCATION}
        resource_group_name: ${RESOURCE_GROUP}
    secrets:
      variables:
        credentials:
          azure_subscription_id: ${AZURE_SUBSCRIPTION_ID}
          azure_subscription_tenant_id: ${AZURE_SUBSCRIPTION_TENANT_ID}
          service_principal_id: ${TERRAFORM_CONTRIBUTOR_SP_ID}
          service_principal_password: ${TERRAFORM_CONTRIBUTOR_SP_PASSWORD}
EOF
humctl create \
    -f azure-blob-terraform.yaml
```

### Azure MySQL

```bash
cat <<EOF > azure-blob-terraform.yaml
apiVersion: entity.humanitec.io/v1b1
kind: Definition
metadata:
  id: azure-mysql-terraform
entity:
  name: azure-mysql-terraform
  type: mysql
  driver_type: humanitec/terraform
  driver_inputs:
    values:
      append_logs_to_error: true
      source:
        path: resources/terraform/azure-mysql/
        rev: refs/heads/main
        url: https://github.com/Humanitec-DemoOrg/azure-reference-architecture.git
      variables:
        mysql_server_location: ${LOCATION}
        resource_group_name: ${RESOURCE_GROUP}
    secrets:
      variables:
        credentials:
          azure_subscription_id: ${AZURE_SUBSCRIPTION_ID}
          azure_subscription_tenant_id: ${AZURE_SUBSCRIPTION_TENANT_ID}
          service_principal_id: ${TERRAFORM_CONTRIBUTOR_SP_ID}
          service_principal_password: ${TERRAFORM_CONTRIBUTOR_SP_PASSWORD}
EOF
humctl create \
    -f azure-mysql-terraform.yaml
```
