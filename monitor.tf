resource "azurerm_monitor_action_group" "main" {
  count = local.enable_monitoring ? 1 : 0

  name                = "${local.resource_prefix}-actiongroup"
  resource_group_name = local.resource_group.name
  short_name          = "${local.project_name}-monitor"
  tags                = local.tags

  dynamic "email_receiver" {
    for_each = local.monitor_email_receivers != [] ? local.monitor_email_receivers : []

    content {
      name                    = "Email ${email_receiver.value}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  #   # webhook_receiver = local.monitor_webook_receiver ? {
  #   #   name                    = "Webhook"
  #   #   use_common_alert_schema = true
  #   # } : {}

  dynamic "event_hub_receiver" {
    for_each = local.enable_event_hub ? [1] : []

    content {
      name                    = "Event Hub"
      event_hub_name          = azurerm_eventhub.container_app[0].name
      event_hub_namespace     = azurerm_eventhub_namespace.container_app[0].id
      subscription_id         = data.azurerm_subscription.current.subscription_id
      use_common_alert_schema = true
    }
  }
}

resource "azurerm_application_insights" "main" {
  count = local.enable_monitoring ? 1 : 0

  name                       = "${local.resource_prefix}-container-insights"
  location                   = local.resource_group.location
  resource_group_name        = local.resource_group.name
  application_type           = "web"
  workspace_id               = azurerm_log_analytics_workspace.container_app.id
  internet_ingestion_enabled = false
  internet_query_enabled     = false
  retention_in_days          = 30
  tags                       = local.tags
}

resource "azurerm_application_insights_standard_web_test" "main" {
  count = local.enable_monitoring ? 1 : 0

  name                    = "${local.resource_prefix}-web-test"
  resource_group_name     = local.resource_group.name
  location                = local.resource_group.location
  application_insights_id = azurerm_application_insights.main[0].id
  timeout = 10

  geo_locations = [
    "emea-se-sto-edge", # UK West
    "emea-nl-ams-azr",  # West Europe
    "emea-ru-msa-edge"  # UK South
  ]

  request {
    url = local.enable_cdn_frontdoor ? azurerm_cdn_frontdoor_endpoint.endpoint[0].host_name : jsondecode(azapi_resource.default.output).properties.configuration.ingress.fqdn
  }

  tags = local.tags
}

# resource "azurerm_monitor_metric_alert" "connect-time" {
#   count = local.enable_monitoring ? 1 : 0

#   name                = "${local.resource_prefix}alert-conn"
#   resource_group_name = local.resource_group.name
#   scopes = [ azapi_resource.default.id ]
#   description = "Action will be triggered when revision count is less than 1"
#   window_size = "PT5M"
#   frequency   = "PT1M"

#   criteria {
#     metric_namespace = "Microsoft.App/containerApps"
#     metric_name      = "ReplicaCount"
#     aggregation      = "Count"
#     operator         = "LessThan"
#     threshold        = 1
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.main.id
#   }

#   tags                = local.tags
# }

# resource "azurerm_monitor_activity_log_alert" "health" {
#   name                = var.alert_appgw_health[terraform.workspace]
#   resource_group_name = data.azurerm_resource_group.rg.name
#   # scopes              = [azurerm_application_gateway.appgw.id]
#   description = "Action will be triggered when backend health is bad"

#   criteria {
#     category = "ResourceHealth"

#     resource_health {
#       current  = ["Degraded", "Unavailable"]
#       previous = ["Available"]
#       reason   = ["PlatformInitiated", "Unknown"]
#     }
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.main.id
#   }

#   tags = data.azurerm_resource_group.rg.tags
# }

# resource "azurerm_monitor_metric_alert" "container-cpu" {
#   name                = var.alert_container_cpu[terraform.workspace]
#   resource_group_name = data.azurerm_resource_group.rg.name
#   # scopes              = [azurerm_service_plan.service-plan.id]
#   description = "Action will be triggered when CPU percentage is greater than 50%"
#   window_size = "PT5M"
#   frequency   = "PT1M"

#   # criteria {
#   #   metric_namespace = "Microsoft.Web/serverfarms"
#   #   metric_name      = "CpuPercentage"
#   #   aggregation      = "Average"
#   #   operator         = "GreaterThan"
#   #   threshold        = 50
#   # }

#   action {
#     action_group_id = azurerm_monitor_action_group.main.id
#   }

#   tags = data.azurerm_resource_group.rg.tags
# }

# resource "azurerm_monitor_metric_alert" "container-avg-resp-time" {
#   name                = var.alert_container_avg_resp_time[terraform.workspace]
#   resource_group_name = data.azurerm_resource_group.rg.name
#   # scopes              = [azurerm_linux_web_app.linux-web-app.id]
#   description = "Action will be triggered when container average response time is greater than 1000ms"
#   window_size = "PT5M"
#   frequency   = "PT1M"

#   # criteria {
#   #   metric_namespace = "Microsoft.Web/sites"
#   #   metric_name      = "AverageResponseTime"
#   #   aggregation      = "Average"
#   #   operator         = "GreaterThan"
#   #   threshold        = 1000
#   # }

#   action {
#     action_group_id = azurerm_monitor_action_group.main.id
#   }

#   tags = data.azurerm_resource_group.rg.tags
# }

# resource "azurerm_monitor_metric_alert" "failed-requests" {
#   name                = var.alert_failed_requests[terraform.workspace]
#   resource_group_name = data.azurerm_resource_group.rg.name
#   # scopes              = [data.azurerm_application_insights.appinsights.id]
#   description = "Action will be triggered when failed requests is greater than 1"
#   window_size = "PT5M"
#   frequency   = "PT1M"

#   # criteria {
#   #   metric_namespace = "microsoft.insights/components"
#   #   metric_name      = "requests/failed"
#   #   aggregation      = "Count"
#   #   operator         = "GreaterThan"
#   #   threshold        = 1
#   # }

#   action {
#     action_group_id = azurerm_monitor_action_group.main.id
#   }

#   tags = data.azurerm_resource_group.rg.tags
# }