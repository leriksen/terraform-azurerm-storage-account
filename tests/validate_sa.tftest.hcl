provider "azurerm" {
  features {}
  storage_use_azuread = true
}

variables {
  location = "australiaeast"
}

run "setup_rg" {
  module {
    source = "./setup_rg"
  }
  command = apply

  variables {
    name     = "tftestsa"
    location = var.location
  }
}

run "storage_account_with_blob_properties" {
  module {
    source = "./.."
  }
  command = apply

  variables {
    resource_group_name = run.setup_rg.name
    location            = var.location
    sequence_no         = "01"
    blob_properties = {
      change_feed_enabled        = true
      change_feed_retention_days = 7
    }
    tags = { env = "tftest" }
  }

  assert {
    condition     = azurerm_storage_account.this.name == "tftestsadl01"
    error_message = "Storage account name should be <resource_group_name>dl<sequence_no>."
  }

  assert {
    condition     = azurerm_storage_account.this.is_hns_enabled == true
    error_message = "Storage account must have HNS (ADLS Gen2) enabled."
  }

  assert {
    condition     = output.umi_principal_id != ""
    error_message = "UMI principal id should be set."
  }

  assert {
    condition     = azurerm_storage_account.this.blob_properties[0].change_feed_enabled == true
    error_message = "Blob properties change_feed_enabled should be true."
  }

  assert {
    condition     = azurerm_storage_account.this.blob_properties[0].delete_retention_policy[0].days == 7
    error_message = "Blob properties delete_retention_policy days should default to 7."
  }

  assert {
    condition     = azurerm_storage_account.this.blob_properties[0].container_delete_retention_policy[0].days == 7
    error_message = "Blob properties container_delete_retention_policy days should default to 7."
  }

  assert {
    condition     = azurerm_storage_account.this.account_tier == "Standard"
    error_message = "account_tier should default to Standard."
  }
}

run "storage_account_without_blob_properties" {
  module {
    source = "./.."
  }
  command = apply

  variables {
    resource_group_name = run.setup_rg.name
    location            = var.location
    sequence_no         = "02"
    tags                = { env = "tftest" }
  }

  assert {
    condition     = azurerm_storage_account.this.name == "tftestsadl02"
    error_message = "Storage account name should be <resource_group_name>dl<sequence_no>."
  }

  assert {
    condition     = azurerm_storage_account.this.is_hns_enabled == true
    error_message = "Storage account must have HNS (ADLS Gen2) enabled."
  }

  assert {
    condition     = output.umi_principal_id != ""
    error_message = "UMI principal id should be set."
  }

  assert {
    condition     = azurerm_storage_account.this.blob_properties[0].change_feed_enabled == false
    error_message = "Blob properties change_feed_enabled should be false."
  }
}

run "storage_account_file_storage_skips_blob_properties" {
  module {
    source = "./.."
  }
  command = apply

  variables {
    resource_group_name = run.setup_rg.name
    location            = var.location
    sequence_no         = "03"
    account_kind        = "FileStorage"
    account_tier        = "Premium"
    is_hns_enabled      = false
    blob_properties = {
      versioning_enabled                = true
      container_delete_retention_policy = { days = 9 }
      delete_retention_policy           = { days = 9 }
    }
    tags = { env = "tftest" }
  }

  assert {
    condition     = length(azurerm_storage_account.this.blob_properties) == 0
    error_message = "blob_properties must be dropped for FileStorage even when explicitly passed."
  }

  assert {
    condition     = azurerm_storage_account.this.account_kind == "FileStorage"
    error_message = "account_kind should be FileStorage."
  }
}
