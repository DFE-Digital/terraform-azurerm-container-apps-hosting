resource "azurerm_container_registry" "acr" {
  count = local.enable_container_registry ? 1 : 0

  name                          = replace(local.resource_prefix, "-", "")
  resource_group_name           = local.resource_group.name
  location                      = local.resource_group.location
  sku                           = local.registry_sku
  admin_enabled                 = local.registry_admin_enabled
  public_network_access_enabled = local.registry_public_access_enabled
  tags                          = local.tags
  retention_policy_in_days      = local.registry_sku == "Premium" && local.enable_registry_retention_policy ? local.registry_retention_days : null

  dynamic "network_rule_set" {
    for_each = local.registry_sku == "Premium" && length(local.registry_ipv4_allow_list) > 0 ? { ip_rules : local.registry_ipv4_allow_list } : {}

    content {
      default_action = "Deny"

      # Allow the Container App subnet to access the Container Registry
      virtual_network {
        action    = "Allow"
        subnet_id = azurerm_subnet.container_apps_infra_subnet[0].id
      }

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
