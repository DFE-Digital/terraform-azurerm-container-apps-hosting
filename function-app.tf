resource "azurerm_service_plan" "function_apps" {
  count = local.enable_linux_function_apps ? 1 : 0

  name                = "${local.resource_prefix}-linux-serviceplan"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  os_type             = "Linux"
  sku_name            = "Y1" // PAYG/Consumption plan

  tags = local.tags
}

resource "azurerm_service_plan" "function_apps_flex" {
  count = local.enable_linux_function_apps ? 1 : 0

  name                = "${local.resource_prefix}-linux-serviceplan-flex"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  os_type             = "Linux"
  sku_name            = "FC1" // Flex Consumption Plan

  tags = local.tags
}

resource "azurerm_linux_function_app" "health_api" {
  for_each = local.linux_function_health_insights_api

  name                                           = "${local.resource_prefix}-${each.key}"
  resource_group_name                            = local.resource_group.name
  location                                       = local.resource_group.location
  storage_account_name                           = azurerm_storage_account.function_app_backing[0].name
  storage_account_access_key                     = azurerm_storage_account.function_app_backing[0].primary_access_key
  service_plan_id                                = azurerm_service_plan.function_apps[0].id
  ftp_publish_basic_authentication_enabled       = each.value.ftp_publish_basic_authentication_enabled
  webdeploy_publish_basic_authentication_enabled = each.value.webdeploy_publish_basic_authentication_enabled
  https_only                                     = true
  key_vault_reference_identity_id                = azurerm_user_assigned_identity.function_apps[each.key].id
  zip_deploy_file                                = data.archive_file.azure_function[each.key].output_path

  app_settings = merge(each.value.app_settings, {
    "AZURE_CLIENT_ID" = azurerm_user_assigned_identity.function_apps[each.key].client_id
  })

  site_config {
    always_on                              = false
    application_insights_connection_string = local.enable_app_insights_integration ? azurerm_application_insights.function_apps[each.key].connection_string : null
    application_insights_key               = local.enable_app_insights_integration ? azurerm_application_insights.function_apps[each.key].instrumentation_key : null
    app_scale_limit                        = 1
    http2_enabled                          = true
    ftps_state                             = each.value.ftp_publish_basic_authentication_enabled ? "FtpsOnly" : "Disabled"
    ip_restriction_default_action          = length(each.value.ipv4_access) > 0 ? "Deny" : "Allow"
    scm_ip_restriction_default_action      = length(each.value.ipv4_access) > 0 ? "Deny" : "Allow"
    scm_use_main_ip_restriction            = true
    minimum_tls_version                    = "1.3"

    cors {
      allowed_origins     = each.value.allowed_origins
      support_credentials = contains(each.value.allowed_origins, "*") ? false : true
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

  lifecycle {
    replace_triggered_by = [terraform_data.function_app_package_sha[each.key]]
  }
}

resource "azurerm_storage_container" "function_app_backing" {
  for_each = local.linux_function_apps

  name                 = each.key
  storage_account_name = azurerm_storage_account.function_app_backing[0].name
}

resource "azurerm_function_app_flex_consumption" "function_apps" {
  for_each = local.linux_function_apps

  name                                           = "${local.environment}${each.key}"
  resource_group_name                            = local.resource_group.name
  location                                       = local.resource_group.location
  storage_container_type                         = "blobContainer"
  storage_authentication_type                    = "StorageAccountConnectionString"
  storage_access_key                             = azurerm_storage_account.function_app_backing[0].primary_access_key
  storage_container_endpoint                     = "${azurerm_storage_account.function_app_backing[0].primary_blob_endpoint}${azurerm_storage_container.function_app_backing[each.key].name}"
  runtime_name                                   = each.value["runtime"]
  runtime_version                                = each.value["runtime_version"]
  service_plan_id                                = azurerm_service_plan.function_apps_flex[0].id
  webdeploy_publish_basic_authentication_enabled = each.value.webdeploy_publish_basic_authentication_enabled
  https_only                                     = true
  virtual_network_subnet_id                      = local.launch_in_vnet ? azurerm_subnet.function_app_subnet[0].id : null

  app_settings = merge(each.value.app_settings, {
    "AZURE_CLIENT_ID" = azurerm_user_assigned_identity.function_apps[each.key].client_id
    },
    each.value["enable_service_bus"] ? {
      "SERVICEBUS_TOPIC_NAME"   = azurerm_servicebus_topic.function_apps[each.key].name
      "SERVICEBUS_SUBSCRIPTION" = azurerm_servicebus_subscription.function_apps[each.key].name
    } : {}
  )

  dynamic "connection_string" {
    for_each = each.value["enable_service_bus"] ? [1] : []

    content {
      name  = "ServiceBus"
      type  = "ServiceBus"
      value = azurerm_servicebus_namespace_authorization_rule.function_apps[each.key].primary_connection_string
    }
  }

  dynamic "connection_string" {
    for_each = each.value["connection_strings"]

    content {
      name  = connection_string.key
      type  = connection_string.value["type"]
      value = connection_string.value["value"]
    }
  }

  site_config {
    application_insights_connection_string = local.enable_app_insights_integration ? azurerm_application_insights.function_apps[each.key].connection_string : null
    application_insights_key               = local.enable_app_insights_integration ? azurerm_application_insights.function_apps[each.key].instrumentation_key : null
    http2_enabled                          = true
    ip_restriction_default_action          = length(each.value.ipv4_access) > 0 ? "Deny" : "Allow"
    scm_ip_restriction_default_action      = length(each.value.ipv4_access) > 0 ? "Deny" : "Allow"
    scm_use_main_ip_restriction            = true
    minimum_tls_version                    = each.value.minimum_tls_version

    cors {
      allowed_origins     = each.value.allowed_origins
      support_credentials = contains(each.value.allowed_origins, "*") ? false : true
    }

    dynamic "ip_restriction" {
      for_each = each.value.ipv4_access

      content {
        action     = "Allow"
        name       = "AllowIPInbound${ip_restriction.value}"
        ip_address = ip_restriction.value
      }
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
  for_each = local.linux_function_apps

  name                       = "${azurerm_function_app_flex_consumption.function_apps[each.key].name}-diagnostics"
  target_resource_id         = azurerm_function_app_flex_consumption.function_apps[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.function_app[0].id

  enabled_log {
    category = "FunctionAppLogs"
  }
}

resource "azurerm_monitor_diagnostic_setting" "function_apps_health_api" {
  for_each = local.linux_function_health_insights_api

  name                       = "${azurerm_linux_function_app.health_api[each.key].name}-diagnostics"
  target_resource_id         = azurerm_linux_function_app.health_api[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.function_app[0].id

  enabled_log {
    category = "FunctionAppLogs"
  }
}
