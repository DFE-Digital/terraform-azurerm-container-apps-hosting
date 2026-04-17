resource "azurerm_servicebus_namespace" "function_apps" {
  #checkov:skip=CKV_AZURE_202: Suppressing check pending review
  #checkov:skip=CKV_AZURE_201: Suppressing check pending review
  #checkov:skip=CKV_AZURE_199: Suppressing check pending review
  #checkov:skip=CKV_AZURE_203: Suppressing check pending review
  #checkov:skip=CKV_AZURE_204: Suppressing check pending review
  #checkov:skip=CKV_AZURE_205: Suppressing check pending review

  for_each = {
    for k, v in local.linux_function_apps : k => v if v["enable_service_bus"]
  }

  name                = "${local.environment}${each.key}-function-app"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_namespace_authorization_rule" "function_apps" {
  for_each = {
    for k, v in local.linux_function_apps : k => v if v["enable_service_bus"]
  }

  name         = "${local.environment}${each.key}-function-app"
  namespace_id = azurerm_servicebus_namespace.function_apps[each.key].id
  listen       = true
  send         = true
  manage       = false
}

resource "azurerm_servicebus_topic" "function_apps" {
  for_each = {
    for k, v in local.linux_function_apps : k => v if v["enable_service_bus"]
  }

  name                  = "${local.environment}${each.key}-function-app"
  namespace_id          = azurerm_servicebus_namespace.function_apps[each.key].id
  partitioning_enabled  = false
  max_size_in_megabytes = 1024
}

resource "azurerm_servicebus_subscription" "function_apps" {
  for_each = {
    for k, v in local.linux_function_apps : k => v if v["enable_service_bus"]
  }

  name                                 = "${local.environment}${each.key}-function-app"
  topic_id                             = azurerm_servicebus_topic.function_apps[each.key].id
  max_delivery_count                   = 10
  lock_duration                        = "PT1M"
  dead_lettering_on_message_expiration = true
}

resource "azurerm_servicebus_subscription" "function_apps_additional" {
  for_each = toset(flatten([
    for k, v in local.linux_function_apps : formatlist("${k}_%s", v["service_bus_additional_subscriptions"]) if v["enable_service_bus"]
  ]))

  name                                 = "${local.environment}${each.key}-function-app"
  topic_id                             = azurerm_servicebus_topic.function_apps[split("_", each.key)[0]].id
  max_delivery_count                   = 10
  lock_duration                        = "PT1M"
  dead_lettering_on_message_expiration = true
}
