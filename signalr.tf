resource "azurerm_signalr_service" "default" {
  count = local.enable_signalr ? 1 : 0

  name                = "${local.resource_prefix}-signalr"
  location            = azurerm_resource_group.default[0].location
  resource_group_name = azurerm_resource_group.default[0].name

  sku {
    name     = local.signalr_sku
    capacity = 1
  }

  service_mode = "Serverless"
}
