data "azurerm_virtual_network" "existing_virtual_network" {
  count = local.existing_virtual_network == "" ? 0 : 1

  name                = local.existing_virtual_network
  resource_group_name = local.existing_resource_group
}

data "azurerm_resource_group" "existing_resource_group" {
  count = local.existing_resource_group == "" ? 0 : 1

  name = local.existing_resource_group
}
