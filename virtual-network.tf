resource "azurerm_virtual_network" "default" {
  count = local.existing_virtual_network == "" ? (
    local.launch_in_vnet ? 1 : 0
  ) : 0

  name                = "${local.resource_prefix}default"
  address_space       = [local.virtual_network_address_space]
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  tags                = local.tags
}

resource "azurerm_route_table" "default" {
  count = local.launch_in_vnet && local.existing_virtual_network == "" && local.container_app_environment_workload_profile_type != "Consumption" ? 1 : 0

  name                          = "${local.resource_prefix}default"
  location                      = local.resource_group.location
  resource_group_name           = local.resource_group.name
  bgp_route_propagation_enabled = true

  route {
    name           = "egress"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = local.virtual_network_deny_all_egress ? "None" : "Internet"
  }

  tags = local.tags
}

# Container App Networking

resource "azurerm_subnet" "container_apps_infra_subnet" {
  count = local.launch_in_vnet ? 1 : 0

  name                 = "${local.resource_prefix}containerappsinfra"
  virtual_network_name = local.virtual_network.name
  resource_group_name  = local.resource_group.name
  address_prefixes     = [local.container_apps_infra_subnet_cidr]
  service_endpoints    = local.container_apps_infra_subnet_service_endpoints

  dynamic "delegation" {
    for_each = local.container_app_environment_workload_profile_type != "Consumption" ? [1] : []

    content {
      name = "AzureContainerAppEnvironments"

      service_delegation {
        name = "Microsoft.App/environments"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action"
        ]
      }
    }
  }
}

resource "azurerm_subnet_route_table_association" "container_apps_infra_subnet" {
  count = local.launch_in_vnet && local.existing_virtual_network == "" && local.container_app_environment_workload_profile_type != "Consumption" ? 1 : 0

  subnet_id      = azurerm_subnet.container_apps_infra_subnet[0].id
  route_table_id = azurerm_route_table.default[0].id
}

# Container App Networking / Security

resource "azurerm_network_security_group" "container_apps_infra" {
  count = local.launch_in_vnet ? 1 : 0

  name                = "${local.resource_prefix}containerappsinfransg"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  tags = local.tags
}

resource "azurerm_network_security_rule" "allow_subnet_internal" {
  count = local.launch_in_vnet ? 1 : 0

  network_security_group_name = azurerm_network_security_group.container_apps_infra[0].name
  resource_group_name         = local.resource_group.name

  name        = "AllowSubnetInbound"
  description = "Required to allow the container app envoy sidecar to connect to envoy service."

  priority                     = 100
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "*"
  source_address_prefixes      = azurerm_subnet.container_apps_infra_subnet[0].address_prefixes
  destination_address_prefixes = azurerm_subnet.container_apps_infra_subnet[0].address_prefixes
}

resource "azurerm_network_security_rule" "container_apps_infra_allow_frontdoor_inbound_only" {
  count = local.launch_in_vnet && local.restrict_container_apps_to_cdn_inbound_only ? 1 : 0

  network_security_group_name = azurerm_network_security_group.container_apps_infra[0].name
  resource_group_name         = local.resource_group.name

  name        = "AllowAzureFrontDoorInbound"
  description = "Allow Azure Front Door to access Azure Container Apps."

  priority                   = 120
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_ranges    = ["443", "80"]
  source_address_prefix      = "AzureFrontDoor.Backend"
  destination_address_prefix = "${local.container_app_environment.static_ip_address}/32"
}

resource "azurerm_network_security_rule" "container_apps_infra_allow_appgateway_inbound_only" {
  count = local.launch_in_vnet && local.restrict_container_apps_to_agw_inbound_only && local.container_apps_allow_agw_ip != "" ? 1 : 0

  network_security_group_name = azurerm_network_security_group.container_apps_infra[0].name
  resource_group_name         = local.resource_group.name

  name        = "AllowAzureAppGatewayInbound"
  description = "Allow Azure App Gateway to access Azure Container Apps."

  priority                   = 130
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_ranges    = ["443", "80", "65200-65535"]
  source_address_prefix      = "${local.container_apps_allow_agw_ip}/32"
  destination_address_prefix = "${local.container_app_environment.static_ip_address}/32"
}

