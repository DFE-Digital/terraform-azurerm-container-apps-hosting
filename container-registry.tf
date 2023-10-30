resource "azurerm_container_registry" "acr" {
  count = local.enable_container_registry ? 1 : 0

  name                = replace(local.resource_prefix, "-", "")
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  sku                 = local.registry_sku
  admin_enabled       = true
  tags                = local.tags

  dynamic "retention_policy" {
    for_each = local.registry_sku == "Premium" ? [1] : []

    content {
      days    = local.registry_retention_days
      enabled = local.enable_registry_retention_policy
    }
  }
}
