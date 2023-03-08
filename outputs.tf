output "azurerm_resource_group_default" {
  value       = local.existing_resource_group == "" ? azurerm_resource_group.default[0] : null
  description = "Default Azure Resource Group"
}

output "azurerm_log_analytics_workspace_container_app" {
  value       = azurerm_log_analytics_workspace.container_app
  description = "Container App Log Analytics Workspace"
}

output "azurerm_eventhub_container_app" {
  value       = local.enable_event_hub ? azurerm_eventhub.container_app[0] : null
  description = "Container App Event Hub"
}
