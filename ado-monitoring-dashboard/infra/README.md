# Infra

This folder is for the main project infrastructure after bootstrap has completed.

`infra/` should not create its own backend storage account or first deployment identity. Those are produced by `bootstrap/foundation/` and then passed into `infra/` through backend configuration and Azure DevOps service connection setup.

## Inputs expected from bootstrap

- target subscription ID
- Terraform backend resource group name
- Terraform backend storage account name
- Terraform backend container name
- deployment identity details

## Suggested next layout

```text
infra/
  modules/
  environments/
    dev/
    test/
    prod/
```

Keep workload resources here, and keep bootstrap resources in `bootstrap/` so you can reason about first-run platform setup separately from normal environment delivery.