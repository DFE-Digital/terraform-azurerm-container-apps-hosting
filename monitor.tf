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
    for_each = local.existing_logic_app_workflow.name != "" ? [0] : []

    content {
      name                    = local.monitor_logic_app_receiver.name
      resource_id             = local.monitor_logic_app_receiver.resource_id
      callback_url            = local.monitor_logic_app_receiver.callback_url
      use_common_alert_schema = true
    }
  }
}

resource "azurerm_monitor_metric_alert" "cpu" {
  for_each = local.enable_monitoring ? local.monitor_containers : {}

  name                = "Container App CPU - ${each.value.name}"
  resource_group_name = local.resource_group.name
  scopes              = [each.value.id]
  description         = "Container App ${each.value.name} is consuming more than ${local.alarm_cpu_threshold_percentage}% of CPU"
  window_size         = "PT5M"
  frequency           = "PT5M"
  severity            = 2 # Warning

  criteria {
    metric_namespace = "microsoft.app/containerapps"
    metric_name      = "UsageNanoCores"
    aggregation      = "Average"
    operator         = "GreaterThan"
    # CPU usage in nanocores (1,000,000,000 nanocores = 1 core)
    threshold = ((each.value.template[0].container[0].cpu * 10000000) * local.alarm_cpu_threshold_percentage)
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "memory" {
  for_each = local.enable_monitoring ? local.monitor_containers : {}

  name                = "Container App Memory - ${each.value.name}"
  resource_group_name = local.resource_group.name
  scopes              = [each.value.id]
  description         = "Container App ${each.value.name} is consuming more than ${local.alarm_memory_threshold_percentage}% of Memory"
  window_size         = "PT5M"
  frequency           = "PT5M"
  severity            = 2 # Warning

  criteria {
    metric_namespace = "microsoft.app/containerapps"
    metric_name      = "WorkingSetBytes"
    aggregation      = "Average"
    operator         = "GreaterThan"
    # Memory usage in bytes (1,000,000,000 bytes = 1 GB)
    threshold = ((replace(each.value.template[0].container[0].memory, "Gi", "") * 10000000) * local.alarm_memory_threshold_percentage)
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "count" {
  for_each = local.enable_monitoring ? local.monitor_containers : {}

  name                = "Container App Replica Count - ${each.value.name}"
  resource_group_name = local.resource_group.name
  scopes              = [each.value.id]
  description         = "Container App ${each.value.name} has less than ${each.value.template[0].min_replicas} replicas"
  window_size         = "PT5M"
  frequency           = "PT1M"
  severity            = 1 # Error

  criteria {
    metric_namespace = "microsoft.app/containerapps"
    metric_name      = "Replicas"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = each.value.template[0].min_replicas
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "sql_cpu" {
  count = local.enable_monitoring && local.enable_mssql_database ? 1 : 0

  name                = "SQL Database CPU - ${azurerm_mssql_database.default[0].name}"
  resource_group_name = local.resource_group.name
  scopes              = [azurerm_mssql_database.default[0].id]
  description         = "SQL Database ${azurerm_mssql_server.default[0].name}/${azurerm_mssql_database.default[0].name} is consuming more than 80% of CPU"
  window_size         = "PT5M"
  frequency           = "PT5M"
  severity            = 2 # Warning

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "sql_dtu" {
  count = local.enable_monitoring && local.enable_mssql_database ? 1 : 0

  name                = "SQL Database DTU - ${azurerm_mssql_database.default[0].name}"
  resource_group_name = local.resource_group.name
  scopes              = [azurerm_mssql_database.default[0].id]
  description         = "SQL Database ${azurerm_mssql_server.default[0].name}/${azurerm_mssql_database.default[0].name} is consuming more than 80% of available DTUs"
  window_size         = "PT5M"
  frequency           = "PT5M"
  severity            = 2 # Warning

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "dtu_consumption_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_smart_detector_alert_rule" "ai_smart_failures" {
  count = local.enable_monitoring && local.enable_app_insights_integration && local.app_insights_smart_detection_enabled ? 1 : 0

  name                = "Failure Anomalies - ${azurerm_application_insights.main[0].name}"
  description         = "Failure Anomalies notifies you of an unusual rise in the rate of failed HTTP requests or dependency calls."
  resource_group_name = local.resource_group.name
  severity            = "Sev2" # Warning
  scope_resource_ids  = [azurerm_application_insights.main[0].id]
  frequency           = "PT1M"
  detector_type       = "FailureAnomaliesDetector"

  action_group {
    ids = [azurerm_monitor_action_group.main[0].id]
  }

  tags = local.tags
}

resource "azurerm_monitor_smart_detector_alert_rule" "ai_smart_performance_degradation" {
  count = local.enable_monitoring && local.enable_app_insights_integration && local.app_insights_smart_detection_enabled ? 1 : 0

  name                = "Request Performance Degradation - ${azurerm_application_insights.main[0].name}"
  description         = "Request Performance Degradation notifies you when your app has started responding to requests more slowly than it used to."
  resource_group_name = local.resource_group.name
  severity            = "Sev2" # Warning
  scope_resource_ids  = [azurerm_application_insights.main[0].id]
  frequency           = "P1D"
  detector_type       = "RequestPerformanceDegradationDetector"

  action_group {
    ids = [azurerm_monitor_action_group.main[0].id]
  }

  tags = local.tags
}

resource "azurerm_monitor_smart_detector_alert_rule" "ai_smart_dependency_degradation" {
  count = local.enable_monitoring && local.enable_app_insights_integration && local.app_insights_smart_detection_enabled ? 1 : 0

  name                = "Dependency Performance Degradation - ${azurerm_application_insights.main[0].name}"
  description         = "Dependency Performance Degradation notifies you when your app makes calls to a REST API, database, or other dependency. The dependency is responding more slowly than it used to."
  resource_group_name = local.resource_group.name
  severity            = "Sev2" # Warning
  scope_resource_ids  = [azurerm_application_insights.main[0].id]
  frequency           = "P1D"
  detector_type       = "DependencyPerformanceDegradationDetector"

  action_group {
    ids = [azurerm_monitor_action_group.main[0].id]
  }

  tags = local.tags
}

resource "azurerm_monitor_smart_detector_alert_rule" "ai_smart_exception_volume" {
  count = local.enable_monitoring && local.enable_app_insights_integration && local.app_insights_smart_detection_enabled ? 1 : 0

  name                = "Exception Volume Changed - ${azurerm_application_insights.main[0].name}"
  description         = "Exception Volume Changed notifies you when your app is showing an abnormal rise in the number of exceptions of a specific type, during a day."
  resource_group_name = local.resource_group.name
  severity            = "Sev2" # Warning
  scope_resource_ids  = [azurerm_application_insights.main[0].id]
  frequency           = "P1D"
  detector_type       = "ExceptionVolumeChangedDetector"

  action_group {
    ids = [azurerm_monitor_action_group.main[0].id]
  }

  tags = local.tags
}

resource "azurerm_monitor_smart_detector_alert_rule" "ai_smart_trace_severity" {
  count = local.enable_monitoring && local.enable_app_insights_integration && local.app_insights_smart_detection_enabled ? 1 : 0

  name                = "Trace Severity - ${azurerm_application_insights.main[0].name}"
  description         = "Trace Severity notifies you if the ratio between “good” traces (traces logged with a level of Info or Verbose) and “bad” traces (traces logged with a level of Warning, Error, or Fatal) is degrading in a specific day."
  resource_group_name = local.resource_group.name
  severity            = "Sev2" # Warning
  scope_resource_ids  = [azurerm_application_insights.main[0].id]
  frequency           = "P1D"
  detector_type       = "TraceSeverityDetector"

  action_group {
    ids = [azurerm_monitor_action_group.main[0].id]
  }

  tags = local.tags
}

resource "azurerm_monitor_smart_detector_alert_rule" "ai_smart_memory_leak" {
  count = local.enable_monitoring && local.enable_app_insights_integration && local.app_insights_smart_detection_enabled ? 1 : 0

  name                = "Memory Leak - ${azurerm_application_insights.main[0].name}"
  description         = "Memory Leak analyzes the memory consumption of each process in your application. It can warn you about potential memory leaks or increased memory consumption."
  resource_group_name = local.resource_group.name
  severity            = "Sev2" # Warning
  scope_resource_ids  = [azurerm_application_insights.main[0].id]
  frequency           = "P1D"
  detector_type       = "MemoryLeakDetector"

  action_group {
    ids = [azurerm_monitor_action_group.main[0].id]
  }

  tags = local.tags
}

resource "azurerm_application_insights_smart_detection_rule" "ai_slow_page" {
  count = local.enable_app_insights_integration ? 1 : 0

  name                               = "Slow page load time"
  application_insights_id            = azurerm_application_insights.main[0].id
  additional_email_recipients        = local.monitor_email_receivers
  send_emails_to_subscription_owners = false
  enabled                            = local.app_insights_smart_detection_enabled
}

resource "azurerm_application_insights_smart_detection_rule" "ai_slow_server" {
  count = local.enable_app_insights_integration ? 1 : 0

  name                               = "Slow server response time"
  application_insights_id            = azurerm_application_insights.main[0].id
  additional_email_recipients        = local.monitor_email_receivers
  send_emails_to_subscription_owners = false
  enabled                            = local.app_insights_smart_detection_enabled
}

resource "azurerm_application_insights_smart_detection_rule" "ai_memory" {
  count = local.enable_app_insights_integration ? 1 : 0

  name                               = "Potential memory leak detected"
  application_insights_id            = azurerm_application_insights.main[0].id
  additional_email_recipients        = local.monitor_email_receivers
  send_emails_to_subscription_owners = false
  enabled                            = local.app_insights_smart_detection_enabled
}

resource "azurerm_application_insights_smart_detection_rule" "ai_security" {
  count = local.enable_app_insights_integration ? 1 : 0

  name                               = "Potential security issue detected"
  application_insights_id            = azurerm_application_insights.main[0].id
  additional_email_recipients        = local.monitor_email_receivers
  send_emails_to_subscription_owners = false
  enabled                            = local.app_insights_smart_detection_enabled
}

resource "azurerm_application_insights_smart_detection_rule" "ai_trace" {
  count = local.enable_app_insights_integration ? 1 : 0

  name                               = "Degradation in trace severity ratio"
  application_insights_id            = azurerm_application_insights.main[0].id
  additional_email_recipients        = local.monitor_email_receivers
  send_emails_to_subscription_owners = false
  enabled                            = local.app_insights_smart_detection_enabled
}

resource "azurerm_application_insights_smart_detection_rule" "ai_long_dependency_duration" {
  count = local.enable_app_insights_integration ? 1 : 0

  name                               = "Long dependency duration"
  application_insights_id            = azurerm_application_insights.main[0].id
  additional_email_recipients        = local.monitor_email_receivers
  send_emails_to_subscription_owners = false
  enabled                            = local.app_insights_smart_detection_enabled
}

resource "azurerm_application_insights_smart_detection_rule" "ai_response_time" {
  count = local.enable_app_insights_integration ? 1 : 0

  name                               = "Degradation in server response time"
  application_insights_id            = azurerm_application_insights.main[0].id
  additional_email_recipients        = local.monitor_email_receivers
  send_emails_to_subscription_owners = false
  enabled                            = local.app_insights_smart_detection_enabled
}

resource "azurerm_application_insights_smart_detection_rule" "ai_exception_volume" {
  count = local.enable_app_insights_integration ? 1 : 0

  name                               = "Abnormal rise in exception volume"
  application_insights_id            = azurerm_application_insights.main[0].id
  additional_email_recipients        = local.monitor_email_receivers
  send_emails_to_subscription_owners = false
  enabled                            = local.app_insights_smart_detection_enabled
}

resource "azurerm_application_insights_smart_detection_rule" "ai_dependency_duration" {
  count = local.enable_app_insights_integration ? 1 : 0

  name                               = "Degradation in dependency duration"
  application_insights_id            = azurerm_application_insights.main[0].id
  additional_email_recipients        = local.monitor_email_receivers
  send_emails_to_subscription_owners = false
  enabled                            = local.app_insights_smart_detection_enabled
}

resource "azurerm_application_insights_smart_detection_rule" "ai_data_volume" {
  count = local.enable_app_insights_integration ? 1 : 0

  name                               = "Abnormal rise in daily data volume"
  application_insights_id            = azurerm_application_insights.main[0].id
  additional_email_recipients        = local.monitor_email_receivers
  send_emails_to_subscription_owners = false
  enabled                            = local.app_insights_smart_detection_enabled
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "exceptions" {
  count = local.enable_monitoring && local.enable_app_insights_integration ? 1 : 0

  name                 = "Exceptions Count - ${azurerm_application_insights.main[0].name}"
  resource_group_name  = local.resource_group.name
  location             = local.resource_group.location
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  scopes               = [azurerm_application_insights.main[0].id]
  severity             = 2 # Warning
  description          = "Action will be triggered when an Exception is raised in App Insights"

  criteria {
    query = <<-QUERY
      exceptions
        | where isnotempty(operation_Name)
        | join requests on $left.operation_Id == $right.operation_Id
        | where toint(severityLevel) >= 2
        | extend severity = case(
            severityLevel == 4, "Fatal",
            severityLevel == 3, "Error",
            severityLevel == 2, "Warning",
            "Unknown" // Default case
        )
        | extend message = strcat(type, ": ", outerMessage)
        | extend linkToAppInsights = strcat(
            "https://portal.azure.com/#blade/AppInsightsExtension/DetailsV2Blade/DataModel/",
            url_encode(strcat('{"eventId":"', itemId, '","timestamp":"', timestamp, '"}')),
            "/ComponentId/",
            url_encode(strcat('{"Name":"', split(appName, "/", 8)[0], '","ResourceGroup":"', split(appName, "/", 4)[0], '","SubscriptionId":"', split(appName, "/", 2)[0], '"}'))
        )
        | project operation_Id, timestamp, operation_Name, message, severity, url, resultCode, linkToAppInsights
        | order by timestamp desc
      QUERY

    time_aggregation_method = "Count"
    threshold               = 1
    operator                = "GreaterThanOrEqual"

    // Keep dimensions ordered by 'name' as that is how they will be presented
    // in the Common Alert Schema
    dimension {
      name     = "linkToAppInsights"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "message"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "operation_Id"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "operation_Name"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "resultCode"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "severity"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "url"
      operator = "Include"
      values   = ["*"]
    }

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  auto_mitigation_enabled = false

  action {
    action_groups = [azurerm_monitor_action_group.main[0].id]
  }

  tags = local.tags
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "traces" {
  count = local.enable_monitoring && local.enable_monitoring_traces && local.enable_app_insights_integration ? 1 : 0

  name                 = "Error Count - ${azurerm_application_insights.main[0].name}"
  resource_group_name  = local.resource_group.name
  location             = local.resource_group.location
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes               = [azurerm_application_insights.main[0].id]
  severity             = 2 # Warning
  description          = "Action will be triggered when ${local.enable_monitoring_traces_include_warnings ? "warnings or " : ""}errors are detected in App Insights traces"

  criteria {
    query = <<-QUERY
      traces
        | where
            isempty(customDimensions.StatusCode) or
            (isnotempty(customDimensions.StatusCode) and customDimensions.StatusCode >= 500)
        | where isnotempty(operation_Name)
        | where severityLevel >= ${local.enable_monitoring_traces_include_warnings ? 2 : 3}
        | extend linkToAppInsights = strcat(
              "https://portal.azure.com/#blade/AppInsightsExtension/DetailsV2Blade/DataModel/",
              url_encode(strcat('{"eventId":"', itemId, '","timestamp":"', timestamp, '"}')),
              "/ComponentId/",
              url_encode(strcat('{"Name":"', split(appName, "/", 8)[0], '","ResourceGroup":"', split(appName, "/", 4)[0], '","SubscriptionId":"', split(appName, "/", 2)[0], '"}'))
            )
        | extend severity = case(
            severityLevel == 4, "Fatal",
            severityLevel == 3, "Error",
            severityLevel == 2, "Warning",
            "Unknown" // Default case
        )
        | join requests on $left.operation_Id == $right.operation_Id
        | project operation_Id, timestamp, operation_Name, message, severity, url, resultCode, linkToAppInsights
        | order by timestamp desc
      QUERY

    time_aggregation_method = "Count"
    threshold               = 1
    operator                = "GreaterThanOrEqual"

    // Keep dimensions ordered by 'name' as that is how they will be presented
    // in the Common Alert Schema
    dimension {
      name     = "linkToAppInsights"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "message"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "operation_Id"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "operation_Name"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "resultCode"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "severity"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "url"
      operator = "Include"
      values   = ["*"]
    }

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  auto_mitigation_enabled = false

  action {
    action_groups = [azurerm_monitor_action_group.main[0].id]
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "http" {
  count = local.enable_monitoring && local.enable_app_insights_integration ? 1 : 0

  name                = "HTTP Availability Test - ${azurerm_application_insights.main[0].name}"
  resource_group_name = local.resource_group.name
  # Scope requires web test to come first
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/8551
  scopes      = [azurerm_application_insights_standard_web_test.main[0].id, azurerm_application_insights.main[0].id]
  description = "HTTP URL ${local.monitor_http_availability_url} could not be reached by 2 out of 3 locations"
  severity    = 0 # Critical

  application_insights_web_test_location_availability_criteria {
    web_test_id           = azurerm_application_insights_standard_web_test.main[0].id
    component_id          = azurerm_application_insights.main[0].id
    failed_location_count = 2 # 2 out of 3 locations
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "redis" {
  count = local.enable_monitoring && local.enable_redis_cache ? 1 : 0

  name                = "Azure Cache for Redis CPU - ${azurerm_redis_cache.default[0].name}"
  resource_group_name = local.resource_group.name
  scopes              = [azurerm_redis_cache.default[0].id]
  description         = "Azure Cache for Redis ${azurerm_redis_cache.default[0].name} is consuming more than 80% of CPU"
  window_size         = "PT5M"
  frequency           = "PT1M"
  severity            = 2 # Warning

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

  name                = "Azure Front Door Total Latency - ${azurerm_cdn_frontdoor_profile.cdn[0].name}"
  resource_group_name = local.resource_group.name
  scopes              = [azurerm_cdn_frontdoor_profile.cdn[0].id]
  description         = "Azure Front Door ${azurerm_cdn_frontdoor_profile.cdn[0].name} total latency is greater than ${local.alarm_latency_threshold_ms / 1000}s"
  window_size         = "PT5M"
  frequency           = "PT5M"
  severity            = 2 # Warning

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

  name                = "Log Ingestion Rate - ${azurerm_log_analytics_workspace.container_app.name}"
  description         = "${azurerm_log_analytics_workspace.container_app.name} log ingestion reaches more than ${local.alarm_log_ingestion_gb_per_day}GB/day"
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
  severity             = 2 # Warning
  window_duration      = "P1D"

  action {
    action_groups = [azurerm_monitor_action_group.main[0].id]
  }

  tags = local.tags
}

resource "azurerm_monitor_activity_log_alert" "delete_container_app" {
  for_each = local.enable_monitoring && local.alarm_for_delete_events ? merge(azurerm_container_app.container_apps, azurerm_container_app.custom_container_apps) : {}

  name                = "Resource Deletion - Container App - ${each.value.name}"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  scopes              = [local.resource_group.id]
  description         = "Delete Resource event started for Container App ${each.value.name}"

  criteria {
    resource_id    = each.value.id
    operation_name = "microsoft.app/containerapps/delete"
    category       = "Administrative"
    statuses       = ["Started"]
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_activity_log_alert" "delete_sql_database" {
  count = local.enable_monitoring && local.alarm_for_delete_events && local.enable_mssql_database ? 1 : 0

  name                = "Resource Deletion - SQL Database - ${azurerm_mssql_database.default[0].name}"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  scopes              = [local.resource_group.id]
  description         = "Delete Resource event started for SQL Database ${azurerm_mssql_database.default[0].name}"

  criteria {
    resource_id    = azurerm_mssql_database.default[0].id
    operation_name = "microsoft.sql/servers/databases/delete"
    category       = "Administrative"
    statuses       = ["Started"]
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_activity_log_alert" "delete_dns_zone" {
  count = local.enable_monitoring && local.alarm_for_delete_events && local.enable_dns_zone ? 1 : 0

  name                = "Resource Deletion - DNS Zone - ${azurerm_dns_zone.default[0].name}"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  scopes              = [local.resource_group.id]
  description         = "Delete Resource event started for DNS Zone ${azurerm_dns_zone.default[0].name}"

  criteria {
    resource_id    = azurerm_dns_zone.default[0].id
    operation_name = "microsoft.network/dnszones/delete"
    category       = "Administrative"
    statuses       = ["Started"]
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_activity_log_alert" "delete_redis_cache" {
  count = local.enable_monitoring && local.alarm_for_delete_events && local.enable_redis_cache ? 1 : 0

  name                = "Resource Deletion - Redis Cache - ${azurerm_redis_cache.default[0].name}"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  scopes              = [local.resource_group.id]
  description         = "Delete Resource event started for Redis Cache ${azurerm_redis_cache.default[0].name}"

  criteria {
    resource_id    = azurerm_redis_cache.default[0].id
    operation_name = "microsoft.cache/redis/delete"
    category       = "Administrative"
    statuses       = ["Started"]
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_activity_log_alert" "delete_postgresql_database" {
  count = local.enable_monitoring && local.alarm_for_delete_events && local.enable_postgresql_database ? 1 : 0

  name                = "Resource Deletion - PostgreSQL Database - ${azurerm_postgresql_flexible_server_database.default[0].name}"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  scopes              = [local.resource_group.id]
  description         = "Delete Resource event started for PostgreSQL Database ${azurerm_postgresql_flexible_server_database.default[0].name}"

  criteria {
    resource_id    = azurerm_postgresql_flexible_server_database.default[0].id
    operation_name = "microsoft.dbforpostgresql/servers/databases/delete"
    category       = "Administrative"
    statuses       = ["Started"]
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_activity_log_alert" "delete_frontdoor_cdn" {
  count = local.enable_monitoring && local.alarm_for_delete_events && local.enable_cdn_frontdoor ? 1 : 0

  name                = "Resource Deletion - Front Door - ${azurerm_cdn_frontdoor_profile.cdn[0].name}"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  scopes              = [local.resource_group.id]
  description         = "Delete Resource event started for Front Door ${azurerm_cdn_frontdoor_profile.cdn[0].name}"

  criteria {
    resource_id    = azurerm_cdn_frontdoor_profile.cdn[0].id
    operation_name = "microsoft.cdn/profiles/delete"
    category       = "Administrative"
    statuses       = ["Started"]
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_activity_log_alert" "delete_vnet" {
  count = local.enable_monitoring && local.alarm_for_delete_events && local.launch_in_vnet ? 1 : 0

  name                = "Resource Deletion - Virtual Network - ${local.virtual_network.name}"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  scopes              = [local.resource_group.id]
  description         = "Delete Resource event started for Virtual Network ${local.virtual_network.name}"

  criteria {
    resource_id    = local.virtual_network.id
    operation_name = "microsoft.network/virtualnetworks/delete"
    category       = "Administrative"
    statuses       = ["Started"]
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.tags
}
