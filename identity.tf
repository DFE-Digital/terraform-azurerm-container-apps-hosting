resource "azurerm_user_assigned_identity" "containerapp" {
  count = local.registry_use_managed_identity ? 1 : 0

  location            = local.resource_group.location
  name                = "${local.resource_prefix}-uami-containerapp"
  resource_group_name = local.resource_group.name
  tags                = local.tags
}

resource "azurerm_role_assignment" "acrpull" {
  count = local.registry_use_managed_identity && local.registry_managed_identity_assign_role ? 1 : 0

  scope                = azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.containerapp[0].id
  description          = "Allow Azure Container Apps to pull images from an Azure Container Registry"
}
