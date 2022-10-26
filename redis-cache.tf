resource "azurerm_redis_cache" "default" {
  count = local.enable_redis_cache ? 1 : 0

  name                = "${local.resource_prefix}default"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  capacity            = local.redis_cache_capacity
  family              = local.redis_cache_family
  sku_name            = local.redis_cache_sku
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  public_network_access_enabled = local.launch_in_vnet ? (
    local.redis_cache_sku == "Premium" ? false : true
  ) : true
  subnet_id = local.launch_in_vnet ? (
    local.redis_cache_sku == "Premium" ? azurerm_subnet.redis_cache_subnet[0].id : null
  ) : null

  redis_configuration {
    enable_authentication = true
  }

  patch_schedule {
    day_of_week    = local.redis_cache_patch_schedule_day
    start_hour_utc = local.redis_cache_patch_schedule_hour
  }

  tags = local.tags
}

resource "azurerm_redis_firewall_rule" "container_app_default_static_ip" {
  count = local.enable_redis_cache ? 1 : 0

  name                = "${replace(local.resource_prefix, "-", "")}containerapp"
  redis_cache_name    = azurerm_redis_cache.default[0].name
  resource_group_name = local.resource_group.name
  start_ip            = jsondecode(azapi_resource.default.output).properties.outboundIpAddresses[0]
  end_ip              = jsondecode(azapi_resource.default.output).properties.outboundIpAddresses[0]
}

resource "azurerm_redis_firewall_rule" "container_app_worker_static_ip" {
  count = local.enable_redis_cache ? (
    local.enable_worker_container ? 1 : 0
  ) : 0

  name                = "${replace(local.resource_prefix, "-", "")}containerappworker"
  redis_cache_name    = azurerm_redis_cache.default[0].name
  resource_group_name = local.resource_group.name
  start_ip            = jsondecode(azapi_resource.worker[0].output).properties.outboundIpAddresses[0]
  end_ip              = jsondecode(azapi_resource.worker[0].output).properties.outboundIpAddresses[0]
}

resource "azurerm_private_endpoint" "default_redis_cache" {
  count = local.enable_redis_cache ? (
    local.launch_in_vnet ? (
      local.redis_cache_sku == "Premium" ? 1 : 0
    ) : 0
  ) : 0

  name                = "${local.resource_prefix}defaultrediscache"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  subnet_id           = azurerm_subnet.redis_cache_private_endpoint_subnet[0].id

  private_service_connection {
    name                           = "${local.resource_prefix}defaultrediscacheconnection"
    private_connection_resource_id = azurerm_redis_cache.default[0].id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }
  tags = local.tags
}

resource "azurerm_private_dns_a_record" "redis_cache_private_endpoint" {
  count = local.enable_redis_cache ? (
    local.launch_in_vnet ? (
      local.redis_cache_sku == "Premium" ? 1 : 0
    ) : 0
  ) : 0

  name                = "@"
  zone_name           = azurerm_private_dns_zone.redis_cache_private_link[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.default_redis_cache[0].private_service_connection.0.private_ip_address]
  tags                = local.tags
}
