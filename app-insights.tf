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
    url = local.monitor_http_availability_url

    header {
      name  = "X-AppInsights-HttpTest"
      value = azurerm_application_insights.main[0].name
    }
  }

  tags = merge(
    local.tags,
    { "hidden-link:${azurerm_application_insights.main[0].id}" = "Resource" },
  )
}

resource "azurerm_application_insights_standard_web_test" "tls" {
  count = local.enable_app_insights_integration && local.enable_monitoring && local.monitor_tls_expiry ? 1 : 0

  name                    = "${local.resource_prefix}-tls"
  resource_group_name     = local.resource_group.name
  location                = local.resource_group.location
  application_insights_id = azurerm_application_insights.main[0].id
  timeout                 = 60
  frequency               = 900 # Interval in seconds to test. (15 mins)
  retry_enabled           = true
  description             = "TLS certificate validity check"
  enabled                 = true

  geo_locations = ["emea-nl-ams-azr"] # West Europe

  request {
    url                              = local.monitor_http_availability_url
    parse_dependent_requests_enabled = false

    header {
      name  = "X-AppInsights-TlsExpiryTest"
      value = azurerm_application_insights.main[0].name
    }
  }

  validation_rules {
    ssl_cert_remaining_lifetime = local.alarm_tls_expiry_days_remaining
    ssl_check_enabled           = true
  }

  tags = merge(
    local.tags,
    { "hidden-link:${azurerm_application_insights.main[0].id}" = "Resource" },
  )
}
