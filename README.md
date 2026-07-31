# terraform-azurerm-storage-account

Terraform module for an Azure Storage Account with a
dedicated user-assigned managed identity.

Will support customer-managed keys (CMK) in the future, but currently uses platform-managed keys.

The account is created hardened by default: shared access keys disabled, OAuth
default authentication, no public nested items, LRS replication. SFTP and local
users can be enabled via `sftp_enabled`.

The storage account is named `<resource_group_name>dl<sequence_no>` and the
identity `tftest-umi-<sequence_no>`.

> **Destroy ordering:** the storage account references the identity via
> `identity_ids`, creating an implicit dependency so the account is destroyed
> before the identity. This is intentional for CMK scenarios — see the comment
> in `main.tf`.

## Usage

```hcl
module "storage_account" {
  source  = "app.terraform.io/leif-lab3/terraform-azurerm-storage-account/azurerm"
  version = "0.6.0"

  resource_group_name = "myrg"
  sequence_no         = "01"
  location            = "australiaeast"

  tags = {
    environment = "dev"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| hashicorp/azurerm | >= 4.0.0, < 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| resource\_group\_name | Resource group; also the storage account name prefix | `string` | — | yes |
| sequence\_no | Numeric suffix for the account and identity names | `string` | — | yes |
| location | Azure region | `string` | — | yes |
| tags | Tags to apply | `map(string)` | `{}` | no |
| sftp\_enabled | Enable SFTP and local users | `bool` | `false` | no |
| is\_hns\_enabled | Enable hierarchical namespace (required for ADLS Gen2). Only valid on `Standard`/`StorageV2` and `Premium`/`BlockBlobStorage` accounts — see [Kind, tier and HNS constraints](#kind-tier-and-hns-constraints) | `bool` | `true` | no |
| account\_kind | Kind of storage account. One of `BlobStorage`, `BlockBlobStorage`, `FileStorage`, `StorageV2`. Must be `StorageV2`, `BlobStorage`, or `BlockBlobStorage` if `blob_properties.change_feed_enabled` is `true` | `string` | `"StorageV2"` | no |
| account\_tier | Tier of the storage account. One of `Standard`, `Premium`. `BlockBlobStorage`/`FileStorage` kinds require `Premium`; `BlobStorage` requires `Standard` | `string` | `"Standard"` | no |
| blob\_properties | Blob service properties: versioning, change feed, container/blob soft-delete retention, and CORS. Ignored when `account_kind` is `FileStorage` — such accounts have no blob service, so the block is dropped even if explicitly set. See `variables.tf` for the full object shape | <pre>object({<br>  versioning_enabled                = optional(bool, false)<br>  change_feed_enabled               = optional(bool, false)<br>  change_feed_retention_days        = optional(number, null)<br>  container_delete_retention_policy = optional(object({ days = number }), { days = 7 })<br>  delete_retention_policy           = optional(object({ days = number }), { days = 7 })<br>  cors_rule = optional(object({<br>    allowed_origins    = list(string)<br>    allowed_methods    = list(string)<br>    allowed_headers    = list(string)<br>    exposed_headers    = list(string)<br>    max_age_in_seconds = number<br>  }), null)<br>})</pre> | `{}` | no |

## Kind, tier and HNS constraints

Azure only supports a hierarchical namespace (ADLS Gen2) on two combinations:

| account\_tier | account\_kind | HNS |
|---------------|---------------|-----|
| `Standard` | `StorageV2` | ✅ |
| `Premium` | `BlockBlobStorage` | ✅ |
| anything else | | ❌ |

The azurerm provider does not check the tier, so an invalid combination (e.g.
`Premium` + `StorageV2` + HNS) is accepted by the initial create call and then
fails during Azure-side provisioning, leaving the account tainted in state.
This module rejects those combinations at plan time instead, along with:

- `account_tier`/`account_kind` mismatches (`BlockBlobStorage`/`FileStorage`
  require `Premium`; `BlobStorage` requires `Standard`), and
- `blob_properties.versioning_enabled = true` together with
  `is_hns_enabled = true` — Azure rejects blob versioning on HNS accounts
  after the account is created, which also taints it.

These guards are covered by plan-only tests in
`tests/validate_inputs.tftest.hcl`.

## Outputs

| Name | Description |
|------|-------------|
| id | Resource ID of the storage account |
| umi\_id | Resource ID of the user-assigned managed identity |
| umi\_principal\_id | Principal ID of the user-assigned managed identity |
| blob\_properties | The blob\_properties block as applied on the storage account |
| change\_feed\_enabled | Whether change feed is enabled on the storage account |

## Testing

Tests use HCP Terraform as the backend. From the `tests/` directory:

```bash
terraform init
terraform test
```
