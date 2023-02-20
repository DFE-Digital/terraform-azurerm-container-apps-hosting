resource "azurerm_storage_account" "container_app" {
  count = local.enable_container_app_blob_storage ? 1 : 0

  name                      = "${replace(local.resource_prefix, "-", "")}storage"
  resource_group_name       = local.resource_group.name
  location                  = local.resource_group.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  min_tls_version           = "TLS1_2"
  tags                      = local.tags
  enable_https_traffic_only = true
}

resource "azurerm_storage_container" "container_app" {
  depends_on = [
    azurerm_storage_account.container_app[0]
  ]

  name                  = "${local.resource_prefix}-storage"
  storage_account_name  = azurerm_storage_account.container_app[0].name
  container_access_type = "private"
}

data "azurerm_storage_account_blob_container_sas" "container_app" {
  depends_on = [
    azurerm_storage_account.container_app[0],
    azurerm_storage_container.container_app
  ]

  connection_string = azurerm_storage_account.container_app[0].primary_connection_string
  container_name    = azurerm_storage_container.container_app.name
  https_only        = true

  start  = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
  expiry = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timeadd(timestamp(), "+4380h")) # +6 months

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = true
    list   = true
  }
}