resource "azurerm_virtual_network_peering" "peered_vnet_app_gateway" {
  count = local.restrict_container_apps_to_agw_inbound_only && local.container_apps_allow_agw_resource.vnet_name != "" ? 1 : 0

  name                      = "Vnet-${local.virtual_network.name}-To-Vnet-${data.azurerm_virtual_network.existing_agw_vnet[0].name}"
  resource_group_name       = local.resource_group.name
  virtual_network_name      = local.virtual_network.name
  remote_virtual_network_id = data.azurerm_virtual_network.existing_agw_vnet[0].id
}

resource "azurerm_private_dns_zone" "container_app_environment" {
  count = local.restrict_container_apps_to_agw_inbound_only && local.container_apps_allow_agw_resource.vnet_name != "" ? 1 : 0

  name                = replace(local.container_fqdn, "${local.environment}${local.project_name}-${local.image_name}.", "")
  resource_group_name = local.resource_group.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "container_app_environment_agw_link" {
  count = local.restrict_container_apps_to_agw_inbound_only && local.container_apps_allow_agw_resource.vnet_name != "" ? 1 : 0

  name                  = "${local.resource_prefix}containerappsprivatelink"
  resource_group_name   = local.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.container_app_environment[0].name
  virtual_network_id    = data.azurerm_virtual_network.existing_agw_vnet[0].id
  tags                  = local.tags
}

resource "azurerm_private_dns_a_record" "container_app_environment_root" {
  count = local.restrict_container_apps_to_agw_inbound_only && local.container_apps_allow_agw_resource.vnet_name != "" ? 1 : 0

  name                = "@"
  zone_name           = azurerm_private_dns_zone.container_app_environment[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 300
  records             = [local.container_app_environment.static_ip_address]
}

resource "azurerm_private_dns_a_record" "container_app_environment_wildcard" {
  count = local.restrict_container_apps_to_agw_inbound_only && local.container_apps_allow_agw_resource.vnet_name != "" ? 1 : 0

  name                = "*"
  zone_name           = azurerm_private_dns_zone.container_app_environment[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 300
  records             = [local.container_app_environment.static_ip_address]
}

resource "azurerm_network_security_rule" "container_apps_infra_allow_ips_inbound" {
  count = local.launch_in_vnet && length(local.container_apps_allow_ips_inbound) != 0 ? 1 : 0

  network_security_group_name = azurerm_network_security_group.container_apps_infra[0].name
  resource_group_name         = local.resource_group.name

  name        = "AllowClientIpsInbound"
  description = "Allow your Client IPs to access Azure Container Apps. Use port 80 for HTTP and 443 for HTTPS."

  priority                   = 140
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_ranges    = ["443", "80"]
  source_address_prefixes    = local.container_apps_allow_ips_inbound
  destination_address_prefix = "${local.container_app_environment.static_ip_address}/32"
}

resource "azurerm_subnet_network_security_group_association" "container_apps_infra" {
  count = local.launch_in_vnet ? 1 : 0

  subnet_id                 = azurerm_subnet.container_apps_infra_subnet[0].id
  network_security_group_id = azurerm_network_security_group.container_apps_infra[0].id
}

# SQL Server Networking

resource "azurerm_subnet" "mssql_private_endpoint_subnet" {
  count = local.enable_mssql_database ? (
    local.launch_in_vnet ? 1 : 0
  ) : 0

  name                              = "${local.resource_prefix}mssqlprivateendpoint"
  virtual_network_name              = local.virtual_network.name
  resource_group_name               = local.resource_group.name
  address_prefixes                  = [local.mssql_private_endpoint_subnet_cidr]
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_subnet_route_table_association" "mssql_private_endpoint_subnet" {
  count = local.enable_private_endpoint_mssql && local.existing_virtual_network == "" ? 1 : 0

  subnet_id      = azurerm_subnet.mssql_private_endpoint_subnet[0].id
  route_table_id = azurerm_route_table.default[0].id
}

# SQL Server Networking / Security

resource "azurerm_network_security_group" "mssql_infra" {
  count = local.enable_mssql_database ? (
    local.launch_in_vnet ? 1 : 0
  ) : 0

  name                = "${local.resource_prefix}mssqlnsg"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  tags = local.tags
}

resource "azurerm_network_security_rule" "allow_mssql_inbound" {
  count = local.enable_mssql_database ? (
    local.launch_in_vnet ? 1 : 0
  ) : 0

  name                         = "AllowInboundMSSQLFromContainerApp"
  priority                     = 100
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "1433"
  source_address_prefixes      = azurerm_subnet.container_apps_infra_subnet[0].address_prefixes
  destination_address_prefixes = azurerm_subnet.mssql_private_endpoint_subnet[0].address_prefixes
  network_security_group_name  = azurerm_network_security_group.mssql_infra[0].name
  resource_group_name          = local.resource_group.name
}

resource "azurerm_subnet_network_security_group_association" "mssql_infra" {
  count = local.enable_mssql_database ? (
    local.launch_in_vnet ? 1 : 0
  ) : 0

  subnet_id                 = azurerm_subnet.mssql_private_endpoint_subnet[0].id
  network_security_group_id = azurerm_network_security_group.mssql_infra[0].id
}

# SQL Server Networking / Private Endpoint

resource "azurerm_private_dns_zone" "mssql_private_link" {
  count = local.enable_private_endpoint_mssql ? 1 : 0

  name                = "${local.resource_prefix}.database.windows.net"
  resource_group_name = local.resource_group.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "mssql_private_link" {
  count = local.enable_private_endpoint_mssql ? 1 : 0

  name                  = "${local.resource_prefix}mssqlprivatelink"
  resource_group_name   = local.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.mssql_private_link[0].name
  virtual_network_id    = local.virtual_network.id
  tags                  = local.tags
}

resource "azurerm_private_dns_a_record" "mssql_private_endpoint" {
  count = local.enable_private_endpoint_mssql ? 1 : 0

  name                = "@"
  zone_name           = azurerm_private_dns_zone.mssql_private_link[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.default["mssql"].private_service_connection[0].private_ip_address]
  tags                = local.tags
}

# Redis Networking

resource "azurerm_subnet" "redis_cache_subnet" {
  count = local.enable_private_endpoint_redis ? 1 : 0

  name                              = "${local.resource_prefix}rediscache"
  virtual_network_name              = local.virtual_network.name
  resource_group_name               = local.resource_group.name
  address_prefixes                  = [local.redis_cache_subnet_cidr]
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_subnet_route_table_association" "redis_cache_subnet" {
  count = local.enable_private_endpoint_redis && local.existing_virtual_network == "" ? 1 : 0

  subnet_id      = azurerm_subnet.redis_cache_subnet[0].id
  route_table_id = azurerm_route_table.default[0].id
}

# Redis Networking / Security

resource "azurerm_network_security_group" "redis_infra" {
  count = local.enable_private_endpoint_redis ? 1 : 0

  name                = "${local.resource_prefix}redisnsg"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  tags = local.tags
}

resource "azurerm_network_security_rule" "allow_redis_inbound" {
  count = local.enable_private_endpoint_redis ? 1 : 0

  name                         = "AllowInboundRedisFromContainerApp"
  priority                     = 100
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "6379-6380"
  source_address_prefixes      = azurerm_subnet.container_apps_infra_subnet[0].address_prefixes
  destination_address_prefixes = azurerm_subnet.redis_cache_subnet[0].address_prefixes
  network_security_group_name  = azurerm_network_security_group.redis_infra[0].name
  resource_group_name          = local.resource_group.name
}

resource "azurerm_subnet_network_security_group_association" "redis_infra" {
  count = local.enable_private_endpoint_redis ? 1 : 0

  subnet_id                 = azurerm_subnet.redis_cache_subnet[0].id
  network_security_group_id = azurerm_network_security_group.redis_infra[0].id
}

# Redis Networking / Private Endpoint

resource "azurerm_private_dns_zone" "redis_cache_private_link" {
  count = local.enable_private_endpoint_redis ? 1 : 0

  name                = "${azurerm_redis_cache.default[0].name}.redis.cache.windows.net"
  resource_group_name = local.resource_group.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis_cache_private_link" {
  count = local.enable_private_endpoint_redis ? 1 : 0

  name                  = "${local.resource_prefix}rediscacheprivatelink"
  resource_group_name   = local.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.redis_cache_private_link[0].name
  virtual_network_id    = local.virtual_network.id
  tags                  = local.tags
}

resource "azurerm_private_dns_a_record" "redis_cache_private_endpoint" {
  count = local.enable_private_endpoint_redis ? 1 : 0

  name                = "@"
  zone_name           = azurerm_private_dns_zone.redis_cache_private_link[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.default["rediscache"].private_service_connection[0].private_ip_address]
  tags                = local.tags
}

# PostgreSQL Server Networking

resource "azurerm_subnet" "postgresql_subnet" {
  count = local.enable_private_endpoint_postgres ? 1 : 0

  name                              = "${local.resource_prefix}postgresql"
  virtual_network_name              = local.virtual_network.name
  resource_group_name               = local.resource_group.name
  address_prefixes                  = [local.postgresql_subnet_cidr]
  private_endpoint_network_policies = "Enabled"
  service_endpoints                 = ["Microsoft.Sql"]

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet_route_table_association" "postgresql_subnet" {
  count = local.enable_private_endpoint_postgres && local.existing_virtual_network == "" ? 1 : 0

  subnet_id      = azurerm_subnet.postgresql_subnet[0].id
  route_table_id = azurerm_route_table.default[0].id
}

# PostgreSQL Server Networking / Security

resource "azurerm_network_security_group" "postgresql_infra" {
  count = local.enable_private_endpoint_postgres ? 1 : 0

  name                = "${local.resource_prefix}postgresqlnsg"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  tags = local.tags
}

resource "azurerm_network_security_rule" "allow_postgresql_inbound" {
  count = local.enable_private_endpoint_postgres ? 1 : 0

  name                         = "AllowInboundPostgresSQLFromContainerApp"
  priority                     = 100
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "5432"
  source_address_prefixes      = azurerm_subnet.container_apps_infra_subnet[0].address_prefixes
  destination_address_prefixes = azurerm_subnet.postgresql_subnet[0].address_prefixes
  network_security_group_name  = azurerm_network_security_group.postgresql_infra[0].name
  resource_group_name          = local.resource_group.name
}

resource "azurerm_subnet_network_security_group_association" "postgresql_infra" {
  count = local.enable_private_endpoint_postgres ? 1 : 0

  subnet_id                 = azurerm_subnet.postgresql_subnet[0].id
  network_security_group_id = azurerm_network_security_group.postgresql_infra[0].id
}

# PostgreSQL Server Networking / Private Endpoint

resource "azurerm_private_dns_zone" "postgresql_private_link" {
  count = local.enable_private_endpoint_postgres ? 1 : 0

  name                = "${local.resource_prefix}.postgres.database.azure.com"
  resource_group_name = local.resource_group.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql_private_link" {
  count = local.enable_private_endpoint_postgres ? 1 : 0

  name                  = "${local.resource_prefix}pgsqlprivatelink"
  resource_group_name   = local.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql_private_link[0].name
  virtual_network_id    = local.virtual_network.id
  tags                  = local.tags
}

resource "azurerm_private_dns_a_record" "postgresql_private_link" {
  count = local.enable_private_endpoint_postgres ? 1 : 0

  name                = "@"
  zone_name           = azurerm_private_dns_zone.postgresql_private_link[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.default["postgres"].private_service_connection[0].private_ip_address]
  tags                = local.tags
}

# Container Registry Networking

resource "azurerm_subnet" "registry_private_endpoint_subnet" {
  count = local.enable_private_endpoint_registry ? 1 : 0

  name                              = "${local.resource_prefix}registryprivateendpoint"
  virtual_network_name              = local.virtual_network.name
  resource_group_name               = local.resource_group.name
  address_prefixes                  = [local.registry_subnet_cidr]
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_subnet_route_table_association" "registry_private_endpoint_subnet" {
  count = local.enable_private_endpoint_registry && local.existing_virtual_network == "" ? 1 : 0

  subnet_id      = azurerm_subnet.registry_private_endpoint_subnet[0].id
  route_table_id = azurerm_route_table.default[0].id
}

# Container Registry Networking / Security

resource "azurerm_network_security_group" "registry_infra" {
  count = local.enable_private_endpoint_registry ? 1 : 0

  name                = "${local.resource_prefix}registrynsg"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  tags = local.tags
}

resource "azurerm_network_security_rule" "allow_registry_inbound" {
  count = local.enable_private_endpoint_registry ? 1 : 0

  name                         = "AllowInboundACRFromContainerApp"
  priority                     = 100
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "443"
  source_address_prefixes      = azurerm_subnet.container_apps_infra_subnet[0].address_prefixes
  destination_address_prefixes = azurerm_subnet.registry_private_endpoint_subnet[0].address_prefixes
  network_security_group_name  = azurerm_network_security_group.registry_infra[0].name
  resource_group_name          = local.resource_group.name
}

resource "azurerm_subnet_network_security_group_association" "registry_infra" {
  count = local.enable_private_endpoint_registry ? 1 : 0

  subnet_id                 = azurerm_subnet.registry_private_endpoint_subnet[0].id
  network_security_group_id = azurerm_network_security_group.registry_infra[0].id
}

# Container Registry Networking / Private Endpoint

resource "azurerm_private_dns_zone" "registry_private_link" {
  count = local.enable_private_endpoint_registry ? 1 : 0

  name                = "${azurerm_container_registry.acr[0].name}.azurecr.io"
  resource_group_name = local.resource_group.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "registry_private_link" {
  count = local.enable_private_endpoint_registry ? 1 : 0

  name                  = "${local.resource_prefix}registryprivatelink"
  resource_group_name   = local.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.registry_private_link[0].name
  virtual_network_id    = local.virtual_network.id
  tags                  = local.tags
}

resource "azurerm_private_dns_a_record" "registry_private_link" {
  count = local.enable_private_endpoint_registry ? 1 : 0

  name                = "@"
  zone_name           = azurerm_private_dns_zone.registry_private_link[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.default["registry"].private_service_connection[0].private_ip_address]
  tags                = local.tags
}

# Storage Account Networking

resource "azurerm_subnet" "storage_private_endpoint_subnet" {
  count = local.enable_private_endpoint_storage ? 1 : 0

  name                              = "${local.resource_prefix}storageprivateendpoint"
  virtual_network_name              = local.virtual_network.name
  resource_group_name               = local.resource_group.name
  address_prefixes                  = [local.storage_subnet_cidr]
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_subnet_route_table_association" "storage_private_endpoint_subnet" {
  count = local.enable_private_endpoint_storage && local.existing_virtual_network == "" ? 1 : 0

  subnet_id      = azurerm_subnet.storage_private_endpoint_subnet[0].id
  route_table_id = azurerm_route_table.default[0].id
}

# Storage Account Networking / Security

resource "azurerm_network_security_group" "storage_infra" {
  count = local.enable_private_endpoint_storage ? 1 : 0

  name                = "${local.resource_prefix}storagensg"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  tags = local.tags
}

resource "azurerm_network_security_rule" "allow_storage_inbound" {
  count = local.enable_private_endpoint_storage && local.existing_virtual_network == "" ? 1 : 0

  name                         = "AllowInboundStorageFromContainerApp"
  priority                     = 100
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_ranges      = ["443", "445"]
  source_address_prefixes      = azurerm_subnet.container_apps_infra_subnet[0].address_prefixes
  destination_address_prefixes = azurerm_subnet.storage_private_endpoint_subnet[0].address_prefixes
  network_security_group_name  = azurerm_network_security_group.storage_infra[0].name
  resource_group_name          = local.resource_group.name
}


resource "azurerm_subnet_network_security_group_association" "storage_infra" {
  count = local.enable_private_endpoint_storage ? 1 : 0

  subnet_id                 = azurerm_subnet.storage_private_endpoint_subnet[0].id
  network_security_group_id = azurerm_network_security_group.storage_infra[0].id
}

# Storage Account Networking / Private Endpoint / Blob

resource "azurerm_private_dns_zone" "storage_private_link_blob" {
  count = local.enable_private_endpoint_storage && local.enable_container_app_blob_storage ? 1 : 0

  name                = "${azurerm_storage_account.container_app[0].name}.blob.core.windows.net"
  resource_group_name = local.resource_group.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_private_link_blob" {
  count = local.enable_private_endpoint_storage && local.enable_container_app_blob_storage ? 1 : 0

  name                  = "${local.resource_prefix}storageprivatelinkblob"
  resource_group_name   = local.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_private_link_blob[0].name
  virtual_network_id    = local.virtual_network.id
  tags                  = local.tags
}

resource "azurerm_private_dns_a_record" "storage_private_link_blob" {
  count = local.enable_private_endpoint_storage && local.enable_container_app_blob_storage ? 1 : 0

  name                = "@"
  zone_name           = azurerm_private_dns_zone.storage_private_link_blob[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.default["blob"].private_service_connection[0].private_ip_address]
  tags                = local.tags
}

# Storage Account Networking / Private Endpoint / File

resource "azurerm_private_dns_zone" "storage_private_link_file" {
  count = local.enable_private_endpoint_storage && local.enable_container_app_file_share ? 1 : 0

  name                = "${azurerm_storage_account.container_app[0].name}.file.core.windows.net"
  resource_group_name = local.resource_group.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_private_link_file" {
  count = local.enable_private_endpoint_storage && local.enable_container_app_file_share ? 1 : 0

  name                  = "${local.resource_prefix}storageprivatelinkfile"
  resource_group_name   = local.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_private_link_file[0].name
  virtual_network_id    = local.virtual_network.id
  tags                  = local.tags
}

resource "azurerm_private_dns_a_record" "storage_private_link_file" {
  count = local.enable_private_endpoint_storage && local.enable_container_app_file_share ? 1 : 0

  name                = "@"
  zone_name           = azurerm_private_dns_zone.storage_private_link_file[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.default["file"].private_service_connection[0].private_ip_address]
  tags                = local.tags
}

# App Configuration Networking

resource "azurerm_subnet" "app_configuration_private_endpoint_subnet" {
  count = local.enable_private_endpoint_app_configuration ? 1 : 0

  name                              = "${local.resource_prefix}appconfigprivateendpoint"
  virtual_network_name              = local.virtual_network.name
  resource_group_name               = local.resource_group.name
  address_prefixes                  = [local.app_configuration_subnet_cidr]
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_subnet_route_table_association" "app_configuration_private_endpoint_subnet" {
  count = local.enable_private_endpoint_app_configuration && local.existing_virtual_network == "" ? 1 : 0

  subnet_id      = azurerm_subnet.app_configuration_private_endpoint_subnet[0].id
  route_table_id = azurerm_route_table.default[0].id
}

# App Configuration Networking / Security

resource "azurerm_network_security_group" "app_configuration_infra" {
  count = local.enable_private_endpoint_app_configuration ? 1 : 0

  name                = "${local.resource_prefix}appconfigurationnsg"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  tags = local.tags
}

resource "azurerm_network_security_rule" "allow_app_configuration_inbound" {
  count = local.enable_private_endpoint_app_configuration ? 1 : 0

  name                         = "AllowInboundAppConfigurationFromContainerApp"
  priority                     = 100
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "443"
  source_address_prefixes      = azurerm_subnet.container_apps_infra_subnet[0].address_prefixes
  destination_address_prefixes = azurerm_subnet.app_configuration_private_endpoint_subnet[0].address_prefixes
  network_security_group_name  = azurerm_network_security_group.app_configuration_infra[0].name
  resource_group_name          = local.resource_group.name
}

resource "azurerm_subnet_network_security_group_association" "app_configuration_infra" {
  count = local.enable_private_endpoint_app_configuration ? 1 : 0

  subnet_id                 = azurerm_subnet.app_configuration_private_endpoint_subnet[0].id
  network_security_group_id = azurerm_network_security_group.app_configuration_infra[0].id
}

# App Configuration Networking / Private Endpoint

resource "azurerm_private_dns_zone" "app_configuration_private_link" {
  count = local.enable_private_endpoint_app_configuration ? 1 : 0

  name                = "${azurerm_app_configuration.default[0].name}.privatelink.azconfig.io"
  resource_group_name = local.resource_group.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "app_configuration_private_link" {
  count = local.enable_private_endpoint_app_configuration ? 1 : 0

  name                  = "${local.resource_prefix}appconfigprivatelink"
  resource_group_name   = local.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.app_configuration_private_link[0].name
  virtual_network_id    = local.virtual_network.id
  tags                  = local.tags
}

resource "azurerm_private_dns_a_record" "app_configuration_private_link" {
  count = local.enable_private_endpoint_app_configuration ? 1 : 0

  name                = "@"
  zone_name           = azurerm_private_dns_zone.app_configuration_private_link[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.default["appconfig"].private_service_connection[0].private_ip_address]
  tags                = local.tags
}
