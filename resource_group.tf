resource "azurerm_resource_group" "default" {
  name     = local.resource_prefix
  location = local.azure_location
}
