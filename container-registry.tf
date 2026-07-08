resource "azurerm_container_registry" "acr" {
  count = local.enable_container_registry ? 1 : 0

  #checkov:skip=CKV_AZURE_166: Ensure container image quarantine, scan, and mark images verified
  #checkov:skip=CKV_AZURE_233: Ensure Azure Container Registry (ACR) is zone redundant
  #checkov:skip=CKV_AZURE_137: Ensure ACR admin account is disabled - set in variables
  #checkov:skip=CKV_AZURE_164: Ensures that ACR uses signed/trusted images
  #checkov:skip=CKV_AZURE_139: Ensure ACR set to disable public networking - set in variables
  #checkov:skip=CKV_AZURE_237: Ensure dedicated data endpoints are enabled.
  #checkov:skip=CKV_AZURE_165: Ensure geo-replicated container registries to match multi-region container deployments.

  name                          = replace(local.resource_prefix, "-", "")
  resource_group_name           = local.resource_group.name
  location                      = local.resource_group.location
  sku                           = local.registry_sku
  admin_enabled                 = local.registry_admin_enabled
  public_network_access_enabled = local.registry_public_access_enabled
  tags                          = local.tags
  retention_policy_in_days      = local.registry_sku == "Premium" && local.enable_registry_retention_policy ? local.registry_retention_days : null
  network_rule_bypass_option    = "None"

  dynamic "network_rule_set" {
    for_each = local.registry_sku == "Premium" && length(local.registry_ipv4_allow_list) > 0 ? { ip_rules : local.registry_ipv4_allow_list } : {}

    content {
      default_action = "Deny"

      dynamic "ip_rule" {
        for_each = network_rule_set.value

        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }
    }
  }
}
