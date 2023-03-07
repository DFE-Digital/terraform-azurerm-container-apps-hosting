resource "azurerm_logic_app_workflow" "webhook" {
  count = local.enable_monitoring ? 1 : 0

  name                = "${local.resource_prefix}-webhook-workflow"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  tags = local.tags
}

resource "azurerm_logic_app_trigger_http_request" "webhook" {
  count = local.enable_monitoring ? 1 : 0

  depends_on = [
    azurerm_logic_app_workflow.webhook[0]
  ]

  name         = "${local.resource_prefix}-trigger"
  logic_app_id = azurerm_logic_app_workflow.webhook[0].id

  schema = templatefile("${path.module}/schema/common-alert-schema.json", {})
}

resource "azurerm_logic_app_action_http" "slack" {
  count = local.enable_monitoring && local.monitor_enable_slack_webhook && length(local.monitor_slack_webhook_receiver) > 0 ? 1 : 0

  depends_on = [
    azurerm_logic_app_workflow.webhook[0]
  ]

  name         = "${local.resource_prefix}-action"
  logic_app_id = azurerm_logic_app_workflow.webhook[0].id
  method       = "POST"
  uri          = local.monitor_slack_webhook_receiver
  headers = {
    "Content-Type" : "application/json"
  }

  body = templatefile(
    "${path.module}/webhook/slack.json",
    {
      channel = local.monitor_slack_channel
    }
  )
}

resource "azurerm_monitor_diagnostic_setting" "webhook" {
  count = local.enable_monitoring ? 1 : 0

  depends_on = [
    azurerm_logic_app_workflow.webhook[0]
  ]

  name               = "${local.resource_prefix}-webhook-diag"
  target_resource_id = azurerm_logic_app_workflow.webhook[0].id

  log_analytics_workspace_id     = azurerm_log_analytics_workspace.container_app.id
  log_analytics_destination_type = "Dedicated"

  eventhub_name = local.enable_event_hub ? azurerm_eventhub.container_app[0].name : null

  enabled_log {
    category = "WorkflowRuntime"

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = 7
    }
  }
}
