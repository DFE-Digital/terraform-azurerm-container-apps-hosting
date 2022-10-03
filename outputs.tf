output "azurerm_resource_group_default" {
  value = local.existing_resource_group == "" ? azurerm_resource_group.default[0] : null
}
