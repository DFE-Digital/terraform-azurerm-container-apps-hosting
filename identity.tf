resource "azurerm_user_assigned_identity" "containerapp" {
  count = local.enable_container_app_uami ? 1 : 0

  location            = local.resource_group.location
  name                = "${local.resource_prefix}-uami-containerapp"
  resource_group_name = local.resource_group.name
  tags                = local.tags
}

resource "azurerm_role_assignment" "containerapp_acrpull" {
  count = local.registry_use_managed_identity && local.registry_managed_identity_assign_role ? 1 : 0

  scope                = azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.containerapp[0].id
  description          = "Allow Azure Container Apps to pull images from an Azure Container Registry"
}

resource "azurerm_user_assigned_identity" "mssql" {
  count = local.enable_mssql_database ? 1 : 0

  location            = local.resource_group.location
  name                = "${local.resource_prefix}-uami-mssql"
  resource_group_name = local.resource_group.name
  tags                = local.tags
}

resource "azurerm_role_assignment" "mssql_storageblobdatacontributor" {
  count = local.enable_mssql_database && local.mssql_managed_identity_assign_role ? 1 : 0

  scope                = azurerm_storage_account.mssql_security_storage[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.mssql[0].id
  description          = "Allow SQL Auditing to write reports and findings into the MSSQL Security Storage Account"
}

resource "azurerm_user_assigned_identity" "function_apps" {
  for_each = local.enable_linux_function_apps ? merge(local.linux_function_apps, local.linux_function_health_insights_api) : {}

  location            = local.resource_group.location
  name                = "${each.key}-uami-functionapp"
  resource_group_name = local.resource_group.name
  tags                = local.tags
}
