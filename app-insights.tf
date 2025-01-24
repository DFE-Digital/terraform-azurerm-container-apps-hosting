resource "azurerm_application_insights" "main" {
  count = local.enable_app_insights_integration ? 1 : 0

  name                = "${local.resource_prefix}-insights"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.app_insights[0].id
  retention_in_days   = local.app_insights_retention_days
  tags                = local.tags
}

resource "azurerm_application_insights" "function_apps" {
  for_each = local.enable_app_insights_integration ? merge(local.linux_function_apps, local.linux_function_health_insights_api) : {}

  name                = "${local.resource_prefix}-${each.key}-insights"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.app_insights[0].id
  retention_in_days   = local.app_insights_retention_days
  tags                = local.tags
}

resource "azurerm_log_analytics_workspace" "app_insights" {
  count = local.enable_app_insights_integration ? 1 : 0

  name                = "${local.resource_prefix}-insights"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = local.app_insights_retention_days
  tags                = local.tags
}

resource "azurerm_application_insights_standard_web_test" "main" {
  count = local.enable_app_insights_integration && local.enable_monitoring ? 1 : 0

  name                    = "${local.resource_prefix}-http"
  resource_group_name     = local.resource_group.name
  location                = local.resource_group.location
  application_insights_id = azurerm_application_insights.main[0].id
  timeout                 = 10
  description             = "Regional HTTP availability check"
  enabled                 = true
  retry_enabled           = true

  geo_locations = [
    "emea-nl-ams-azr",  # West Europe
    "emea-se-sto-edge", # UK West
    "emea-ru-msa-edge"  # UK South
  ]

  request {
    url       = local.monitor_http_availability_url
    http_verb = local.monitor_http_availability_verb

    header {
      name  = "X-AppInsights-HttpTest"
      value = azurerm_application_insights.main[0].name
    }
  }

  validation_rules {
    expected_status_code = 0 # 0 = response code < 400
  }

  tags = merge(
    local.tags,
    { "hidden-link:${azurerm_application_insights.main[0].id}" = "Resource" },
  )
}
