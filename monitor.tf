resource "azurerm_application_insights" "main" {
  name                = "${local.resource_prefix}-insights"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.container_app.id
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_application_insights_standard_web_test" "main" {
  count = local.enable_monitoring ? 1 : 0

  name                    = "${local.resource_prefix}-http"
  resource_group_name     = local.resource_group.name
  location                = local.resource_group.location
  application_insights_id = azurerm_application_insights.main.id
  timeout                 = 10
  description             = "Regional HTTP availability check"
  enabled                 = true

  geo_locations = slice(data.azurerm_extended_locations.geo_locations.extended_locations, 0, 3) # Use 3 locations

  request {
    url = local.monitor_http_availability_url

    header {
      name  = "X-AppInsights-HttpTest"
      value = azurerm_application_insights.main.name
    }
  }

  tags = merge(
    local.tags,
    { "hidden-link:${azurerm_application_insights.main.id}" = "Resource" },
  )
}

resource "azurerm_application_insights_standard_web_test" "tls" {
  count = local.enable_monitoring && local.monitor_tls_expiry ? 1 : 0

  name                    = "${local.resource_prefix}-tls"
  resource_group_name     = local.resource_group.name
  location                = local.resource_group.location
  application_insights_id = azurerm_application_insights.main.id
  timeout                 = 60
  frequency               = 900 # Interval in seconds to test. (15 mins)
  retry_enabled           = true
  description             = "TLS certificate validity check"
  enabled                 = true

  geo_locations = slice(data.azurerm_extended_locations.geo_locations.extended_locations, 0, 1) # Use 1 location

  request {
    url                              = local.monitor_http_availability_url
    parse_dependent_requests_enabled = false

    header {
      name  = "X-AppInsights-TlsExpiryTest"
      value = azurerm_application_insights.main.name
    }
  }

  validation_rules {
    ssl_cert_remaining_lifetime = local.alarm_tls_expiry_days_remaining
    ssl_check_enabled           = true
  }

  tags = merge(
    local.tags,
    { "hidden-link:${azurerm_application_insights.main.id}" = "Resource" },
  )
}

