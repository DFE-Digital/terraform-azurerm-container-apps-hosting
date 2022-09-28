resource "azurerm_storage_account" "mssql_security_storage" {
  count = local.enable_mssql_database ? 1 : 0

  name                     = "${local.resource_prefix}mssqlsec"
  resource_group_name      = local.resource_group.name
  location                 = local.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.tags
}

resource "azurerm_mssql_server" "default" {
  count = local.enable_mssql_database ? 1 : 0

  name                          = local.resource_prefix
  resource_group_name           = local.resource_group.name
  location                      = local.resource_group.location
  version                       = "12.0"
  administrator_login           = "${local.resource_prefix}-admin"
  administrator_login_password  = local.mssql_server_admin_password
  public_network_access_enabled = false
  minimum_tls_version           = "1.2"
  tags                          = local.tags
}

resource "azurerm_mssql_server_extended_auditing_policy" "default" {
  count = local.enable_mssql_database ? 1 : 0

  server_id                               = azurerm_mssql_server.default[0].id
  storage_endpoint                        = azurerm_storage_account.mssql_security_storage[0].primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.mssql_security_storage[0].primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = 90
}

resource "azurerm_mssql_database" "default" {
  count = local.enable_mssql_database ? 1 : 0

  name        = local.mssql_database_name
  server_id   = azurerm_mssql_server.default[0].id
  collation   = "SQL_Latin1_General_CP1_CI_AS"
  sku_name    = local.mssql_sku_name
  max_size_gb = local.mssql_max_size_gb
  tags        = local.tags
}

resource "azurerm_mssql_database_extended_auditing_policy" "default" {
  count = local.enable_mssql_database ? 1 : 0

  database_id                             = azurerm_mssql_database.default[0].id
  storage_endpoint                        = azurerm_storage_account.mssql_security_storage[0].primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.mssql_security_storage[0].primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = 90
}

resource "azurerm_private_endpoint" "default_mssql" {
  count = local.enable_mssql_database ? 1 : 0

  name                = "${local.resource_prefix}defaultmssql"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  subnet_id           = azurerm_subnet.mssql_private_endpoint_subnet[0].id

  private_service_connection {
    name                           = "${local.resource_prefix}defaultmssqlconnection"
    private_connection_resource_id = azurerm_mssql_server.default[0].id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
  tags = local.tags
}

resource "azurerm_private_dns_a_record" "mssql_private_endpoint" {
  count = local.enable_mssql_database ? 1 : 0

  name                = "@"
  zone_name           = azurerm_private_dns_zone.mssql_private_link[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.default_mssql[0].private_service_connection.0.private_ip_address]
  tags                = local.tags
}
