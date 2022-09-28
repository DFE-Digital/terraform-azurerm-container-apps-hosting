resource "azurerm_container_registry" "acr" {
  count = local.enable_container_registry ? 1 : 0

  name                = replace(local.resource_prefix, "-", "")
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  sku                 = "Standard"
  admin_enabled       = true
  tags                = local.tags
}
