resource "azurerm_virtual_network" "default" {
  name                = "${local.resource_prefix}default"
  address_space       = [local.virtual_network_address_space]
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_route_table" "default" {
  name                          = "${local.resource_prefix}default"
  location                      = azurerm_resource_group.default.location
  resource_group_name           = azurerm_resource_group.default.name
  disable_bgp_route_propagation = false
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
