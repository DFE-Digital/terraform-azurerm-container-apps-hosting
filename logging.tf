resource "azurerm_log_analytics_workspace" "container_app" {
  name                = "${local.resource_prefix}containerapp"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_log_analytics_workspace" "function_app" {
  count               = local.enable_linux_function_apps ? 1 : 0
  name                = "${local.resource_prefix}functionapp"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_log_analytics_data_export_rule" "container_app" {
  count                   = local.enable_event_hub ? 1 : 0
  name                    = "${local.resource_prefix}containerapp"
  resource_group_name     = local.resource_group.name
  workspace_resource_id   = azurerm_log_analytics_workspace.container_app.id
  destination_resource_id = azurerm_eventhub.container_app[0].id
  table_names             = local.eventhub_export_log_analytics_table_names
  enabled                 = true
}

resource "azurerm_log_analytics_query_pack" "container_app" {
  name                = "${local.resource_prefix}containerapp"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  tags                = local.tags
}

resource "azurerm_eventhub_namespace" "container_app" {
  count               = local.enable_event_hub ? 1 : 0
  name                = "${local.resource_prefix}eventhubnamespace"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  sku                 = "Standard"
  capacity            = 1
  tags                = local.tags
}

resource "azurerm_monitor_diagnostic_setting" "event_hub" {
  count = local.enable_event_hub ? 1 : 0

  name                       = "${local.resource_prefix}-eventhub-diag"
  target_resource_id         = azurerm_eventhub_namespace.container_app[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.container_app.id
  eventhub_name              = azurerm_eventhub.container_app[0].name

  enabled_log {
    category_group = "Audit"
  }
}

resource "azurerm_eventhub" "container_app" {
  count               = local.enable_event_hub ? 1 : 0
  name                = "${local.resource_prefix}containerapp"
  namespace_name      = azurerm_eventhub_namespace.container_app[0].name
  resource_group_name = local.resource_group.name
  partition_count     = 2
  message_retention   = 7
}

resource "azurerm_eventhub_consumer_group" "logstash" {
  count               = local.enable_event_hub && local.enable_logstash_consumer ? 1 : 0
  name                = "${local.resource_prefix}eventhubconsumergroup"
  namespace_name      = azurerm_eventhub_namespace.container_app[0].name
  eventhub_name       = azurerm_eventhub.container_app[0].name
  resource_group_name = local.resource_group.name
  user_metadata       = "Logstash"
}

resource "azurerm_eventhub_authorization_rule" "listen_only" {
  count               = local.enable_event_hub && local.enable_logstash_consumer ? 1 : 0
  name                = "${local.resource_prefix}eventhublistenrule"
  namespace_name      = azurerm_eventhub_namespace.container_app[0].name
  eventhub_name       = azurerm_eventhub.container_app[0].name
  resource_group_name = local.resource_group.name
  listen              = true
  send                = false
  manage              = false
}
