resource "azurerm_network_watcher" "default" {
  count = local.enable_network_watcher ? 1 : 0

  name                = "${local.resource_prefix}default"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  tags = local.tags
}

resource "azurerm_storage_account" "default_network_watcher_nsg_flow_logs" {
  count = local.enable_network_watcher ? 1 : 0

  name                      = "${local.resource_prefix}nwnsgdefault"
  resource_group_name       = local.resource_group.location
  location                  = local.resource_group.name
  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  min_tls_version           = "TLS1_2"
  enable_https_traffic_only = true

  tags = local.tags
}

resource "azurerm_log_analytics_workspace" "default_network_watcher_nsg_flow_logs" {
  count = local.enable_network_watcher && local.enable_network_watcher_traffic_analytics ? 1 : 0

  name                = "${local.resource_prefix}nwnsgdefault"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  sku                 = "PerGB2018"

  tags = local.tags
}

resource "azurerm_network_watcher_flow_log" "default_network_watcher_nsg" {
  for_each = local.enable_network_watcher ? local.network_security_group_ids : []

  network_watcher_name = azurerm_network_watcher.default[0].name
  resource_group_name  = azurerm_resource_group.default[0].name
  name                 = "${local.resource_prefix}nsg${each.value}"

  network_security_group_id = each.value
  storage_account_id        = azurerm_storage_account.default_network_watcher_nsg_flow_logs[0].id
  enabled                   = true

  retention_policy {
    enabled = local.network_watcher_retention == 0 ? false : true
    days    = local.network_watcher_retention
  }

  dynamic "traffic_analytics" {
    for_each = local.enable_network_watcher && local.enable_network_watcher_traffic_analytics ? [0] : []
    content {
      enabled               = true
      workspace_id          = azurerm_log_analytics_workspace.default_network_watcher_nsg_flow_logs[0].workspace_id
      workspace_region      = azurerm_log_analytics_workspace.default_network_watcher_nsg_flow_logs[0].location
      workspace_resource_id = azurerm_log_analytics_workspace.default_network_watcher_nsg_flow_logs[0].id
      interval_in_minutes   = local.network_watcher_traffic_analytics_interval
    }
  }

  tags = local.tags
}
