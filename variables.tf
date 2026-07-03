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
