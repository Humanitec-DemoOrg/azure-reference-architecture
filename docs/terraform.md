# By Terraform

Tools needed:
- `terraform`

```bash
HUMANITEC_TOKEN=FIXME
HUMANITEC_ORG=FIXME
```

```bash
cd terraform/

terraform init

terraform plan \
    -var humanitec_credentials="{\"organization\"=\"${HUMANITEC_ORG}\", \"token\"=\"${HUMANITEC_TOKEN}\"}" \
    -out tfplan

terraform apply \
    tfplan
```