resource "azurerm_monitor_action_group" "main" {
  count = local.enable_monitoring ? 1 : 0

  name                = "${local.resource_prefix}-actiongroup"
  resource_group_name = local.resource_group.name
  short_name          = local.project_name
  tags                = local.tags

  dynamic "email_receiver" {
    for_each = local.monitor_email_receivers

    content {
      name                    = "Email ${email_receiver.value}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  dynamic "event_hub_receiver" {
    for_each = local.enable_event_hub ? [0] : []

    content {
      name                    = "Event Hub"
      event_hub_name          = azurerm_eventhub.container_app[0].name
      event_hub_namespace     = azurerm_eventhub_namespace.container_app[0].id
      subscription_id         = data.azurerm_subscription.current.subscription_id
      use_common_alert_schema = true
    }
  }

  dynamic "logic_app_receiver" {
    for_each = local.enable_monitoring || local.existing_logic_app_workflow.name != "" ? [0] : []

    content {
      name                    = local.monitor_logic_app_receiver.name
      resource_id             = local.monitor_logic_app_receiver.resource_id
      callback_url            = local.monitor_logic_app_receiver.callback_url
      use_common_alert_schema = true
    }
  }
}

resource "azurerm_monitor_metric_alert" "cpu" {
  for_each = local.enable_monitoring ? local.monitor_container_ids : {}

  name                = "${element(split("/", each.value), length(split("/", each.value)) - 1)}-cpu"
  resource_group_name = local.resource_group.name
  scopes              = [each.value]
  description         = "Action will be triggered when CPU usage is higher than a defined threshold for longer than 5 minutes"
  window_size         = "PT5M"
  frequency           = "PT5M"
  severity            = 2

  criteria {
    metric_namespace = "microsoft.app/containerapps"
    metric_name      = "UsageNanoCores"
    aggregation      = "Average"
    operator         = "GreaterThan"
    # CPU usage in nanocores (1,000,000,000 nanocores = 1 core)
    threshold = ((local.container_cpu * 10000000) * local.alarm_cpu_threshold_percentage)
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "memory" {
  for_each = local.enable_monitoring ? local.monitor_container_ids : {}

  name                = "${element(split("/", each.value), length(split("/", each.value)) - 1)}-memory"
  resource_group_name = local.resource_group.name
  scopes              = [each.value]
  description         = "Action will be triggered when memory usage is higher than a defined threshold for longer than 5 minutes"
  window_size         = "PT5M"
  frequency           = "PT5M"
  severity            = 2

  criteria {
    metric_namespace = "microsoft.app/containerapps"
    metric_name      = "WorkingSetBytes"
    aggregation      = "Average"
    operator         = "GreaterThan"
    # Memory usage in bytes (1,000,000,000 bytes = 1 GB)
    threshold = ((local.container_memory * 10000000) * local.alarm_memory_threshold_percentage)
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "exceptions" {
  count = local.enable_monitoring ? 1 : 0

  name                = "${azurerm_application_insights.main.name}-exceptions"
  resource_group_name = local.resource_group.name
  scopes              = [azurerm_application_insights.main.id]
  description         = "Action will be triggered when the number of exceptions exceeds 0"
  window_size         = "PT5M"
  frequency           = "PT1M"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Insights/components"
    metric_name      = "exceptions/count"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "http" {
  count = local.enable_monitoring ? 1 : 0

  name                = "${local.resource_prefix}-http"
  resource_group_name = local.resource_group.name
  # Scope requires web test to come first
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/8551
  scopes      = [azurerm_application_insights_standard_web_test.main[0].id, azurerm_application_insights.main.id]
  description = "Action will be triggered when regional availability becomes impacted."
  severity    = 2

  application_insights_web_test_location_availability_criteria {
    web_test_id           = azurerm_application_insights_standard_web_test.main[0].id
    component_id          = azurerm_application_insights.main.id
    failed_location_count = 2 # 2 out of 3 locations
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "tls" {
  count = local.enable_monitoring && local.monitor_tls_expiry ? 1 : 0

  name                = "${local.resource_prefix}-tls"
  resource_group_name = local.resource_group.name
  # Scope requires web test to come first
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/8551
  scopes      = [azurerm_application_insights_standard_web_test.tls[0].id, azurerm_application_insights.main.id]
  description = "Action will be triggered when the TLS certificate expires in ${local.alarm_tls_expiry_days_remaining} days or less"
  severity    = 2

  application_insights_web_test_location_availability_criteria {
    web_test_id           = azurerm_application_insights_standard_web_test.tls[0].id
    component_id          = azurerm_application_insights.main.id
    failed_location_count = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "count" {
  for_each = local.enable_monitoring ? local.monitor_container_ids : {}

  name                = "${element(split("/", each.value), length(split("/", each.value)) - 1)}-replicas"
  resource_group_name = local.resource_group.name
  scopes              = [each.value]
  description         = "Action will be triggered when container count is zero"
  window_size         = "PT5M"
  frequency           = "PT1M"
  severity            = 1

  criteria {
    metric_namespace = "microsoft.app/containerapps"
    metric_name      = "Replicas"
    aggregation      = "Maximum"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "redis" {
  count = local.enable_monitoring && local.enable_redis_cache ? 1 : 0

  name                = "${azurerm_redis_cache.default[0].name}-cpu"
  resource_group_name = local.resource_group.name
  scopes              = [azurerm_redis_cache.default[0].id]
  description         = "Action will be triggered when Redis Server Load is higher than 80%"
  window_size         = "PT5M"
  frequency           = "PT1M"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Cache/Redis"
    metric_name      = "allserverLoad"
    aggregation      = "Average"
    operator         = "GreaterThan"
    # Number used as %
    threshold = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "latency" {
  count = local.enable_monitoring && local.enable_cdn_frontdoor ? 1 : 0

  name                = "${azurerm_cdn_frontdoor_profile.cdn[0].name}-latency"
  resource_group_name = local.resource_group.name
  scopes              = [azurerm_cdn_frontdoor_profile.cdn[0].id]
  description         = "Action will be triggered when Origin latency is higher than ${local.alarm_latency_threshold_ms}ms"
  window_size         = "PT5M"
  frequency           = "PT5M"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Cdn/profiles"
    metric_name      = "TotalLatency"
    aggregation      = "Minimum"
    operator         = "GreaterThan"
    # 1,000ms = 1s
    threshold = local.alarm_latency_threshold_ms
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "log-analytics-ingestion" {
  count = local.enable_monitoring && local.alarm_log_ingestion_gb_per_day != 0 ? 1 : 0

  name                = "${azurerm_log_analytics_workspace.container_app.name}-log-ingestion"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location

  criteria {
    operator                = "GreaterThan"
    query                   = "Usage | where IsBillable | summarize DataGB = sum(Quantity / 1000)"
    threshold               = local.alarm_log_ingestion_gb_per_day
    time_aggregation_method = "Total"
    metric_measure_column   = "DataGB"
  }

  evaluation_frequency = "P1D"
  scopes               = [azurerm_log_analytics_workspace.container_app.id]
  severity             = 2
  window_duration      = "P1D"

  action {
    action_groups = [azurerm_monitor_action_group.main[0].id]
  }

  description = "Action will be triggered when log ingestion reaches more than ${local.alarm_log_ingestion_gb_per_day}GB/day"
  tags        = local.tags
}
