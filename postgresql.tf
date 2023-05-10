resource "azurerm_postgresql_flexible_server" "default" {
  count = local.enable_postgresql_database ? 1 : 0

  name                   = "${local.resource_prefix}-pg-flexserv"
  resource_group_name    = local.resource_group.name
  location               = local.resource_group.location
  version                = local.postgresql_server_version
  delegated_subnet_id    = azurerm_subnet.postgresql_private_endpoint_subnet[0].id
  private_dns_zone_id    = azurerm_private_dns_zone.postgresql_private_link[0].id
  administrator_login    = local.postgresql_administrator_login
  administrator_password = local.postgresql_administrator_password
  zone                   = local.postgresql_availability_zone

  storage_mb = local.postgresql_max_storage_mb

  sku_name   = local.postgresql_sku_name
  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql_private_link[0]]
  tags       = local.tags
}

resource "azurerm_postgresql_flexible_server_database" "default" {
  count = local.enable_postgresql_database ? 1 : 0

  name      = "${local.resource_prefix}-pg"
  server_id = azurerm_postgresql_flexible_server.default[0].id
  collation = local.postgresql_collation
  charset   = local.postgresql_charset
}

# https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-extensions?WT.mc_id=Portal-Microsoft_Azure_OSSDatabases#postgres-13-extensions
resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  count = local.enable_postgresql_database && local.postgresql_enabled_extensions != "" ? 1 : 0

  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.default[0].id
  value     = local.postgresql_enabled_extensions
}

