locals {
  # Global options
  environment     = var.environment
  project_name    = var.project_name
  resource_prefix = "${local.environment}${local.project_name}"
  azure_location  = var.azure_location
  tags            = var.tags

  # Resource Group
  existing_resource_group    = var.existing_resource_group
  resource_group             = local.existing_resource_group == "" ? azurerm_resource_group.default[0] : data.azurerm_resource_group.existing_resource_group[0]
  enable_resource_group_lock = var.enable_resource_group_lock

  # Networking
  launch_in_vnet                                           = var.launch_in_vnet
  existing_virtual_network                                 = var.existing_virtual_network
  virtual_network                                          = local.existing_virtual_network == "" ? azurerm_virtual_network.default[0] : data.azurerm_virtual_network.existing_virtual_network[0]
  virtual_network_address_space                            = var.virtual_network_address_space
  virtual_network_address_space_mask                       = element(split("/", local.virtual_network_address_space), 1)
  container_apps_infra_subnet_cidr                         = cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 0)
  mssql_private_endpoint_subnet_cidr                       = cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 1)
  container_instances_subnet_cidr                          = cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 2)
  redis_cache_private_endpoint_subnet_cidr                 = cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 3)
  registry_subnet_cidr                                     = cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 3)
  redis_cache_subnet_cidr                                  = cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 4)
  postgresql_subnet_cidr                                   = cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 5)
  container_app_environment_internal_load_balancer_enabled = var.container_app_environment_internal_load_balancer_enabled
  container_apps_infra_subnet_service_endpoints            = distinct(concat(local.launch_in_vnet && local.enable_storage_account ? ["Microsoft.Storage"] : [], var.container_apps_infra_subnet_service_endpoints))
  # Networking / Private Endpoints
  enable_private_endpoint_redis = local.enable_redis_cache ? (
    local.launch_in_vnet ? (
      local.redis_cache_sku == "Premium" ? false : true
    ) : false
  ) : false
  private_endpoint_redis = local.enable_private_endpoint_redis ? [{
    "rediscache" : {
      resource_group : local.resource_group,
      subnet_id : azurerm_subnet.redis_cache_subnet[0].id,
      resource_id : azurerm_redis_cache.default[0].id,
      subresource_names : ["redisCache"]
    }
  }] : []
  enable_private_endpoint_mssql = local.enable_mssql_database ? (
    local.launch_in_vnet ? true : false
  ) : false
  private_endpoint_mssql = local.enable_private_endpoint_mssql ? [{
    "mssql" : {
      resource_group : local.resource_group,
      subnet_id : azurerm_subnet.mssql_private_endpoint_subnet[0].id,
      resource_id : azurerm_mssql_server.default[0].id,
      subresource_names : ["sqlServer"]
    }
  }] : []
  enable_private_endpoint_postgres = local.enable_postgresql_database && local.launch_in_vnet && local.postgresql_network_connectivity_method == "private" ? 1 : 0
  private_endpoint_postgres = local.enable_private_endpoint_postgres ? [{
    "postgres" : {
      resource_group : local.resource_group,
      subnet_id : azurerm_subnet.postgresql_subnet[0].id,
      resource_id : azurerm_postgresql_flexible_server.default[0].id,
      subresource_names : ["postgresqlServer"]
    }
  }] : []
  enable_private_endpoint_registry = local.registry_sku == "Premium" ? 1 : 0
  private_endpoint_registry = local.enable_private_endpoint_registry ? [{
    "registry" : {
      resource_group : local.resource_group,
      subnet_id : azurerm_subnet.registry_private_endpoint_subnet[0].id,
      resource_id : azurerm_container_registry.acr[0].id,
    }
  }] : []
  custom_private_endpoints = var.custom_private_endpoints
  private_endpoints = concat(
    local.private_endpoint_redis,
    local.private_endpoint_mssql,
    local.private_endpoint_postgres,
    local.private_endpoint_registry,
    local.custom_private_endpoints,
  )

  # Azure Container Registry
  enable_container_registry        = var.enable_container_registry
  use_external_container_registry  = var.use_external_container_registry_url
  registry_custom_image_url        = var.registry_custom_image_url
  registry_retention_days          = var.registry_retention_days
  enable_registry_retention_policy = var.enable_registry_retention_policy
  registry_server                  = local.enable_container_registry ? azurerm_container_registry.acr[0].login_server : var.registry_server
  registry_username                = local.enable_container_registry ? azurerm_container_registry.acr[0].admin_username : var.registry_username
  registry_password                = local.enable_container_registry ? azurerm_container_registry.acr[0].admin_password : var.registry_password
  registry_sku                     = var.registry_sku
  registry_admin_enabled           = var.registry_admin_enabled
  registry_public_access_enabled   = var.registry_public_access_enabled
  registry_ipv4_allow_list         = var.registry_ipv4_allow_list
  registry_use_managed_identity    = var.registry_use_managed_identity
  registry_identity_id             = local.registry_use_managed_identity ? azurerm_container_registry.acr[0].identity[0].principal_id : null

  # SQL Server
  enable_mssql_database              = var.enable_mssql_database
  mssql_server_admin_password        = var.mssql_server_admin_password
  mssql_sku_name                     = var.mssql_sku_name
  mssql_max_size_gb                  = var.mssql_max_size_gb
  mssql_database_name                = var.mssql_database_name
  mssql_firewall_ipv4_allow_list     = var.mssql_firewall_ipv4_allow_list
  mssql_azuread_admin_username       = var.mssql_azuread_admin_username
  mssql_azuread_admin_object_id      = var.mssql_azuread_admin_object_id
  mssql_azuread_auth_only            = var.mssql_azuread_auth_only
  mssql_version                      = var.mssql_version
  mssql_server_public_access_enabled = var.mssql_server_public_access_enabled

  # Postgres Server
  enable_postgresql_database             = var.enable_postgresql_database
  postgresql_server_version              = var.postgresql_server_version
  postgresql_administrator_login         = var.postgresql_administrator_login
  postgresql_administrator_password      = var.postgresql_administrator_password
  postgresql_availability_zone           = var.postgresql_availability_zone
  postgresql_max_storage_mb              = var.postgresql_max_storage_mb
  postgresql_sku_name                    = var.postgresql_sku_name
  postgresql_enabled_extensions          = var.postgresql_enabled_extensions
  postgresql_collation                   = var.postgresql_collation
  postgresql_charset                     = var.postgresql_charset
  postgresql_network_connectivity_method = var.postgresql_network_connectivity_method
  postgresql_firewall_ipv4_allow = merge(
    {
      "container-app" = {
        start_ip_address = azurerm_container_app.container_apps["main"].outbound_ip_addresses[0]
        end_ip_address   = azurerm_container_app.container_apps["main"].outbound_ip_addresses[0]
      }
    },
    var.postgresql_firewall_ipv4_allow
  )

  # Azure Cache for Redis
  enable_redis_cache                   = var.enable_redis_cache
  redis_cache_version                  = var.redis_cache_version
  redis_cache_family                   = var.redis_cache_family
  redis_cache_sku                      = var.redis_cache_sku
  redis_cache_capacity                 = var.redis_cache_capacity
  redis_cache_patch_schedule_day       = var.redis_cache_patch_schedule_day
  redis_cache_patch_schedule_hour      = var.redis_cache_patch_schedule_hour
  redis_cache_firewall_ipv4_allow_list = var.redis_cache_firewall_ipv4_allow_list
  # Azure Cache for Redis/Configuration
  redis_config_defaults = {
    maxmemory_reserved              = local.redis_cache_sku == "Basic" ? 2 : local.redis_cache_sku == "Standard" ? 50 : local.redis_cache_sku == "Premium" ? 200 : null
    maxmemory_delta                 = local.redis_cache_sku == "Basic" ? 2 : local.redis_cache_sku == "Standard" ? 50 : local.redis_cache_sku == "Premium" ? 200 : null
    maxfragmentationmemory_reserved = local.redis_cache_sku == "Basic" ? 2 : local.redis_cache_sku == "Standard" ? 50 : local.redis_cache_sku == "Premium" ? 200 : null
    maxmemory_policy                = "volatile-lru"
  }
  redis_config = merge(local.redis_config_defaults, var.redis_config)

  # Container App
  container_cpu                          = var.container_cpu
  container_memory                       = var.container_memory
  container_min_replicas                 = var.container_min_replicas
  container_max_replicas                 = var.container_max_replicas
  container_port                         = var.container_port
  container_command                      = var.container_command
  container_environment_variables        = var.container_environment_variables
  container_secret_environment_variables = var.container_secret_environment_variables
  container_fqdn                         = azurerm_container_app.container_apps["main"].ingress[0].fqdn
  container_app_identities               = var.container_app_identities
  container_app_name_override            = var.container_app_name_override
  container_app_name                     = local.container_app_name_override == "" ? "${local.resource_prefix}-${local.image_name}" : local.container_app_name_override
  # Container App / Container image
  image_name = var.image_name
  image_tag  = var.image_tag
  # Container App / Liveness Probe
  enable_container_health_probe   = var.enable_container_health_probe
  container_health_probe_interval = var.container_health_probe_interval
  container_health_probe_path     = var.container_health_probe_path
  container_health_probe_protocol = var.container_health_probe_protocol
  container_health_tcp_probe = {
    interval_seconds = local.container_health_probe_interval
    transport        = "TCP"
    port             = local.container_port
  }
  container_health_http_probe = {
    interval_seconds = local.container_health_probe_interval
    transport        = "HTTP"
    port             = local.container_port
    path             = local.container_health_probe_path
  }
  container_health_https_probe = {
    interval_seconds = local.container_health_probe_interval
    transport        = "HTTPS"
    port             = local.container_port
    path             = local.container_health_probe_path
  }
  container_health_probes = {
    "tcp" : local.container_health_tcp_probe
    "http" : local.container_health_http_probe
    "https" : local.container_health_https_probe
  }
  container_health_probe = lookup(local.container_health_probes, local.container_health_probe_protocol, null)
  # Container App / Sidecar
  enable_worker_container       = var.enable_worker_container
  worker_container_command      = var.worker_container_command
  worker_container_min_replicas = var.worker_container_min_replicas
  worker_container_max_replicas = var.worker_container_max_replicas
  # Container app / Custom
  custom_container_apps = var.custom_container_apps
  custom_container_apps_cdn_frontdoor_custom_domain_dns_names = local.enable_cdn_frontdoor ? {
    for name, container in local.custom_container_apps : name => replace(container.ingress.cdn_frontdoor_custom_domain, local.dns_zone_domain_name, "")
    if container.ingress.external_enabled && container.ingress.cdn_frontdoor_custom_domain != "" && endswith(container.ingress.cdn_frontdoor_custom_domain, local.dns_zone_domain_name)
  } : {}

  # Storage Account
  enable_storage_account                = local.enable_container_app_blob_storage || local.enable_container_app_file_share
  storage_account_ipv4_allow_list       = var.storage_account_ipv4_allow_list
  storage_account_public_access_enabled = var.storage_account_public_access_enabled
  storage_account_file_share_quota_gb   = var.storage_account_file_share_quota_gb
  # Storage Account / Container
  enable_container_app_blob_storage = var.enable_container_app_blob_storage
  container_app_blob_storage_sas_secret = local.enable_container_app_blob_storage ? [
    {
      name  = "connectionstrings--blobstorage",
      value = "${azurerm_storage_account.container_app[0].primary_blob_endpoint}${azurerm_storage_container.container_app[0].name}${data.azurerm_storage_account_blob_container_sas.container_app[0].sas}"
    }
  ] : []
  # Storage Account / File Share
  enable_container_app_file_share     = var.enable_container_app_file_share
  container_app_file_share_mount_path = var.container_app_file_share_mount_path

  # Azure DNS Zone
  enable_dns_zone      = var.enable_dns_zone
  dns_zone_domain_name = var.dns_zone_domain_name
  dns_zone_soa_record  = var.dns_zone_soa_record
  dns_a_records        = var.dns_a_records
  dns_alias_records    = var.dns_alias_records
  dns_aaaa_records     = var.dns_aaaa_records
  dns_caa_records      = var.dns_caa_records
  dns_cname_records    = var.dns_cname_records
  dns_mx_records       = var.dns_mx_records
  dns_ns_records       = var.dns_ns_records
  dns_ptr_records      = var.dns_ptr_records
  dns_srv_records      = var.dns_srv_records
  dns_txt_records      = var.dns_txt_records

  # Azure Front Door
  enable_cdn_frontdoor                   = var.enable_cdn_frontdoor
  cdn_frontdoor_sku                      = var.cdn_frontdoor_sku
  cdn_frontdoor_response_timeout         = var.cdn_frontdoor_response_timeout
  cdn_frontdoor_custom_domains           = var.cdn_frontdoor_custom_domains
  cdn_frontdoor_enable_waf_logs          = var.cdn_frontdoor_enable_waf_logs
  cdn_frontdoor_enable_access_logs       = var.cdn_frontdoor_enable_access_logs
  cdn_frontdoor_enable_health_probe_logs = var.cdn_frontdoor_enable_health_probe_logs
  cdn_frontdoor_custom_domain_dns_names = local.enable_cdn_frontdoor && local.enable_dns_zone ? toset([
    for domain in local.cdn_frontdoor_custom_domains : replace(domain, local.dns_zone_domain_name, "") if endswith(domain, local.dns_zone_domain_name)
  ]) : []
  cdn_frontdoor_custom_domains_create_dns_records = var.cdn_frontdoor_custom_domains_create_dns_records
  cdn_frontdoor_origin_fqdn_override              = var.cdn_frontdoor_origin_fqdn_override != "" ? var.cdn_frontdoor_origin_fqdn_override : local.container_fqdn
  cdn_frontdoor_origin_host_header_override       = var.cdn_frontdoor_origin_host_header_override != "" ? var.cdn_frontdoor_origin_host_header_override : null
  cdn_frontdoor_origin_http_port                  = var.cdn_frontdoor_origin_http_port
  cdn_frontdoor_origin_https_port                 = var.cdn_frontdoor_origin_https_port
  cdn_frontdoor_forwarding_protocol               = var.cdn_frontdoor_forwarding_protocol
  enable_cdn_frontdoor_health_probe               = var.enable_cdn_frontdoor_health_probe
  cdn_frontdoor_health_probe_protocol             = var.cdn_frontdoor_health_probe_protocol
  cdn_frontdoor_health_probe_interval             = var.cdn_frontdoor_health_probe_interval
  cdn_frontdoor_health_probe_path                 = var.cdn_frontdoor_health_probe_path
  cdn_frontdoor_health_probe_request_type         = var.cdn_frontdoor_health_probe_request_type
  restrict_container_apps_to_cdn_inbound_only     = var.restrict_container_apps_to_cdn_inbound_only
  container_apps_allow_ips_inbound                = var.container_apps_allow_ips_inbound
  cdn_frontdoor_host_redirects                    = var.cdn_frontdoor_host_redirects
  cdn_frontdoor_host_add_response_headers         = var.cdn_frontdoor_host_add_response_headers
  cdn_frontdoor_remove_response_headers           = var.cdn_frontdoor_remove_response_headers
  ruleset_redirects_id                            = length(local.cdn_frontdoor_host_redirects) > 0 ? [azurerm_cdn_frontdoor_rule_set.redirects[0].id] : []
  ruleset_add_response_headers_id                 = length(local.cdn_frontdoor_host_add_response_headers) > 0 ? [azurerm_cdn_frontdoor_rule_set.add_response_headers[0].id] : []
  ruleset_remove_response_headers_id              = length(local.cdn_frontdoor_remove_response_headers) > 0 ? [azurerm_cdn_frontdoor_rule_set.remove_response_headers[0].id] : []
  ruleset_ids = concat(
    local.ruleset_redirects_id,
    local.ruleset_add_response_headers_id,
    local.ruleset_remove_response_headers_id,
  )
  cdn_frontdoor_enable_rate_limiting              = var.cdn_frontdoor_enable_rate_limiting
  cdn_frontdoor_rate_limiting_duration_in_minutes = var.cdn_frontdoor_rate_limiting_duration_in_minutes
  cdn_frontdoor_rate_limiting_threshold           = var.cdn_frontdoor_rate_limiting_threshold
  cdn_frontdoor_enable_waf                        = local.enable_cdn_frontdoor && local.cdn_frontdoor_enable_rate_limiting
  cdn_frontdoor_waf_mode                          = var.cdn_frontdoor_waf_mode
  cdn_frontdoor_rate_limiting_bypass_ip_list      = var.cdn_frontdoor_rate_limiting_bypass_ip_list

  # Event Hub
  enable_event_hub                          = var.enable_event_hub
  enable_logstash_consumer                  = var.enable_logstash_consumer
  eventhub_export_log_analytics_table_names = var.eventhub_export_log_analytics_table_names

  # Azure Monitor
  enable_monitoring = var.enable_monitoring
  # Azure Monitor / Logic App Workflow
  existing_logic_app_workflow     = var.existing_logic_app_workflow
  logic_app_workflow_name         = local.existing_logic_app_workflow.name == "" ? (local.enable_monitoring ? azurerm_logic_app_workflow.webhook[0].name : "") : data.azurerm_logic_app_workflow.existing_logic_app_workflow[0].name
  logic_app_workflow_id           = local.existing_logic_app_workflow.name == "" ? (local.enable_monitoring ? azurerm_logic_app_workflow.webhook[0].id : "") : data.azurerm_logic_app_workflow.existing_logic_app_workflow[0].id
  logic_app_workflow_callback_url = local.existing_logic_app_workflow.name == "" ? (local.enable_monitoring ? azurerm_logic_app_trigger_http_request.webhook[0].callback_url : "") : jsondecode(data.azapi_resource_action.existing_logic_app_workflow_callback_url[0].output).value
  monitor_email_receivers         = var.monitor_email_receivers
  monitor_endpoint_healthcheck    = var.monitor_endpoint_healthcheck
  monitor_http_availability_fqdn = local.enable_cdn_frontdoor ? (
    length(local.cdn_frontdoor_custom_domains) >= 1 ? local.cdn_frontdoor_custom_domains[0] : azurerm_cdn_frontdoor_endpoint.endpoint[0].host_name
  ) : local.container_fqdn
  monitor_http_availability_url = "https://${local.monitor_http_availability_fqdn}${local.monitor_endpoint_healthcheck}"
  monitor_default_container_id  = { "default_id" = azurerm_container_app.container_apps["main"].id }
  monitor_worker_container_id   = local.enable_worker_container ? { "worker_id" = azurerm_container_app.container_apps["worker"].id } : {}
  monitor_container_ids = merge(
    local.monitor_default_container_id,
    local.monitor_worker_container_id,
  )
  monitor_enable_slack_webhook   = var.monitor_enable_slack_webhook
  monitor_slack_webhook_receiver = var.monitor_slack_webhook_receiver
  monitor_slack_channel          = var.monitor_slack_channel
  monitor_logic_app_receiver = {
    name         = local.logic_app_workflow_name
    resource_id  = local.logic_app_workflow_id
    callback_url = local.logic_app_workflow_callback_url
  }
  monitor_tls_expiry = var.monitor_tls_expiry
  # Azure Monitor / Alarm thresholds
  alarm_cpu_threshold_percentage    = var.alarm_cpu_threshold_percentage
  alarm_memory_threshold_percentage = var.alarm_memory_threshold_percentage
  alarm_latency_threshold_ms        = var.alarm_latency_threshold_ms
  alarm_tls_expiry_days_remaining   = var.alarm_tls_expiry_days_remaining
  alarm_log_ingestion_gb_per_day    = var.alarm_log_ingestion_gb_per_day

  # Network Watcher
  enable_network_watcher                         = var.enable_network_watcher
  existing_network_watcher_name                  = var.existing_network_watcher_name
  existing_network_watcher_resource_group_name   = var.existing_network_watcher_resource_group_name
  network_watcher_name                           = local.enable_network_watcher ? azurerm_network_watcher.default[0].name : local.existing_network_watcher_name
  network_watcher_resource_group_name            = local.network_watcher_name != "" ? local.existing_network_watcher_resource_group_name : local.resource_group.name
  network_watcher_flow_log_retention             = var.network_watcher_flow_log_retention
  enable_network_watcher_traffic_analytics       = var.enable_network_watcher_traffic_analytics
  network_watcher_traffic_analytics_interval     = var.network_watcher_traffic_analytics_interval
  network_security_group_container_apps_infra_id = local.launch_in_vnet ? { "container_apps_infra" = azurerm_network_security_group.container_apps_infra[0].id } : {}
  network_security_group_ids = merge(
    local.network_security_group_container_apps_infra_id,
  )
}
