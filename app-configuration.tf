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

resource "azurerm_role_assignment" "containerapp_appconfig_read" {
  count = local.enable_app_configuration && local.app_configuration_assign_role ? 1 : 0

  scope                = azurerm_app_configuration.default[0].id
  role_definition_name = "App Configuration Data Reader"
  principal_id         = azurerm_user_assigned_identity.containerapp[0].id
  description          = "Allow Azure Container Apps to read data from App Configuration"
}
