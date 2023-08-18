# By CLI

Tools needed:
- `yq`
- `jq`
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
```

## AKS in Humanitec

```bash
HUMANITEC_TOKEN=FIXME
HUMANITEC_ENVIRONMENT=development

cat <<EOF > ${CLUSTER_NAME}.yaml
id: ${CLUSTER_NAME}
name: ${CLUSTER_NAME}
type: k8s-cluster
driver_type: humanitec/k8s-cluster-aks
driver_inputs:
  values:
    loadbalancer: ${INGRESS_IP}
    name: ${CLUSTER_NAME}
    resource_group: ${RESOURCE_GROUP}
    subscription_id: ${AZURE_SUBCRIPTION_ID}
  secrets:
    credentials: ${AKS_ADMIN_SP_CREDENTIALS}
criteria:
  - env_id: ${HUMANITEC_ENVIRONMENT}
EOF

yq -o json ${CLUSTER_NAME}.yaml > ${CLUSTER_NAME}.json
curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/resources/defs" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
    -d @${CLUSTER_NAME}.json
```

## In-cluster MySQL database

```bash
yq -o json resources/mysql-incluster-resource.yaml > resources/mysql-incluster-resource.json
curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/resources/defs" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
    -d @resources/mysql-incluster-resource.json
```

## Terraform Driver resources

### Azure Blob Storage

```bash
cat <<EOF > azure-blob-terraform.yaml
id: azure-blob-terraform
name: azure-blob-terraform
type: azure-blob
driver_type: ${HUMANITEC_ORG}/terraform
driver_inputs:
  values:
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
        azure_subscription_id: ${AZURE_SUBCRIPTION_ID}
        azure_subscription_tenant_id: ${AZURE_SUBCRIPTION_TENANT_ID}
        service_principal_id: ${TERRAFORM_CONTRIBUTOR_SP_ID}
        service_principal_password: ${TERRAFORM_CONTRIBUTOR_SP_PASSWORD}
EOF

yq -o json azure-blob-terraform.yaml > azure-blob-terraform.json
curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/resources/defs" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
    -d @azure-blob-terraform.json
```

### Azure MySQL

```bash
cat <<EOF > azure-mysql-terraform.yaml
id: azure-mysql-terraform
name: azure-mysql-terraform
type: azure-mysql
driver_type: ${HUMANITEC_ORG}/terraform
driver_inputs:
  values:
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
        azure_subscription_id: ${AZURE_SUBCRIPTION_ID}
        azure_subscription_tenant_id: ${AZURE_SUBCRIPTION_TENANT_ID}
        service_principal_id: ${TERRAFORM_CONTRIBUTOR_SP_ID}
        service_principal_password: ${TERRAFORM_CONTRIBUTOR_SP_PASSWORD}
EOF

yq -o json azure-mysql-terraform.yaml > azure-mysql-terraform.json
curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/resources/defs" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
    -d @azure-mysql-terraform.json
```