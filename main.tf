resource "azurerm_user_assigned_identity" "this" {
  name                = "tftest-umi-${var.sequence_no}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Destroy order: azurerm_storage_account.this references this identity via
  # identity_ids, creating an implicit Terraform dependency that guarantees the
  # storage account is destroyed BEFORE this identity. This is intentional — if
  # CMK encryption is enabled, the identity must remain valid until the storage
  # account (and its Key Vault access) is fully removed. Do not remove the
  # identity_ids reference from the storage account without preserving an
  # explicit depends_on, or this ordering guarantee is lost.
}

resource "azurerm_storage_account" "this" {
  name                            = "${var.resource_group_name}dl${var.sequence_no}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_kind                    = var.account_kind
  account_tier                    = var.tier
  account_replication_type        = "LRS"
  is_hns_enabled                  = var.is_hns_enabled
  sftp_enabled                    = var.sftp_enabled
  local_user_enabled              = var.sftp_enabled
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  dynamic "blob_properties" {
    for_each = var.account_kind != "FileStorage" ? [1] : []
    content {
      versioning_enabled            = var.blob_properties.versioning_enabled
      change_feed_enabled           = var.blob_properties.change_feed_enabled
      change_feed_retention_in_days = var.blob_properties.change_feed_retention_days

      dynamic "container_delete_retention_policy" {
        for_each = var.blob_properties.container_delete_retention_policy != null ? [var.blob_properties.container_delete_retention_policy] : []
        content {
          days = container_delete_retention_policy.value.days
        }
      }

      dynamic "delete_retention_policy" {
        for_each = var.blob_properties.delete_retention_policy != null ? [var.blob_properties.delete_retention_policy] : []
        content {
          days = delete_retention_policy.value.days
        }
      }
    }
  }

  tags = var.tags
}
