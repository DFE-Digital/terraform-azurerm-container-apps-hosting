resource "azurerm_resource_group" "default" {
  count = local.existing_resource_group == "" ? 1 : 0

  name     = local.resource_prefix
  location = local.azure_location
  tags     = local.tags
}
