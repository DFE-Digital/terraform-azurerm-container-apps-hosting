resource "azurerm_container_registry" "acr" {
  count = local.enable_container_registry ? 1 : 0

  name                = replace(local.resource_prefix, "-", "")
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  sku                 = "Standard"
  admin_enabled       = true
  tags                = local.tags
}
