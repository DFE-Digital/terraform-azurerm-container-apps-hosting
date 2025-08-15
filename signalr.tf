resource "azurerm_signalr_service" "default" {
  count = local.enable_signalr ? 1 : 0

  name                = "${local.resource_prefix}-signalr"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  sku {
    name     = local.signalr_sku
    capacity = 1
  }

  service_mode = "Serverless"
}
