locals {
  # Global options
  environment               = var.environment
  project_name              = var.project_name
  resource_prefix           = "${local.environment}${local.project_name}"
  resource_prefix_sha       = sha1(local.resource_prefix)
  resource_prefix_sha_short = substr(local.resource_prefix_sha, 0, 6)
  azure_location            = var.azure_location
  tags                      = var.tags

  # Resource Group
  existing_resource_group    = var.existing_resource_group
  resource_group             = local.existing_resource_group == "" ? azurerm_resource_group.default[0] : data.azurerm_resource_group.existing_resource_group[0]
  enable_resource_group_lock = var.enable_resource_group_lock

  # Key Vault
  escrow_container_app_secrets_in_key_vault = var.escrow_container_app_secrets_in_key_vault
  existing_key_vault                        = var.existing_key_vault
  key_vault                                 = !local.escrow_container_app_secrets_in_key_vault && local.existing_key_vault == "" ? null : local.existing_key_vault == "" ? azurerm_key_vault.default[0] : data.azurerm_key_vault.existing_key_vault[0]
  key_vault_managed_identity_assign_role    = var.key_vault_managed_identity_assign_role
  key_vault_access_ipv4                     = var.key_vault_access_ipv4

  # Networking
  launch_in_vnet                                           = var.launch_in_vnet
  existing_virtual_network                                 = var.existing_virtual_network
  virtual_network                                          = local.existing_virtual_network == "" ? azurerm_virtual_network.default[0] : data.azurerm_virtual_network.existing_virtual_network[0]
  virtual_network_deny_all_egress                          = var.virtual_network_deny_all_egress
  virtual_network_address_space                            = var.virtual_network_address_space
  virtual_network_address_space_mask                       = element(split("/", local.virtual_network_address_space), 1)
  container_apps_infra_subnet_cidr                         = var.container_apps_infra_subnet_cidr == "" ? cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 0) : var.container_apps_infra_subnet_cidr
  mssql_private_endpoint_subnet_cidr                       = var.mssql_private_endpoint_subnet_cidr == "" ? cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 1) : var.mssql_private_endpoint_subnet_cidr
  registry_subnet_cidr                                     = var.registry_subnet_cidr == "" ? cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 3) : var.registry_subnet_cidr
  redis_cache_subnet_cidr                                  = var.redis_cache_subnet_cidr == "" ? cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 4) : var.redis_cache_subnet_cidr
  postgresql_subnet_cidr                                   = var.postgresql_subnet_cidr == "" ? cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 5) : var.postgresql_subnet_cidr
  storage_subnet_cidr                                      = var.storage_subnet_cidr == "" ? cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 6) : var.storage_subnet_cidr
  app_configuration_subnet_cidr                            = var.app_configuration_subnet_cidr == "" ? cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 7) : var.app_configuration_subnet_cidr
  container_app_environment_internal_load_balancer_enabled = var.container_app_environment_internal_load_balancer_enabled
  container_apps_infra_subnet_service_endpoints = distinct(concat(
    local.launch_in_vnet && local.enable_storage_account ? ["Microsoft.Storage"] : [],
    var.container_apps_infra_subnet_service_endpoints,
    local.escrow_container_app_secrets_in_key_vault ? ["Microsoft.KeyVault"] : []
  ))
  # Networking / Private Endpoints
  enable_private_endpoint_redis = local.enable_redis_cache ? (
    local.launch_in_vnet ? true : false
  ) : false
  private_endpoint_redis = local.enable_private_endpoint_redis ? {
    "rediscache" : {
      resource_group : local.resource_group,
      subnet_id : azurerm_subnet.redis_cache_subnet[0].id,
      resource_id : azurerm_redis_cache.default[0].id,
      subresource_names : ["redisCache"],
      private_zone_id : azurerm_private_dns_zone.redis_cache_private_link[0].id,
    }
  } : {}
  enable_private_endpoint_mssql = local.enable_mssql_database ? (
    local.launch_in_vnet ? true : false
  ) : false
  private_endpoint_mssql = local.enable_private_endpoint_mssql ? {
    "mssql" : {
      resource_group : local.resource_group,
      subnet_id : azurerm_subnet.mssql_private_endpoint_subnet[0].id,
      resource_id : azurerm_mssql_server.default[0].id,
      subresource_names : ["sqlServer"],
      private_zone_id : azurerm_private_dns_zone.mssql_private_link[0].id,
    }
  } : {}
  enable_private_endpoint_postgres = local.enable_postgresql_database && local.launch_in_vnet && local.postgresql_network_connectivity_method == "private" ? true : false
  private_endpoint_postgres = local.enable_private_endpoint_postgres ? {
    "postgres" : {
      resource_group : local.resource_group,
      subnet_id : azurerm_subnet.postgresql_subnet[0].id,
      resource_id : azurerm_postgresql_flexible_server.default[0].id,
      subresource_names : ["postgresqlServer"],
      private_zone_id : azurerm_private_dns_zone.postgresql_private_link[0].id,
    }
  } : {}
  enable_private_endpoint_registry = local.registry_sku == "Premium" ? true : false
  private_endpoint_registry = local.enable_private_endpoint_registry ? {
    "registry" : {
      resource_group : local.resource_group,
      subnet_id : azurerm_subnet.registry_private_endpoint_subnet[0].id,
      resource_id : azurerm_container_registry.acr[0].id,
      private_zone_id : azurerm_private_dns_zone.registry_private_link[0].id,
    }
  } : {}
  enable_private_endpoint_storage = local.enable_storage_account ? true : false
  private_endpoint_storage_blob = local.enable_container_app_blob_storage ? {
    "blob" : {
      resource_group : local.resource_group,
      subnet_id : azurerm_subnet.storage_private_endpoint_subnet[0].id,
      resource_id : azurerm_storage_account.container_app[0].id,
      subresource_names : ["blob"],
      private_zone_id : azurerm_private_dns_zone.storage_private_link_blob[0].id,
    }
  } : {}
  private_endpoint_storage_file = local.enable_container_app_file_share ? {
    "file" : {
      resource_group : local.resource_group,
      subnet_id : azurerm_subnet.storage_private_endpoint_subnet[0].id,
      resource_id : azurerm_storage_account.container_app[0].id,
      subresource_names : ["file"],
      private_zone_id : azurerm_private_dns_zone.storage_private_link_file[0].id,
    }
  } : {}
  enable_private_endpoint_app_configuration = local.enable_app_configuration && local.app_configuration_sku != "free" ? true : false
  private_endpoint_app_configuration = local.enable_private_endpoint_app_configuration ? {
    "appconfig" : {
      resource_group : local.resource_group,
      subnet_id : azurerm_subnet.app_configuration_private_endpoint_subnet[0].id,
      resource_id : azurerm_app_configuration.default[0].id,
      private_zone_id : azurerm_private_dns_zone.app_configuration_private_link[0].id,
    }
  } : {}
  private_endpoints = merge(
    local.private_endpoint_redis,
    local.private_endpoint_mssql,
    local.private_endpoint_postgres,
    local.private_endpoint_registry,
    local.private_endpoint_storage_blob,
    local.private_endpoint_storage_file,
    local.private_endpoint_app_configuration,
  )

  # Azure Container Registry
  enable_container_registry             = var.enable_container_registry
  registry_retention_days               = var.registry_retention_days
  enable_registry_retention_policy      = var.enable_registry_retention_policy
  registry_server                       = var.registry_server != "" ? var.registry_server : local.enable_container_registry ? azurerm_container_registry.acr[0].login_server : null
  registry_username                     = var.registry_username != "" ? var.registry_username : local.enable_container_registry ? azurerm_container_registry.acr[0].admin_username : null
  registry_password                     = var.registry_password != "" ? var.registry_password : local.enable_container_registry ? azurerm_container_registry.acr[0].admin_password : null
  registry_sku                          = var.registry_sku
  registry_admin_enabled                = var.registry_admin_enabled
  registry_public_access_enabled        = var.registry_public_access_enabled
  registry_ipv4_allow_list              = var.registry_ipv4_allow_list
  registry_use_managed_identity         = var.registry_use_managed_identity
  registry_managed_identity_assign_role = var.registry_managed_identity_assign_role

  # SQL Server
  enable_mssql_database                           = var.enable_mssql_database
  mssql_server_admin_password                     = var.mssql_server_admin_password
  mssql_sku_name                                  = var.mssql_sku_name
  mssql_max_size_gb                               = var.mssql_max_size_gb
  mssql_database_name                             = var.mssql_database_name
  mssql_firewall_ipv4_allow_list                  = var.mssql_firewall_ipv4_allow_list
  mssql_azuread_admin_username                    = var.mssql_azuread_admin_username
  mssql_azuread_admin_object_id                   = var.mssql_azuread_admin_object_id
  mssql_azuread_auth_only                         = var.mssql_azuread_auth_only
  mssql_version                                   = var.mssql_version
  mssql_server_public_access_enabled              = var.mssql_server_public_access_enabled
  enable_mssql_vulnerability_assessment           = var.enable_mssql_vulnerability_assessment
  mssql_security_storage_firewall_ipv4_allow_list = var.mssql_security_storage_firewall_ipv4_allow_list
  mssql_managed_identity_assign_role              = var.mssql_managed_identity_assign_role
  mssql_maintenance_configuration_name            = var.mssql_maintenance_configuration_name

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
  container_app_environment_workload_profile_type = var.container_app_environment_workload_profile_type
  container_app_environment_min_host_count        = var.container_app_environment_min_host_count
  container_app_environment_max_host_count        = var.container_app_environment_max_host_count

  container_cpu                          = var.container_cpu
  container_memory                       = var.container_memory
  container_min_replicas                 = var.container_min_replicas
  container_max_replicas                 = var.container_max_replicas
  container_port                         = var.container_port
  container_command                      = var.container_command
  container_environment_variables        = var.container_environment_variables
  container_secret_environment_variables = var.container_secret_environment_variables
  container_fqdn                         = azurerm_container_app.container_apps["main"].ingress[0].fqdn
  container_app_name_override            = var.container_app_name_override
  container_app_name                     = local.container_app_name_override == "" ? "${local.resource_prefix}-${local.image_name}" : local.container_app_name_override
  container_app_secrets = { for i, v in concat(
    [
      {
        "name" : "acr-password",
        "value" : local.registry_use_managed_identity && !local.registry_admin_enabled ? "not-in-use" : local.registry_password
      }
    ],
    local.enable_app_insights_integration ? [
      {
        name  = "applicationinsights--connectionstring",
        value = azurerm_application_insights.main[0].connection_string
      },
      {
        name  = "applicationinsights--instrumentationkey",
        value = azurerm_application_insights.main[0].instrumentation_key
      }
    ] : [],
    local.enable_redis_cache ? [
      {
        name  = "connectionstrings--redis",
        value = azurerm_redis_cache.default[0].primary_connection_string
      }
    ] : [],
    local.enable_app_configuration ? [
      {
        name  = "connectionstrings--appconfig",
        value = azurerm_app_configuration.default[0].endpoint
      }
    ] : [],
    local.container_app_blob_storage_sas_secret,
    [for env_name, env_value in nonsensitive(local.container_secret_environment_variables) : {
      name  = lower(replace(env_name, "_", "-"))
      value = sensitive(env_value)
      }
    ]
  ) : v.name => v }
  container_app_secrets_in_key_vault = local.escrow_container_app_secrets_in_key_vault ? { for name, secret in local.container_app_secrets : name => {
    key_vault_secret_id = azurerm_key_vault_secret.secret_app_setting[name].versionless_id
    name                = secret["name"]
  } } : {}
  container_app_env_vars = { for i, v in concat(
    local.enable_app_insights_integration ? [
      {
        "name" : "ApplicationInsights__ConnectionString",
        "secretRef" : "applicationinsights--connectionstring"
      },
      {
        "name" : "ApplicationInsights__InstrumentationKey",
        "secretRef" : "applicationinsights--instrumentationkey"
      }
    ] : [],
    (length(local.container_app_blob_storage_sas_secret) > 0) ?
    [
      {
        "name" : "ConnectionStrings__BlobStorage",
        "secretRef" : "connectionstrings--blobstorage"
      }
    ] : [],
    local.enable_redis_cache ?
    [
      {
        "name" : "ConnectionStrings__Redis",
        "secretRef" : "connectionstrings--redis"
      }
    ] : [],
    local.enable_app_configuration ? [
      {
        "name" : "ConnectionStrings__AppConfig",
        "secretRef" : "connectionstrings--appconfig"
      }
    ] : [],
    local.enable_container_app_uami ? [
      {
        "name" : "AZURE_CLIENT_ID"
        "value" : local.container_app_uami.client_id
      }
    ] : [],
    [
      for env_name, env_value in local.container_environment_variables : {
        name  = env_name
        value = env_value
      }
    ],
    [
      for env_name, env_value in nonsensitive(local.container_secret_environment_variables) : {
        name      = env_name
        secretRef = lower(replace(env_name, "_", "-"))
      }
  ]) : v.name => v }
  # Container App / Init Containers
  enable_init_container  = var.enable_init_container
  init_container_image   = var.init_container_image
  init_container_command = var.init_container_command

  # Container App Environment
  existing_container_app_environment = var.existing_container_app_environment
  container_app_environment          = local.existing_container_app_environment.name == "" ? azurerm_container_app_environment.container_app_env[0] : data.azurerm_container_app_environment.existing_container_app_environment[0]

  # Container App / Identity
  enable_container_app_uami = anytrue([
    var.container_app_use_managed_identity,
    local.registry_use_managed_identity,
    local.enable_app_configuration,
    local.key_vault != null,
    local.enable_storage_account,
  ])
  container_app_uami = local.enable_container_app_uami ? azurerm_user_assigned_identity.containerapp[0] : null
  container_app_identity_ids = concat(
    var.container_app_identities, local.container_app_uami != null ? [local.container_app_uami.id] : []
  )

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
  # Container App / Scale Rules
  container_scale_out_at_defined_time = var.container_scale_out_at_defined_time
  container_scale_out_rule_start      = var.container_scale_out_rule_start
  container_scale_out_rule_end        = var.container_scale_out_rule_end
  container_scale_http_concurrency    = var.container_scale_http_concurrency
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
  enable_storage_account = local.enable_container_app_blob_storage || local.enable_container_app_file_share
  storage_account_ipv4_allow_list = concat(
    var.storage_account_ipv4_allow_list,
    [azurerm_container_app.container_apps["main"].outbound_ip_addresses[0]]
  )
  storage_account_public_access_enabled             = var.storage_account_public_access_enabled
  storage_account_file_share_quota_gb               = var.storage_account_file_share_quota_gb
  storage_account_access_key_rotation_reminder_days = var.storage_account_access_key_rotation_reminder_days
  # Storage Account / Container
  container_app_storage_account_shared_access_key_enabled = var.container_app_storage_account_shared_access_key_enabled
  enable_container_app_blob_storage                       = var.enable_container_app_blob_storage
  create_container_app_blob_storage_sas                   = var.create_container_app_blob_storage_sas
  container_app_blob_storage_sas_secret = (local.enable_container_app_blob_storage && local.create_container_app_blob_storage_sas) ? [
    {
      name  = "connectionstrings--blobstorage",
      value = "${azurerm_storage_account.container_app[0].primary_blob_endpoint}${azurerm_storage_container.container_app[0].name}${data.azurerm_storage_account_blob_container_sas.container_app[0].sas}"
    }
  ] : []
  container_app_blob_storage_public_access_enabled       = local.enable_container_app_blob_storage == false ? false : var.container_app_blob_storage_public_access_enabled
  container_app_storage_cross_tenant_replication_enabled = var.container_app_storage_cross_tenant_replication_enabled
  storage_account_sas_expiration_period                  = var.storage_account_sas_expiration_period
  # Storage Account / File Share
  enable_container_app_file_share           = var.enable_container_app_file_share
  container_app_file_share_mount_path       = var.container_app_file_share_mount_path
  container_app_file_share_security_profile = var.container_app_file_share_security_profile
  # Storage Account / MSSQL Security
  mssql_security_storage_shared_access_key_enabled         = var.mssql_storage_account_shared_access_key_enabled
  mssql_security_storage_access_key_rotation_reminder_days = var.mssql_security_storage_access_key_rotation_reminder_days != 0 ? var.mssql_security_storage_access_key_rotation_reminder_days : local.storage_account_access_key_rotation_reminder_days
  mssql_security_storage_cross_tenant_replication_enabled  = var.mssql_security_storage_cross_tenant_replication_enabled

  # Azure Functions
  linux_function_apps = var.linux_function_apps
  linux_function_health_insights_api = (local.enable_app_insights_integration && local.enable_monitoring && var.enable_health_insights_api) ? {
    "health-api" = {
      runtime         = "python"
      runtime_version = "3.11"
      app_settings = {
        "TARGET_LOG_ANALYTICS_RESOURCE_ID" = azurerm_application_insights.main[0].id
      }
      allowed_origins                                = var.health_insights_api_cors_origins
      ftp_publish_basic_authentication_enabled       = false
      webdeploy_publish_basic_authentication_enabled = true
      ipv4_access                                    = var.health_insights_api_ipv4_allow_list
    }
  } : {}
  enable_linux_function_apps = (length(local.linux_function_apps) > 0 || length(keys(local.linux_function_health_insights_api)) > 0) ? true : false

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
  restrict_container_apps_to_agw_inbound_only     = var.restrict_container_apps_to_agw_inbound_only
  container_apps_allow_agw_resource               = var.container_apps_allow_agw_resource
  container_apps_allow_agw_pip_resource_id        = length(data.azurerm_application_gateway.existing_agw) > 0 ? split("/", data.azurerm_application_gateway.existing_agw[0].frontend_ip_configuration[0].public_ip_address_id) : null
  container_apps_allow_agw_ip                     = length(data.azurerm_application_gateway.existing_agw) > 0 ? data.azurerm_public_ip.existing_agw_ip[0].ip_address : ""
  container_apps_allow_ips_inbound                = var.container_apps_allow_ips_inbound
  cdn_frontdoor_host_redirects                    = var.cdn_frontdoor_host_redirects
  cdn_frontdoor_host_add_response_headers         = var.cdn_frontdoor_host_add_response_headers
  cdn_frontdoor_remove_response_headers           = var.cdn_frontdoor_remove_response_headers
  ruleset_redirects_id                            = length(local.cdn_frontdoor_host_redirects) > 0 ? [azurerm_cdn_frontdoor_rule_set.redirects[0].id] : []
  ruleset_add_response_headers_id                 = length(local.cdn_frontdoor_host_add_response_headers) > 0 ? [azurerm_cdn_frontdoor_rule_set.add_response_headers[0].id] : []
  ruleset_remove_response_headers_id              = length(local.cdn_frontdoor_remove_response_headers) > 0 ? [azurerm_cdn_frontdoor_rule_set.remove_response_headers[0].id] : []
  ruleset_vdp_id                                  = local.enable_cdn_frontdoor_vdp_redirects ? [azurerm_cdn_frontdoor_rule_set.vdp[0].id] : []
  ruleset_ids = concat(
    local.ruleset_redirects_id,
    local.ruleset_add_response_headers_id,
    local.ruleset_remove_response_headers_id,
    local.ruleset_vdp_id
  )
  cdn_frontdoor_enable_rate_limiting              = var.cdn_frontdoor_enable_rate_limiting
  cdn_frontdoor_rate_limiting_duration_in_minutes = var.cdn_frontdoor_rate_limiting_duration_in_minutes
  cdn_frontdoor_rate_limiting_threshold           = var.cdn_frontdoor_rate_limiting_threshold
  cdn_frontdoor_enable_waf                        = local.enable_cdn_frontdoor && local.cdn_frontdoor_enable_rate_limiting
  cdn_frontdoor_waf_mode                          = var.cdn_frontdoor_waf_mode
  cdn_frontdoor_waf_custom_rules                  = var.cdn_frontdoor_waf_custom_rules
  cdn_frontdoor_waf_managed_rulesets              = var.cdn_frontdoor_waf_managed_rulesets
  cdn_frontdoor_rate_limiting_bypass_ip_list      = var.cdn_frontdoor_rate_limiting_bypass_ip_list
  enable_cdn_frontdoor_vdp_redirects              = var.enable_cdn_frontdoor_vdp_redirects
  cdn_frontdoor_vdp_destination_hostname          = var.cdn_frontdoor_vdp_destination_hostname

  # Event Hub
  enable_event_hub                          = var.enable_event_hub
  enable_logstash_consumer                  = var.enable_logstash_consumer
  eventhub_export_log_analytics_table_names = var.eventhub_export_log_analytics_table_names

  # Application Insights
  enable_app_insights_integration      = var.enable_app_insights_integration
  app_insights_retention_days          = var.app_insights_retention_days
  app_insights_smart_detection_enabled = var.app_insights_smart_detection_enabled

  # Azure Monitor
  enable_monitoring = var.enable_monitoring
  # Azure Monitor / Logic App Workflow
  existing_logic_app_workflow     = var.existing_logic_app_workflow
  logic_app_workflow_name         = local.existing_logic_app_workflow.name == "" ? "" : data.azurerm_logic_app_workflow.existing_logic_app_workflow[0].name
  logic_app_workflow_id           = local.existing_logic_app_workflow.name == "" ? "" : data.azurerm_logic_app_workflow.existing_logic_app_workflow[0].id
  logic_app_workflow_callback_url = local.existing_logic_app_workflow.name == "" ? "" : data.azapi_resource_action.existing_logic_app_workflow_callback_url[0].output.value
  monitor_email_receivers         = var.monitor_email_receivers
  monitor_endpoint_healthcheck    = var.monitor_endpoint_healthcheck
  monitor_http_availability_fqdn = var.monitor_http_availability_fqdn == "" ? local.enable_cdn_frontdoor ? (
    length(local.cdn_frontdoor_custom_domains) >= 1 ? local.cdn_frontdoor_custom_domains[0] : azurerm_cdn_frontdoor_endpoint.endpoint[0].host_name
  ) : local.container_fqdn : var.monitor_http_availability_fqdn
  monitor_http_availability_url  = "https://${local.monitor_http_availability_fqdn}${local.monitor_endpoint_healthcheck}"
  monitor_http_availability_verb = var.monitor_http_availability_verb
  monitor_default_container      = { "default" = azurerm_container_app.container_apps["main"] }
  monitor_worker_container       = local.enable_worker_container ? { "worker" = azurerm_container_app.container_apps["worker"] } : {}
  monitor_containers = merge(
    local.monitor_default_container,
    local.monitor_worker_container,
    {
      for name, container in local.custom_container_apps : name => azurerm_container_app.custom_container_apps[name]
    }
  )
  monitor_logic_app_receiver = {
    name         = local.logic_app_workflow_name
    resource_id  = local.logic_app_workflow_id
    callback_url = local.logic_app_workflow_callback_url
  }
  enable_monitoring_traces                  = var.enable_monitoring_traces
  enable_monitoring_traces_include_warnings = var.enable_monitoring_traces_include_warnings

  # Azure Monitor / Alarm thresholds
  alarm_cpu_threshold_percentage    = var.alarm_cpu_threshold_percentage
  alarm_memory_threshold_percentage = var.alarm_memory_threshold_percentage
  alarm_latency_threshold_ms        = var.alarm_latency_threshold_ms
  alarm_log_ingestion_gb_per_day    = var.alarm_log_ingestion_gb_per_day
  alarm_for_delete_events           = var.alarm_for_delete_events

  # Network Watcher
  enable_network_watcher                                        = var.enable_network_watcher
  existing_network_watcher_name                                 = var.existing_network_watcher_name
  existing_network_watcher_resource_group_name                  = var.existing_network_watcher_resource_group_name
  network_watcher_name                                          = local.enable_network_watcher ? azurerm_network_watcher.default[0].name : local.existing_network_watcher_name
  network_watcher_resource_group_name                           = local.network_watcher_name != "" ? local.existing_network_watcher_resource_group_name : local.resource_group.name
  network_watcher_flow_log_retention                            = var.network_watcher_flow_log_retention
  enable_network_watcher_traffic_analytics                      = var.enable_network_watcher_traffic_analytics
  network_watcher_traffic_analytics_interval                    = var.network_watcher_traffic_analytics_interval
  network_watcher_nsg_storage_access_key_rotation_reminder_days = var.network_watcher_nsg_storage_access_key_rotation_reminder_days != 0 ? var.network_watcher_nsg_storage_access_key_rotation_reminder_days : local.storage_account_access_key_rotation_reminder_days

  # App Configuration
  enable_app_configuration      = var.enable_app_configuration
  app_configuration_sku         = var.app_configuration_sku
  app_configuration_assign_role = var.app_configuration_assign_role
}
