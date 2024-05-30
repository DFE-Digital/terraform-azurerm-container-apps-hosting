resource "azurerm_key_vault" "default" {
  count = local.escrow_container_app_secrets_in_key_vault && local.existing_key_vault == "" ? 1 : 0

  name                       = "${local.resource_prefix}-kv"
  location                   = local.azure_location
  resource_group_name        = local.resource_group.name
  tenant_id                  = data.azurerm_subscription.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  enable_rbac_authorization  = true
  purge_protection_enabled   = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = length(local.key_vault_access_ipv4) > 0 ? local.key_vault_access_ipv4 : null
    virtual_network_subnet_ids = local.launch_in_vnet ? [
      azurerm_subnet.container_apps_infra_subnet[0].id
    ] : []
  }

  tags = local.tags
}

resource "azurerm_key_vault_secret" "secret_app_setting" {
  for_each = local.escrow_container_app_secrets_in_key_vault ? nonsensitive(local.container_app_secrets) : {}

  name         = each.value["name"]
  value        = sensitive(each.value["value"])
  key_vault_id = local.key_vault.id
  content_type = "Container App Environment Variable"
}

resource "azurerm_role_assignment" "kv_secret_reader" {
  count = local.escrow_container_app_secrets_in_key_vault && local.key_vault_managed_identity_assign_role ? 1 : 0

  scope                = local.key_vault.id
  role_definition_name = "Key Vault Secret User"
  principal_id         = azurerm_user_assigned_identity.containerapp[0].id
  description          = "Allow Azure Container Apps to read secrets from an Azure Key Vault"
}
