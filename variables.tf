# ── Required ────────────────────────────────────────────────────────────────

variable "resource_group_name" {
  type        = string
  description = "Resource group to create the storage account and identity in. Also used as the storage account name prefix (\"<resource_group_name>dl<sequence_no>\"), so it must yield a valid storage account name (3-24 chars, lowercase alphanumeric)."
}

variable "sequence_no" {
  type        = string
  description = "Numeric suffix used to name the storage account and user-assigned identity (e.g. \"01\")."
}

variable "location" {
  type        = string
  description = "Azure region."
}

# ── Optional ────────────────────────────────────────────────────────────────

variable "is_hns_enabled" {
  type        = bool
  default     = true
  description = "Enable hierarchical namespace (HNS) for the storage account (required for ADLS Gen2)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the storage account and identity."
}

variable "sftp_enabled" {
  type        = bool
  default     = false
  description = "Enable SFTP and local users on the storage account."
}

variable "account_kind" {
  type        = string
  default     = "StorageV2"
  description = "Defines the Kind of account. Valid options are BlobStorage, BlockBlobStorage, FileStorage and StorageV2."

  validation {
    condition     = anytrue(
      [
        var.blob_properties.change_feed_enabled == false && contains(["StorageV2", "BlobStorage", "BlockBlobStorage", "FileStorage"], var.account_kind),
        var.blob_properties.change_feed_enabled == true  && contains(["StorageV2", "BlobStorage", "BlockBlobStorage"], var.account_kind)
      ]
    )
    error_message = "account_kind must be one of StorageV2, BlobStorage, or BlockBlobStorage when blob_properties.change_feed_enabled is true, or one of those or FileStorage if false."
  }
}

variable "account_tier" {
  type        = string
  default     = "Standard"
  description = "Defines the Tier to use for this storage account. Valid options are Standard and Premium."

  validation {
    condition     = contains(["Premium", "Standard"], var.account_tier)
    error_message = "account_tier must be Premium or Standard."
  }
}

variable "blob_properties" {
  type = object(
    {
      versioning_enabled         = optional(bool, false)
      change_feed_enabled        = optional(bool, false)
      change_feed_retention_days = optional(number, null)
      container_delete_retention_policy = optional(
        object(
          {
            days = number
          }
        ),
        {
          days = 7
        }
      )
      delete_retention_policy = optional(
        object(
          {
            days = number
          }
        ),
        {
          days = 7
        }
      )
      cors_rule = optional(
        object(
          {
            allowed_origins    = list(string)
            allowed_methods    = list(string)
            allowed_headers    = list(string)
            exposed_headers    = list(string)
            max_age_in_seconds = number
          }
        ),
        null
      )
    }
  )
  default     = {}
  nullable    = false
  description = "Blob service properties: versioning, change feed, container/blob soft-delete retention, and CORS."
}