resource "azurerm_storage_account" "mssql_security_storage" {
  count = local.enable_mssql_database ? 1 : 0

  name                            = "${replace(local.resource_prefix, "-", "")}mssqlsec"
  resource_group_name             = local.resource_group.name
  location                        = local.resource_group.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  tags                            = local.tags
  enable_https_traffic_only       = true
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_account_network_rules" "mssql_security_storage" {
  count = local.enable_mssql_database ? 1 : 0

  storage_account_id         = azurerm_storage_account.mssql_security_storage[0].id
  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  virtual_network_subnet_ids = []
  ip_rules                   = local.mssql_firewall_ipv4_allow_list
}

resource "azurerm_storage_container" "mssql_security_storage" {
  count = local.enable_mssql_database ? 1 : 0

  name                 = "${local.resource_prefix}-mssqlsec"
  storage_account_name = azurerm_storage_account.mssql_security_storage[0].name
}

resource "azurerm_monitor_diagnostic_setting" "mssql_security_storage" {
  count = local.enable_mssql_database ? 1 : 0

  name                           = "${local.resource_prefix}-mssql-blob-diag"
  target_resource_id             = "${azurerm_storage_account.mssql_security_storage[0].id}/blobServices/default"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.container_app.id
  log_analytics_destination_type = "Dedicated"
  eventhub_name                  = local.enable_event_hub ? azurerm_eventhub.container_app[0].name : null

  enabled_log {
    category_group = "Audit"
  }
}

resource "azurerm_mssql_server" "default" {
  count = local.enable_mssql_database ? 1 : 0

  name                          = local.resource_prefix
  resource_group_name           = local.resource_group.name
  location                      = local.resource_group.location
  version                       = local.mssql_version
  administrator_login           = local.mssql_server_admin_password != "" ? "${local.resource_prefix}-admin" : null
  administrator_login_password  = local.mssql_server_admin_password != "" ? local.mssql_server_admin_password : null
  public_network_access_enabled = local.mssql_server_public_access_enabled
  minimum_tls_version           = "1.2"

  dynamic "azuread_administrator" {
    for_each = local.mssql_azuread_admin_username != "" ? [1] : []

    content {
      object_id                   = local.mssql_azuread_admin_object_id
      login_username              = local.mssql_azuread_admin_username
      tenant_id                   = data.azurerm_subscription.current.tenant_id
      azuread_authentication_only = local.mssql_azuread_auth_only
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mssql[0].id]
  }

  primary_user_assigned_identity_id = azurerm_user_assigned_identity.mssql[0].id

  tags = local.tags
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

  threat_detection_policy {
    state                      = "Enabled"
    email_account_admins       = "Enabled"
    retention_days             = 90
    storage_endpoint           = azurerm_storage_account.mssql_security_storage[0].primary_blob_endpoint
    storage_account_access_key = azurerm_storage_account.mssql_security_storage[0].primary_access_key
  }

  tags = local.tags
}

resource "azurerm_mssql_database_extended_auditing_policy" "default" {
  count = local.enable_mssql_database ? 1 : 0

  database_id                             = azurerm_mssql_database.default[0].id
  storage_endpoint                        = azurerm_storage_account.mssql_security_storage[0].primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.mssql_security_storage[0].primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = 90
}

resource "azurerm_mssql_firewall_rule" "default_mssql" {
  for_each = local.enable_mssql_database ? toset(local.mssql_firewall_ipv4_allow_list) : []

  name             = "${replace(local.resource_prefix, "-", "")}fw${each.key}"
  server_id        = azurerm_mssql_server.default[0].id
  start_ip_address = each.value
  end_ip_address   = each.value
}

resource "azurerm_mssql_server_security_alert_policy" "default" {
  count = local.enable_mssql_database && local.enable_mssql_vulnerability_assessment ? 1 : 0

  resource_group_name        = local.resource_group.name
  server_name                = azurerm_mssql_server.default[0].name
  state                      = "Enabled"
  email_account_admins       = true
  email_addresses            = local.monitor_email_receivers
  retention_days             = 90
  storage_endpoint           = azurerm_storage_account.mssql_security_storage[0].primary_blob_endpoint
  storage_account_access_key = azurerm_storage_account.mssql_security_storage[0].primary_access_key
}

resource "azurerm_mssql_server_vulnerability_assessment" "default" {
  count = local.enable_mssql_database && local.enable_mssql_vulnerability_assessment ? 1 : 0

  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.default[0].id
  storage_container_path          = "${azurerm_storage_account.mssql_security_storage[0].primary_blob_endpoint}${azurerm_storage_container.mssql_security_storage[0].name}/"
  storage_account_access_key      = azurerm_storage_account.mssql_security_storage[0].primary_access_key

  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
    emails                    = local.monitor_email_receivers
  }
}
