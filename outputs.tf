output "id" {
  value       = azurerm_storage_account.this.id
  description = "Resource ID of the storage account."
}

output "umi_id" {
  value       = azurerm_user_assigned_identity.this.id
  description = "Resource ID of the user-assigned managed identity."
}

output "umi_principal_id" {
  value       = azurerm_user_assigned_identity.this.principal_id
  description = "Principal ID of the user-assigned managed identity."
}

output "blob_properties" {
  value       = azurerm_storage_account.this.blob_properties
  description = "The blob_properties block as applied on the storage account."
}

output "change_feed_enabled" {
  value       = try(azurerm_storage_account.this.blob_properties[0].change_feed_enabled, null)
  description = "Whether change feed is enabled on the storage account."
}