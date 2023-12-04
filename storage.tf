resource "azurerm_storage_account" "container_app" {
  count = local.enable_storage_account ? 1 : 0

  name                            = "${replace(local.resource_prefix, "-", "")}storage"
  resource_group_name             = local.resource_group.name
  location                        = local.resource_group.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  enable_https_traffic_only       = true
  public_network_access_enabled   = local.storage_account_public_access_enabled
  allow_nested_items_to_be_public = local.container_app_blob_storage_public_access_enabled

  tags = local.tags
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

  name                           = "${local.resource_prefix}-storage-blobs-diag"
  target_resource_id             = "${azurerm_storage_account.container_app[0].id}/blobServices/default"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.container_app.id
  log_analytics_destination_type = "Dedicated"
  eventhub_name                  = local.enable_event_hub ? azurerm_eventhub.container_app[0].name : null

  enabled_log {
    category_group = "Audit"
  }
}

resource "azurerm_monitor_diagnostic_setting" "files" {
  count = local.enable_container_app_file_share ? 1 : 0

  name                           = "${local.resource_prefix}-storage-files-diag"
  target_resource_id             = "${azurerm_storage_account.container_app[0].id}/fileServices/default"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.container_app.id
  log_analytics_destination_type = "Dedicated"
  eventhub_name                  = local.enable_event_hub ? azurerm_eventhub.container_app[0].name : null

  enabled_log {
    category_group = "Audit"
  }
}

data "azurerm_storage_account_blob_container_sas" "container_app" {
  count = local.enable_container_app_blob_storage ? 1 : 0

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
