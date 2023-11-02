resource "azurerm_private_endpoint" "default" {
  for_each = local.private_endpoints

  name                = "${local.resource_prefix}${each.key}"
  location            = each.value.resource_group.location
  resource_group_name = each.value.resource_group.name
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = "${local.resource_prefix}${each.key}connection"
    private_connection_resource_id = each.value.resource_id
    subresource_names              = lookup(each.value, "subresource_names", [])
    is_manual_connection           = lookup(each.value, "is_manual_connection", false)
  }

  tags = local.tags
}
