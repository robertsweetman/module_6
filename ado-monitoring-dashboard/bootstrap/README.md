# Bootstrap

This folder owns the first-run Azure setup that must exist before the main `infra` stack can use a remote backend or deployment identity.

`bootstrap/` creates:

- a Resource Group and Storage Account for Terraform remote state
- a Blob Container for state files
- a User-Assigned Managed Identity (UAMI) for Azure DevOps pipelines
- a Federated Identity Credential linking the UAMI to an Azure DevOps service connection (Workload Identity Federation)
- subscription-level RBAC role assignments for the UAMI

This resolves the circular dependency: the Terraform backend must exist before `infra/` can use remote state, and the UAMI must exist before Azure DevOps can authenticate without a secret.

## Authentication model

Run bootstrap using your own Azure CLI credentials (`az login`). Do not hardcode credentials into Terraform files or commit them to version control.

The UAMI created here is used by Azure DevOps pipelines going forward — no shared secrets required.

## Execution order

### Phase 1 — create the backend and managed identity (local state)

```powershell
cd bootstrap
terraform init
terraform apply
```

Capture these outputs:

| Output | Used for |
| --- | --- |
| `storage_account_name` | `backend.tf` migration, ADO variable group |
| `resource_group_name` | `backend.tf` migration |
| `container_name` | `backend.tf` migration |
| `smi_client_id` | Azure DevOps service connection wizard |
| `smi_principal_id` | Verification |
| `smi_tenant_id` | Azure DevOps service connection wizard |

### Phase 2 — migrate state to remote backend

1. Edit `backend.tf`: uncomment the `terraform { backend "azurerm" { ... } }` block and paste in `storage_account_name` from the output above.
2. Run:

```powershell
terraform init -migrate-state
```

### Phase 3 — configure Azure DevOps service connection

1. In Azure DevOps, go to **Project Settings → Service connections → New service connection → Azure Resource Manager → Workload identity federation (manual)**.
2. Fill in:
   - **Subscription ID**: `d576283e-72e4-4cfd-8310-4f182b07dd00`
   - **Application (client) ID**: value of `smi_client_id` output
3. Copy the **Issuer** and **Subject identifier** from the ADO wizard into `variables.tf` (or a `terraform.tfvars` file — do not commit secrets).
4. Run `terraform apply` again to create the federated credential.
5. Back in ADO, click **Verify** on the service connection.

## File layout

```terraform
bootstrap/
  backend.tf              # Phase 1: local; Phase 2: remote (uncomment block)
  data.tf                 # azurerm_subscription.current
  locals.tf               # storage account name derivation, common tags
  main.tf                 # resource group, storage account, container, random suffix
  outputs.tf              # storage + subscription outputs
  providers.tf            # azurerm + random providers
  smi_credential.tf       # federated identity credential (ADO OIDC)
  smi_identity.tf         # user-assigned managed identity
  smi_outputs.tf          # UAMI client/principal/tenant ID outputs
  smi_role_assignments.tf # subscription-level RBAC for the UAMI
  variables.tf            # subscription_id, tenant_id, location, project_name, ADO federation values
```
