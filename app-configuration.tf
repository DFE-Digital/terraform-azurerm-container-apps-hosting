resource "azurerm_app_configuration" "default" {
  count = local.enable_app_configuration ? 1 : 0

  name                  = "${local.resource_prefix}appconfig"
  resource_group_name   = local.resource_group.name
  location              = local.resource_group.location
  sku                   = local.app_configuration_sku
  local_auth_enabled    = true
  public_network_access = "Disabled"

  tags = local.tags
}
