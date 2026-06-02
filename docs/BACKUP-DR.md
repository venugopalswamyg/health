# Backup & Disaster Recovery (one-pager)

## Objectives
- **RPO (Recovery Point Objective):** ≤ 24h for the database (point-in-time within retention).
- **RTO (Recovery Time Objective):** ≤ 1h for app, ≤ 2–4h for a full region rebuild.

## What we back up

| Asset | Mechanism | Retention | Restore |
|---|---|---|---|
| PostgreSQL data | Flexible Server automated backups (`backup_retention_days = 7`) + point-in-time restore | 7 days | `az postgres flexible-server restore` to a new server, repoint `DATABASE_URL` in Key Vault |
| Terraform state | Azure Blob (`tfstatehealthcare`) with versioning + soft delete; blob-lease locking | per storage policy | restore prior blob version |
| Key Vault secrets | Soft delete + purge protection (`soft_delete_retention_days = 7`) | 7 days | `az keyvault secret recover` |
| Container images | ACR (geo-replication on Premium for prod) | indefinite | re-pull by digest/tag (immutable Git SHA tags) |
| Cluster config | Declarative (Terraform + Helm in git) | git history | `terraform apply` + `helm upgrade --install` |

## Recovery runbooks

### App / cluster failure
1. `helm rollback healthcare-app <REV> -n <ns>` (fast path), or
2. Recreate cluster with Terraform, then `helm upgrade --install` from the last good image
   tag (Git SHA), which is immutable in ACR.

### Database failure / corruption
1. `az postgres flexible-server restore --restore-time <ISO8601> --source-server <name> --name <new>`.
2. Update the `database-url` secret in Key Vault to point at the restored server.
3. CSI rotation (or pod restart) propagates the new connection string.

### Region outage (DR)
1. Provision the stack in a paired region via `terraform apply -var-file=environments/prod.tfvars`
   (override `location`).
2. Restore PostgreSQL via geo-restore; rely on ACR geo-replication (Premium) for images.
3. Repoint DNS / ingress to the new region.

## Tested / not tested
- ✅ `helm rollback` path is implemented in the pipeline deploy steps.
- ⬜ Full region failover is documented but not rehearsed in this assessment (cost/time).
