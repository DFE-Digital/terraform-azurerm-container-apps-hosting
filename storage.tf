resource "azurerm_storage_account" "container_app" {
  count = local.enable_storage_account ? 1 : 0

  name                             = "${replace(local.resource_prefix, "-", "")}storage"
  resource_group_name              = local.resource_group.name
  location                         = local.resource_group.location
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  min_tls_version                  = "TLS1_2"
  enable_https_traffic_only        = true
  public_network_access_enabled    = local.storage_account_public_access_enabled
  shared_access_key_enabled        = local.container_app_storage_account_shared_access_key_enabled
  allow_nested_items_to_be_public  = local.container_app_blob_storage_public_access_enabled
  cross_tenant_replication_enabled = local.container_app_storage_cross_tenant_replication_enabled

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  share_properties {
    retention_policy {
      days = 7
    }

    dynamic "smb" {
      for_each = lower(local.container_app_file_share_security_profile) == "security" ? [1] : []

      content {
        versions                        = ["SMB3.1.1"]
        authentication_types            = ["NTLMv2", "Kerberos"]
        kerberos_ticket_encryption_type = ["AES-256"]
        channel_encryption_type         = ["AES-128-GCM", "AES-256-GCM"]
      }
    }
  }

  tags = local.tags
}

resource "azapi_update_resource" "container_app_storage_key_rotation_reminder" {
  count = local.enable_storage_account ? 1 : 0

  type        = "Microsoft.Storage/storageAccounts@2023-01-01"
  resource_id = azurerm_storage_account.container_app[0].id
  body = jsonencode({
    properties = {
      keyPolicy : {
        keyExpirationPeriodInDays : local.storage_account_access_key_rotation_reminder_days
      }
    }
  })

  depends_on = [
    azurerm_storage_account.container_app[0]
  ]
}

resource "azurerm_storage_account_network_rules" "container_app" {
  count = local.enable_storage_account ? 1 : 0

  storage_account_id         = azurerm_storage_account.container_app[0].id
  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  virtual_network_subnet_ids = [azurerm_subnet.container_apps_infra_subnet[0].id]
  ip_rules                   = local.storage_account_ipv4_allow_list
}

resource "azurerm_storage_container" "container_app" {
  count = local.enable_container_app_blob_storage ? 1 : 0

  name                 = "${local.resource_prefix}-storage"
  storage_account_name = azurerm_storage_account.container_app[0].name
}

resource "azurerm_storage_share" "container_app" {
  count = local.enable_container_app_file_share ? 1 : 0

  name                 = "${local.resource_prefix}-storage"
  storage_account_name = azurerm_storage_account.container_app[0].name
  quota                = local.storage_account_file_share_quota_gb
}

resource "azurerm_monitor_diagnostic_setting" "blobs" {
  count = local.enable_container_app_blob_storage ? 1 : 0

  name                       = "${local.resource_prefix}-storage-blobs-diag"
  target_resource_id         = "${azurerm_storage_account.container_app[0].id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.container_app.id
  eventhub_name              = local.enable_event_hub ? azurerm_eventhub.container_app[0].name : null

  enabled_log {
    category_group = "Audit"
  }

  # The below metrics are kept in to avoid a diff in the Terraform Plan output
  metric {
    category = "Capacity"
    enabled  = false
  }
  metric {
    category = "Transaction"
    enabled  = false
  }
}

resource "azurerm_monitor_diagnostic_setting" "files" {
  count = local.enable_container_app_file_share ? 1 : 0

  name                       = "${local.resource_prefix}-storage-files-diag"
  target_resource_id         = "${azurerm_storage_account.container_app[0].id}/fileServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.container_app.id
  eventhub_name              = local.enable_event_hub ? azurerm_eventhub.container_app[0].name : null

  enabled_log {
    category_group = "Audit"
  }

  # The below metrics are kept in to avoid a diff in the Terraform Plan output
  metric {
    category = "Capacity"
    enabled  = false
  }
  metric {
    category = "Transaction"
    enabled  = false
  }
}

data "azurerm_storage_account_blob_container_sas" "container_app" {
  count = local.create_container_app_blob_storage_sas ? 1 : 0

  connection_string = azurerm_storage_account.container_app[0].primary_connection_string
  container_name    = azurerm_storage_container.container_app[0].name
  https_only        = true
  start             = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
  expiry            = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timeadd(timestamp(), "+4380h")) # +6 months

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = true
    list   = true
  }
}
