resource "azurerm_service_plan" "function_apps" {
  count = local.enable_linux_function_apps ? 1 : 0

  name                = "${local.resource_prefix}-linux-serviceplan"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  os_type             = "Linux"
  sku_name            = "B1"

  tags = local.tags
}

resource "azurerm_linux_function_app" "health_api" {
  for_each = local.linux_function_health_insights_api

  name                                           = "${local.environment}${each.key}"
  resource_group_name                            = local.resource_group.name
  location                                       = local.resource_group.location
  storage_account_name                           = azurerm_storage_account.function_app_backing[0].name
  storage_account_access_key                     = azurerm_storage_account.function_app_backing[0].primary_access_key
  service_plan_id                                = azurerm_service_plan.function_apps[0].id
  ftp_publish_basic_authentication_enabled       = each.value.ftp_publish_basic_authentication_enabled
  webdeploy_publish_basic_authentication_enabled = each.value.webdeploy_publish_basic_authentication_enabled
  https_only                                     = true
  zip_deploy_file                                = data.archive_file.azure_function[each.key].output_path
  key_vault_reference_identity_id                = azurerm_user_assigned_identity.function_apps[each.key].id
  virtual_network_subnet_id                      = azurerm_subnet.function_apps_infra_subnet[0].id

  app_settings = merge(each.value.app_settings, {
    "WEBSITE_RUN_FROM_PACKAGE" = 1,
    "AZURE_CLIENT_ID"          = azurerm_user_assigned_identity.function_apps[each.key].client_id
    "WEBSITE_DNS_SERVER"       = "168.63.129.16" // Azure Private DNS Resolver
  })

  site_config {
    always_on                              = true
    application_insights_connection_string = azurerm_application_insights.function_apps[each.key].connection_string
    application_insights_key               = azurerm_application_insights.function_apps[each.key].instrumentation_key
    app_scale_limit                        = 1
    http2_enabled                          = true
    vnet_route_all_enabled                 = true

    cors {
      allowed_origins     = each.value.allowed_origins
      support_credentials = contains(each.value.allowed_origins, "*") ? false : true
    }

    ip_restriction {
      action                    = "Allow"
      name                      = "AllowSubnetInbound"
      virtual_network_subnet_id = azurerm_subnet.function_apps_infra_subnet[0].id
    }

    dynamic "ip_restriction" {
      for_each = each.value.ipv4_access

      content {
        action     = "Allow"
        name       = "AllowIPInbound${ip_restriction.value}"
        ip_address = ip_restriction.value
      }
    }

    application_stack {
      python_version = lower(each.value.runtime) == "python" ? each.value.runtime_version : null
      dotnet_version = lower(each.value.runtime) == "dotnet" ? each.value.runtime_version : null
      java_version   = lower(each.value.runtime) == "java" ? each.value.runtime_version : null
      node_version   = lower(each.value.runtime) == "node" ? each.value.runtime_version : null
    }
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.function_apps[each.key].id
    ]
  }

  tags = merge(local.tags, {
    "hidden-link: /app-insights-conn-string" : azurerm_application_insights.function_apps[each.key].connection_string,
    "hidden-link: /app-insights-instrumentation-key" : azurerm_application_insights.function_apps[each.key].instrumentation_key,
    "hidden-link: /app-insights-resource-id" : azurerm_application_insights.function_apps[each.key].id,
  })
}

resource "azurerm_linux_function_app" "function_apps" {
  for_each = local.linux_function_apps

  name                                           = "${local.environment}${each.key}"
  resource_group_name                            = local.resource_group.name
  location                                       = local.resource_group.location
  storage_account_name                           = azurerm_storage_account.function_app_backing[0].name
  storage_account_access_key                     = azurerm_storage_account.function_app_backing[0].primary_access_key
  service_plan_id                                = azurerm_service_plan.function_apps[0].id
  ftp_publish_basic_authentication_enabled       = each.value.ftp_publish_basic_authentication_enabled
  webdeploy_publish_basic_authentication_enabled = each.value.webdeploy_publish_basic_authentication_enabled
  https_only                                     = true
  zip_deploy_file                                = data.archive_file.azure_function[each.key].output_path
  key_vault_reference_identity_id                = azurerm_user_assigned_identity.function_apps[each.key].id
  virtual_network_subnet_id                      = azurerm_subnet.function_apps_infra_subnet[0].id

  app_settings = merge(each.value.app_settings, {
    "WEBSITE_RUN_FROM_PACKAGE" = 1,
    "AZURE_CLIENT_ID"          = azurerm_user_assigned_identity.function_apps[each.key].client_id
    "WEBSITE_DNS_SERVER"       = "168.63.129.16" // Azure Private DNS Resolver
  })

  site_config {
    always_on                              = true
    application_insights_connection_string = local.enable_app_insights_integration ? azurerm_application_insights.function_apps[each.key].connection_string : null
    application_insights_key               = local.enable_app_insights_integration ? azurerm_application_insights.function_apps[each.key].instrumentation_key : null
    app_scale_limit                        = 1
    http2_enabled                          = true
    vnet_route_all_enabled                 = true

    cors {
      allowed_origins     = each.value.allowed_origins
      support_credentials = contains(each.value.allowed_origins, "*") ? false : true
    }

    ip_restriction {
      action                    = "Allow"
      name                      = "AllowSubnetInbound"
      virtual_network_subnet_id = azurerm_subnet.function_apps_infra_subnet[0].id
    }

    dynamic "ip_restriction" {
      for_each = each.value.ipv4_access

      content {
        action     = "Allow"
        name       = "AllowIPInbound${ip_restriction.value}"
        ip_address = ip_restriction.value
      }
    }

    application_stack {
      python_version = lower(each.value.runtime) == "python" ? each.value.runtime_version : null
      dotnet_version = lower(each.value.runtime) == "dotnet" ? each.value.runtime_version : null
      java_version   = lower(each.value.runtime) == "java" ? each.value.runtime_version : null
      node_version   = lower(each.value.runtime) == "node" ? each.value.runtime_version : null
    }
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.function_apps[each.key].id
    ]
  }

  tags = merge(local.tags, local.enable_app_insights_integration ? {
    "hidden-link: /app-insights-conn-string" : azurerm_application_insights.function_apps[each.key].connection_string,
    "hidden-link: /app-insights-instrumentation-key" : azurerm_application_insights.function_apps[each.key].instrumentation_key,
    "hidden-link: /app-insights-resource-id" : azurerm_application_insights.function_apps[each.key].id,
  } : {})
}

resource "azurerm_monitor_diagnostic_setting" "function_apps" {
  for_each = merge(local.linux_function_apps, local.linux_function_health_insights_api)

  name                       = "${azurerm_linux_function_app.function_apps[each.key].name}-diagnostics"
  target_resource_id         = azurerm_linux_function_app.function_apps[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.function_app[0].id

  enabled_log {
    category = "FunctionAppLogs"
  }
}
