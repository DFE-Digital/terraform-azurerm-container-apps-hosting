resource "azurerm_storage_account" "mssql_security_storage" {
  count = local.enable_mssql_database ? 1 : 0

  name                             = "${replace(local.resource_prefix, "-", "")}mssqlsec"
  resource_group_name              = local.resource_group.name
  location                         = local.resource_group.location
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  min_tls_version                  = "TLS1_2"
  tags                             = local.tags
  https_traffic_only_enabled       = true
  public_network_access_enabled    = local.enable_mssql_vulnerability_assessment ? true : false
  shared_access_key_enabled        = local.mssql_security_storage_shared_access_key_enabled
  allow_nested_items_to_be_public  = false
  cross_tenant_replication_enabled = local.mssql_security_storage_cross_tenant_replication_enabled

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  sas_policy {
    expiration_period = local.storage_account_sas_expiration_period
  }
}

resource "azurerm_storage_account_network_rules" "mssql_security_storage" {
  count = local.enable_mssql_database ? 1 : 0

  storage_account_id = azurerm_storage_account.mssql_security_storage[0].id
  # If Vulnerability Assessment is enabled, then there is not currently a way to
  # store reports in a Storage Account that is protected by a Firewall.
  # Inbound traffic must be permitted to the Storage Account
  default_action             = local.enable_mssql_vulnerability_assessment ? "Allow" : "Deny"
  bypass                     = ["AzureServices"]
  virtual_network_subnet_ids = []
  ip_rules                   = local.mssql_security_storage_firewall_ipv4_allow_list
}

resource "azurerm_storage_container" "mssql_security_storage" {
  count = local.enable_mssql_database ? 1 : 0

  name                 = "${local.resource_prefix}-mssqlsec"
  storage_account_name = azurerm_storage_account.mssql_security_storage[0].name
}

resource "azurerm_storage_management_policy" "mssql_security_storage" {
  count = local.enable_mssql_database ? 1 : 0

  storage_account_id = azurerm_storage_account.mssql_security_storage[0].id

  rule {
    name    = "object-lifecycle-policy"
    enabled = true

    filters {
      prefix_match = ["${azurerm_storage_container.mssql_security_storage[0].name}/*", "sqldbauditlogs/*", "sqldbtdlogs/*"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_creation_greater_than    = 3
        tier_to_archive_after_days_since_creation_greater_than = 7
        delete_after_days_since_creation_greater_than          = 30
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "mssql_security_storage" {
  count = local.enable_mssql_database ? 1 : 0

  name                       = "${local.resource_prefix}-mssql-blob-diag"
  target_resource_id         = "${azurerm_storage_account.mssql_security_storage[0].id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.container_app.id
  eventhub_name              = local.enable_event_hub ? azurerm_eventhub.container_app[0].name : null

  enabled_log {
    category_group = "Audit"
  }

  # The below metrics are kept in to avoid a diff in the Terraform Plan output
  metric {
    category = "Capacity"
    enabled  = false
  }

  metric {
    category = "Transaction"
    enabled  = false
  }
}

resource "azurerm_mssql_server" "default" {
  count = local.enable_mssql_database ? 1 : 0

  name                                     = local.resource_prefix
  resource_group_name                      = local.resource_group.name
  location                                 = local.resource_group.location
  version                                  = local.mssql_version
  administrator_login                      = local.mssql_server_admin_password != "" ? "${local.resource_prefix}-admin" : null
  administrator_login_password             = local.mssql_server_admin_password != "" ? local.mssql_server_admin_password : null
  express_vulnerability_assessment_enabled = local.enable_mssql_vulnerability_assessment
  public_network_access_enabled            = local.mssql_server_public_access_enabled
  minimum_tls_version                      = "1.2"

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

  server_id         = azurerm_mssql_server.default[0].id
  storage_endpoint  = azurerm_storage_account.mssql_security_storage[0].primary_blob_endpoint
  retention_in_days = 90
}

resource "azurerm_mssql_database" "default" {
  count = local.enable_mssql_database ? 1 : 0

  name                           = local.mssql_database_name
  server_id                      = azurerm_mssql_server.default[0].id
  collation                      = "SQL_Latin1_General_CP1_CI_AS"
  sku_name                       = local.mssql_sku_name
  max_size_gb                    = local.mssql_max_size_gb
  maintenance_configuration_name = local.mssql_maintenance_configuration_name != "" ? local.mssql_maintenance_configuration_name : "SQL_Default"

  threat_detection_policy {
    state                = "Enabled"
    email_account_admins = "Enabled"
    retention_days       = 90
  }

  tags = local.tags
}

resource "azurerm_mssql_database_extended_auditing_policy" "default" {
  count = local.enable_mssql_database ? 1 : 0

  database_id       = azurerm_mssql_database.default[0].id
  storage_endpoint  = azurerm_storage_account.mssql_security_storage[0].primary_blob_endpoint
  retention_in_days = 90
}

resource "azurerm_mssql_firewall_rule" "default_mssql" {
  for_each = local.enable_mssql_database ? local.mssql_firewall_ipv4_allow_list : {}

  name             = each.key
  server_id        = azurerm_mssql_server.default[0].id
  start_ip_address = each.value.start_ip_range
  end_ip_address   = lookup(each.value, "end_ip_range", "") != "" ? each.value.end_ip_range : each.value.start_ip_range
}

resource "azapi_update_resource" "mssql_threat_protection" {
  count = local.enable_mssql_database ? 1 : 0

  type      = "Microsoft.Sql/servers/advancedThreatProtectionSettings@2023-05-01-preview"
  name      = azurerm_mssql_server.default[0].name
  parent_id = azurerm_mssql_server.default[0].id
  body = jsonencode({
    properties = {
      state = local.enable_mssql_vulnerability_assessment ? "Enabled" : "Disabled"
    }
  })

  depends_on = [
    azurerm_mssql_server.default[0]
  ]
}

resource "azapi_update_resource" "mssql_security_storage_key_rotation_reminder" {
  count = local.enable_mssql_database ? 1 : 0

  type        = "Microsoft.Storage/storageAccounts@2023-01-01"
  resource_id = azurerm_storage_account.mssql_security_storage[0].id
  body = jsonencode({
    properties = {
      keyPolicy : {
        keyExpirationPeriodInDays : local.mssql_security_storage_access_key_rotation_reminder_days
      }
    }
  })

  depends_on = [
    azurerm_storage_account.mssql_security_storage[0]
  ]
}
