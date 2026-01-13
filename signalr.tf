resource "azurerm_signalr_service" "default" {
  count = local.enable_signalr ? 1 : 0

  name                = "${local.resource_prefix}-signalr"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  sku {
    name     = local.signalr_sku
    capacity = 1
  }

  live_trace {
    connectivity_logs_enabled = true
    enabled                   = false
    http_request_logs_enabled = true
    messaging_logs_enabled    = true
  }

  service_mode = local.signalr_service_mode
}
