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
  launch_in_vnet                           = var.launch_in_vnet
  existing_virtual_network                 = var.existing_virtual_network
  virtual_network                          = local.existing_virtual_network == "" ? azurerm_virtual_network.default[0] : data.azurerm_virtual_network.existing_virtual_network[0]
  virtual_network_address_space            = var.virtual_network_address_space
  virtual_network_address_space_mask       = element(split("/", local.virtual_network_address_space), 1)
  container_apps_infra_subnet_cidr         = cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 0)
  mssql_private_endpoint_subnet_cidr       = cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 1)
  container_instances_subnet_cidr          = cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 2)
  redis_cache_private_endpoint_subnet_cidr = cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 3)
  redis_cache_subnet_cidr                  = cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 4)

  # Azure Container Registry
  enable_container_registry = var.enable_container_registry
  registry_server           = local.enable_container_registry ? azurerm_container_registry.acr[0].login_server : var.registry_server
  registry_username         = local.enable_container_registry ? azurerm_container_registry.acr[0].admin_username : var.registry_username
  registry_password         = local.enable_container_registry ? azurerm_container_registry.acr[0].admin_password : var.registry_password

  # SQL Server
  enable_mssql_database          = var.enable_mssql_database
  mssql_server_admin_password    = var.mssql_server_admin_password
  mssql_sku_name                 = var.mssql_sku_name
  mssql_max_size_gb              = var.mssql_max_size_gb
  mssql_database_name            = var.mssql_database_name
  mssql_firewall_ipv4_allow_list = var.mssql_firewall_ipv4_allow_list
  mssql_azuread_admin_username   = var.mssql_azuread_admin_username
  mssql_azuread_admin_object_id  = var.mssql_azuread_admin_object_id
  mssql_azuread_auth_only        = var.mssql_azuread_auth_only

  # Azure Cache for Redis
  enable_redis_cache                   = var.enable_redis_cache
  redis_cache_version                  = var.redis_cache_version
  redis_cache_family                   = var.redis_cache_family
  redis_cache_sku                      = var.redis_cache_sku
  redis_cache_capacity                 = var.redis_cache_capacity
  redis_cache_patch_schedule_day       = var.redis_cache_patch_schedule_day
  redis_cache_patch_schedule_hour      = var.redis_cache_patch_schedule_hour
  redis_cache_firewall_ipv4_allow_list = var.redis_cache_firewall_ipv4_allow_list

  # Container App
  container_cpu                          = var.container_cpu
  container_memory                       = var.container_memory
  container_min_replicas                 = var.container_min_replicas
  container_max_replicas                 = var.container_max_replicas
  container_port                         = var.container_port
  container_command                      = var.container_command
  container_environment_variables        = var.container_environment_variables
  container_secret_environment_variables = var.container_secret_environment_variables
  # Container App / Container image
  image_name = var.image_name
  image_tag  = var.image_tag
  # Container App / Scale rules
  container_scale_rule_concurrent_request_count = tostring(var.container_scale_rule_concurrent_request_count)
  container_scale_rule_scale_down_out_of_hours  = var.container_scale_rule_scale_down_out_of_hours
  container_scale_rule_out_of_hours_start       = var.container_scale_rule_out_of_hours_start
  container_scale_rule_out_of_hours_end         = var.container_scale_rule_out_of_hours_end
  # Container App / Liveness Probe
  enable_container_health_probe   = var.enable_container_health_probe
  container_health_probe_interval = var.container_health_probe_interval
  container_health_probe_path     = var.container_health_probe_path
  container_health_probe_protocol = var.container_health_probe_protocol
  container_health_tcp_probe = [
    {
      type          = "Liveness"
      periodSeconds = local.container_health_probe_interval
      tcpSocket = {
        port = local.container_port
      }
    }
  ]
  container_health_https_probe = [
    {
      type          = "Liveness"
      periodSeconds = local.container_health_probe_interval
      httpGet = {
        path = local.container_health_probe_path
        port = local.container_port
      }
    }
  ]
  container_health_probes = {
    "tcp" : local.container_health_tcp_probe
    "https" : local.container_health_https_probe
  }
  container_health_probe = lookup(local.container_health_probes, local.container_health_probe_protocol, null)
  # Container App / Sidecar
  enable_worker_container       = var.enable_worker_container
  worker_container_command      = var.worker_container_command
  worker_container_min_replicas = var.worker_container_min_replicas
  worker_container_max_replicas = var.worker_container_max_replicas

  # Storage Account
  enable_container_app_blob_storage                = var.enable_container_app_blob_storage
  container_app_blob_storage_public_access_enabled = var.container_app_blob_storage_public_access_enabled
  container_app_blob_storage_ipv4_allow_list = concat(
    jsondecode(azapi_resource.default.output).properties.outboundIpAddresses,
    var.container_app_blob_storage_ipv4_allow_list
  )
  container_app_blob_storage_sas_secret = local.enable_container_app_blob_storage ? [
    {
      name  = "connectionstrings--blobstorage",
      value = "${azurerm_storage_account.container_app[0].primary_blob_endpoint}${azurerm_storage_container.container_app[0].name}${data.azurerm_storage_account_blob_container_sas.container_app[0].sas}"
    }
  ] : []

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
  cdn_frontdoor_origin_fqdn_override              = var.cdn_frontdoor_origin_fqdn_override != "" ? var.cdn_frontdoor_origin_fqdn_override : jsondecode(azapi_resource.default.output).properties.configuration.ingress.fqdn
  cdn_frontdoor_origin_host_header_override       = var.cdn_frontdoor_origin_host_header_override != "" ? var.cdn_frontdoor_origin_host_header_override : null
  cdn_frontdoor_origin_http_port                  = var.cdn_frontdoor_origin_http_port
  cdn_frontdoor_origin_https_port                 = var.cdn_frontdoor_origin_https_port
  enable_cdn_frontdoor_health_probe               = var.enable_cdn_frontdoor_health_probe
  cdn_frontdoor_health_probe_interval             = var.cdn_frontdoor_health_probe_interval
  cdn_frontdoor_health_probe_path                 = var.cdn_frontdoor_health_probe_path
  cdn_frontdoor_health_probe_request_type         = var.cdn_frontdoor_health_probe_request_type
  restrict_container_apps_to_cdn_inbound_only     = var.restrict_container_apps_to_cdn_inbound_only
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
  enable_event_hub         = var.enable_event_hub
  enable_logstash_consumer = var.enable_logstash_consumer

  # Azure Monitor
  enable_monitoring            = var.enable_monitoring
  monitor_email_receivers      = var.monitor_email_receivers
  monitor_endpoint_healthcheck = var.monitor_endpoint_healthcheck
  monitor_http_availability_fqdn = local.enable_cdn_frontdoor ? (
    length(local.cdn_frontdoor_custom_domains) >= 1 ? local.cdn_frontdoor_custom_domains[0] : azurerm_cdn_frontdoor_endpoint.endpoint[0].host_name
  ) : jsondecode(azapi_resource.default.output).properties.configuration.ingress.fqdn
  monitor_http_availability_url = "https://${local.monitor_http_availability_fqdn}${local.monitor_endpoint_healthcheck}"
  monitor_default_container_id  = { "default_id" = azapi_resource.default.id }
  monitor_worker_container_id   = local.enable_worker_container ? { "worker_id" = azapi_resource.worker[0].id } : {}
  monitor_container_ids = merge(
    local.monitor_default_container_id,
    local.monitor_worker_container_id,
  )
  monitor_enable_slack_webhook      = var.monitor_enable_slack_webhook
  monitor_slack_webhook_receiver    = var.monitor_slack_webhook_receiver
  monitor_slack_channel             = var.monitor_slack_channel
  alarm_cpu_threshold_percentage    = var.alarm_cpu_threshold_percentage
  alarm_memory_threshold_percentage = var.alarm_memory_threshold_percentage
  alarm_latency_threshold_ms        = var.alarm_latency_threshold_ms

  # Network Watcher
  enable_network_watcher                                                      = var.enable_network_watcher
  existing_network_watcher_name                                               = var.existing_network_watcher_name
  existing_network_watcher_resource_group_name                                = var.existing_network_watcher_resource_group_name
  network_watcher_name                                                        = local.enable_network_watcher ? azurerm_network_watcher.default[0].name : local.existing_network_watcher_name
  network_watcher_resource_group_name                                         = local.network_watcher_name != "" ? local.existing_network_watcher_resource_group_name : local.resource_group.name
  network_watcher_flow_log_retention                                          = var.network_watcher_flow_log_retention
  enable_network_watcher_traffic_analytics                                    = var.enable_network_watcher_traffic_analytics
  network_watcher_traffic_analytics_interval                                  = var.network_watcher_traffic_analytics_interval
  network_security_group_container_apps_infra_allow_frontdoor_inbound_only_id = local.launch_in_vnet && local.restrict_container_apps_to_cdn_inbound_only && local.enable_cdn_frontdoor ? { "container_apps_infra_allow_frontdoor_inbound_only" = azurerm_network_security_group.container_apps_infra_allow_frontdoor_inbound_only[0].id } : {}
  network_security_group_ids = merge(
    local.network_security_group_container_apps_infra_allow_frontdoor_inbound_only_id,
  )

  # Misc.
  tagging_command = "timeout 15m ${path.module}/script/apply-tags-to-container-app-env-mc-resource-group -n \"${azapi_resource.container_app_env.name}\" -r \"${local.resource_group.name}\" -t \"${replace(jsonencode(local.tags), "\"", "\\\"")}\""
}
