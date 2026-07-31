# Plan-time guards for invalid kind/tier/HNS combinations. Every run here is
# expected to fail variable validation before any provider configuration or
# Azure call, so this file needs no credentials and creates no resources.

provider "azurerm" {
  features {}
  storage_use_azuread = true
}

variables {
  location            = "australiaeast"
  resource_group_name = "tftestsa"
  sequence_no         = "99"
}

# The originally reported failure: Premium StorageV2 is a premium page blob
# account, which does not support HNS. Azure accepts the create request and
# then fails provisioning, leaving the account tainted.
run "premium_storagev2_hns_rejected" {
  module {
    source = "./.."
  }
  command = plan

  variables {
    tier = "Premium"
  }

  expect_failures = [var.is_hns_enabled]
}

run "filestorage_hns_rejected" {
  module {
    source = "./.."
  }
  command = plan

  variables {
    account_kind = "FileStorage"
    tier         = "Premium"
  }

  expect_failures = [var.is_hns_enabled]
}

run "standard_blockblobstorage_rejected" {
  module {
    source = "./.."
  }
  command = plan

  variables {
    account_kind   = "BlockBlobStorage"
    is_hns_enabled = false
  }

  expect_failures = [var.account_kind]
}

run "standard_filestorage_rejected" {
  module {
    source = "./.."
  }
  command = plan

  variables {
    account_kind   = "FileStorage"
    is_hns_enabled = false
  }

  expect_failures = [var.account_kind]
}

run "premium_blobstorage_rejected" {
  module {
    source = "./.."
  }
  command = plan

  variables {
    account_kind   = "BlobStorage"
    tier           = "Premium"
    is_hns_enabled = false
  }

  expect_failures = [var.account_kind]
}

run "filestorage_change_feed_rejected" {
  module {
    source = "./.."
  }
  command = plan

  variables {
    account_kind   = "FileStorage"
    tier           = "Premium"
    is_hns_enabled = false
    blob_properties = {
      change_feed_enabled = true
    }
  }

  expect_failures = [var.account_kind]
}

# The provider rejects versioning on HNS accounts only after the account is
# created (in the blob properties step), which also leaves it tainted.
run "versioning_with_hns_rejected" {
  module {
    source = "./.."
  }
  command = plan

  variables {
    blob_properties = {
      versioning_enabled = true
    }
  }

  expect_failures = [var.is_hns_enabled]
}
