# By CLI

Tools needed:
- `gh`

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