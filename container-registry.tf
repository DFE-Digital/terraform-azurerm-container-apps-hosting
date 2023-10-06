resource "azurerm_container_registry" "acr" {
  count = local.enable_container_registry ? 1 : 0

  name                          = replace(local.resource_prefix, "-", "")
  resource_group_name           = local.resource_group.name
  location                      = local.resource_group.location
  sku                           = local.registry_sku
  admin_enabled                 = local.registry_admin_enabled
  public_network_access_enabled = local.registry_public_access_enabled
  tags                          = local.tags

  dynamic "retention_policy" {
    for_each = local.registry_sku == "Premium" ? [1] : []

    content {
      days    = local.registry_retention_days
      enabled = local.enable_registry_retention_policy
    }
  }

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
        for_each = network_rule_set.value.ip_rules

        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }
    }
  }
}

resource "azurerm_private_endpoint" "acr" {
  count = local.registry_sku == "Premium" ? 1 : 0

  name                = "${local.resource_prefix}defaultacr"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  subnet_id           = azurerm_subnet.container_apps_infra_subnet[0].id

  private_service_connection {
    name                           = "${local.resource_prefix}defaultacrconnection"
    private_connection_resource_id = azurerm_container_registry.acr[0].id
    is_manual_connection           = false
  }

  tags = local.tags
}
