# ado monitoring dashboard

Terraform and other components for an Azure DevOps based dashboard that takes the results of terraform pipeline runs, ticket completions and other State of DevOps report metrics to guage an organisations effectiveness.

## Repository structure

- `bootstrap/` contains first-run Terraform for subscription setup, Terraform state backend creation, and the initial deployment identity.
- `infra/` contains the main workload infrastructure — Storage, Function App, Key Vault, and Entra ID App Registration.
- `function-app/` contains the Python Azure Functions code (event ingest endpoint + dashboard SPA).
- `pipelines/` contains the ADO pipeline definitions.

The bootstrap split is deliberate: the remote backend and shared identity must exist before the main infrastructure stack can run safely from Azure DevOps.

## Prerequisites

### 1. Bootstrap (`bootstrap/`)

Run `terraform apply` locally (once) using an account with Owner rights on the subscription. This creates:

- The Terraform remote state storage account
- The User-Assigned Managed Identity (UAMI) used by the ADO pipeline service connection

### 2. Entra ID — Application Administrator role on the UAMI

The `infra/` stack creates an Entra ID App Registration (for Easy Auth on the Function App dashboard). The identity running Terraform must have the **Application Administrator** directory role in Entra ID so it can create and manage app registrations.

**This must be done once, manually, before the first `infra/` apply:**

1. Open **Entra ID → Roles and administrators → Application Administrator**
2. Click **+ Add assignments**
3. Search for `id-smi-adodashboard-terraform` and assign it

> Note: this permission cannot be granted through the Enterprise Applications portal UI — it must be assigned via the Roles and administrators blade or the Graph API.

### 3. ADO pipeline secrets

After the first successful `infra/` apply, the dashboard ingest API key is stored in Key Vault. The pipeline reads it automatically at runtime — no manual secret copying is required.

## How it works

```
ADO Pipeline (any repo)
  └── POST /events  (x-api-key header, fetched from Key Vault)
          │
          ▼
    Azure Function App
      ├── Validates API key
      └── Writes event row to Azure Table Storage

Browser user
  └── GET /  (redirects to Entra ID login if unauthenticated)
          │
          ▼
    Dashboard SPA
      └── GET /events  (Entra auth — this tenant only)
                │
                ▼
          Table Storage → last 100 pipeline runs
```

## Deploying

1. Run `bootstrap/` locally once (see above).
2. Assign **Application Administrator** to the UAMI (see above).
3. Push to `main` — the `infra-deploy.yml` pipeline will:
   - Run `terraform plan` (Plan stage)
   - Await manual approval (Apply stage)
   - Deploy the Function App code (DeployFunctionApp stage)
   - Send a notification event to the dashboard itself
