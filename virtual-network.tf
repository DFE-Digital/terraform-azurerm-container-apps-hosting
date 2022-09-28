resource "azurerm_virtual_network" "default" {
  name                = "${local.resource_prefix}default"
  address_space       = [local.virtual_network_address_space]
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  tags                = local.tags
}

resource "azurerm_route_table" "default" {
  name                          = "${local.resource_prefix}default"
  location                      = azurerm_resource_group.default.location
  resource_group_name           = azurerm_resource_group.default.name
  disable_bgp_route_propagation = false
  tags                          = local.tags
}

resource "azurerm_subnet" "container_apps_infra_subnet" {
  name                 = "${local.resource_prefix}containerappsinfra"
  virtual_network_name = azurerm_virtual_network.default.name
  resource_group_name  = azurerm_resource_group.default.name
  address_prefixes     = [local.container_apps_infra_subnet_cidr]
}

resource "azurerm_subnet_route_table_association" "container_apps_infra_subnet" {
  subnet_id      = azurerm_subnet.container_apps_infra_subnet.id
  route_table_id = azurerm_route_table.default.id
}

resource "azurerm_subnet" "mssql_private_endpoint_subnet" {
  count = local.enable_mssql_database ? 1 : 0

  name                                      = "${local.resource_prefix}mssqlprivateendpoint"
  virtual_network_name                      = azurerm_virtual_network.default.name
  resource_group_name                       = azurerm_resource_group.default.name
  address_prefixes                          = [local.mssql_private_endpoint_subnet_cidr]
  private_endpoint_network_policies_enabled = true
}

resource "azurerm_subnet_route_table_association" "mssql_private_endpoint_subnet" {
  count = local.enable_mssql_database ? 1 : 0

  subnet_id      = azurerm_subnet.mssql_private_endpoint_subnet[0].id
  route_table_id = azurerm_route_table.default.id
}

resource "azurerm_private_dns_zone" "mssql_private_link" {
  count = local.enable_mssql_database ? 1 : 0

  name                = "${local.resource_prefix}.database.windows.net"
  resource_group_name = azurerm_resource_group.default.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "mssql_private_link" {
  count = local.enable_mssql_database ? 1 : 0

  name                  = "${local.resource_prefix}mssqlprivatelink"
  resource_group_name   = azurerm_resource_group.default.name
  private_dns_zone_name = azurerm_private_dns_zone.mssql_private_link[0].name
  virtual_network_id    = azurerm_virtual_network.default.id
  tags                  = local.tags
}

resource "azurerm_subnet" "container_instances_subnet" {
  count = local.enable_mssql_database ? 1 : 0

  name                                      = "${local.resource_prefix}containerinstances"
  virtual_network_name                      = azurerm_virtual_network.default.name
  resource_group_name                       = azurerm_resource_group.default.name
  address_prefixes                          = [local.container_instances_subnet_cidr]
  private_endpoint_network_policies_enabled = true

  delegation {
    name = "ACIDelegationService"
    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
      name = "Microsoft.ContainerInstance/containerGroups"
    }
  }
}

resource "azurerm_subnet_route_table_association" "containerinstances_subnet" {
  count = local.enable_mssql_database ? 1 : 0

  subnet_id      = azurerm_subnet.container_instances_subnet[0].id
  route_table_id = azurerm_route_table.default.id
}
