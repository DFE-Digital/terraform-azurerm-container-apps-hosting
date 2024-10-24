variable "environment" {
  description = "Environment name. Will be used along with `project_name` as a prefix for all resources."
  type        = string
}

variable "project_name" {
  description = "Project name. Will be used along with `environment` as a prefix for all resources."
  type        = string
}

variable "azure_location" {
  description = "Azure location in which to launch resources."
  type        = string
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "launch_in_vnet" {
  description = "Conditionally launch into a VNet"
  type        = bool
  default     = true
}

variable "existing_virtual_network" {
  description = "Conditionally use an existing virtual network. The `virtual_network_address_space` must match an existing address space in the VNet. This also requires the resource group name."
  type        = string
  default     = ""
}

variable "existing_resource_group" {
  description = "Conditionally launch resources into an existing resource group. Specifying this will NOT create a resource group."
  type        = string
  default     = ""
}

variable "enable_resource_group_lock" {
  description = "Enabling this will add a Resource Lock to the Resource Group preventing any resources from being deleted."
  type        = bool
  default     = false
}

variable "virtual_network_address_space" {
  description = "Virtual Network address space CIDR"
  type        = string
  default     = "172.16.0.0/12"
}

variable "enable_container_registry" {
  description = "Set to true to create a container registry"
  type        = bool
}

variable "registry_server" {
  description = "Container registry server (required if `enable_container_registry` is false)"
  type        = string
  default     = ""
}

variable "registry_username" {
  description = "Container registry username (required if `enable_container_registry` is false)"
  type        = string
  default     = ""
}

variable "registry_password" {
  description = "Container registry password (required if `enable_container_registry` is false)"
  type        = string
  default     = ""
}

variable "registry_sku" {
  description = "The SKU name of the container registry. Possible values are 'Basic', 'Standard' and 'Premium'."
  type        = string
  default     = "Standard"
}

variable "registry_retention_days" {
  description = "The number of days to retain an untagged manifest after which it gets purged"
  type        = number
  default     = 7
}

variable "enable_registry_retention_policy" {
  description = "Boolean value that indicates whether the policy is enabled"
  type        = bool
  default     = false
}

variable "registry_admin_enabled" {
  description = "Do you want to enable access key based authentication for your Container Registry?"
  type        = bool
  default     = true
}

variable "registry_public_access_enabled" {
  description = "Should your Container Registry be publicly accessible?"
  type        = bool
  default     = true
}

variable "registry_ipv4_allow_list" {
  description = "List of IPv4 CIDR blocks that require access to the Container Registry"
  type        = list(string)
  default     = []
}

variable "registry_use_managed_identity" {
  description = "Create a User-Assigned Managed Identity for the Container App. Note: If you do not have 'Microsoft.Authorization/roleAssignments/write' permission, you will need to manually assign the 'AcrPull' Role to the identity"
  type        = bool
  default     = false
}

variable "registry_managed_identity_assign_role" {
  description = "Assign the 'AcrPull' Role to the Container App User-Assigned Managed Identity. Note: If you do not have 'Microsoft.Authorization/roleAssignments/write' permission, you will need to manually assign the 'AcrPull' Role to the identity"
  type        = bool
  default     = true
}

variable "enable_mssql_database" {
  description = "Set to true to create an Azure SQL server/database, with a private endpoint within the virtual network"
  type        = bool
  default     = false
}

variable "mssql_server_admin_password" {
  description = "The local administrator password for the MSSQL server"
  type        = string
  default     = ""
  sensitive   = true
}

variable "mssql_azuread_admin_username" {
  description = "Username of a User within Azure AD that you want to assign as the SQL Server Administrator"
  type        = string
  default     = ""
}

variable "mssql_azuread_admin_object_id" {
  description = "Object ID of a User within Azure AD that you want to assign as the SQL Server Administrator"
  type        = string
  default     = ""
}

variable "mssql_azuread_auth_only" {
  description = "Set to true to only permit SQL logins from Azure AD users"
  type        = bool
  default     = false
}

variable "mssql_sku_name" {
  description = "Specifies the name of the SKU used by the database"
  type        = string
  default     = "Basic"
}

variable "mssql_max_size_gb" {
  description = "The max size of the database in gigabytes"
  type        = number
  default     = 2
}

variable "mssql_database_name" {
  description = "The name of the MSSQL database to create. Must be set if `enable_mssql_database` is true"
  type        = string
  default     = ""
}

variable "mssql_firewall_ipv4_allow_list" {
  description = "A list of IPv4 Addresses that require remote access to the MSSQL Server"
  type = map(object({
    start_ip_range : string,
    end_ip_range : optional(string, "")
  }))
  default = {}
}

variable "mssql_server_public_access_enabled" {
  description = "Enable public internet access to your MSSQL instance. Be sure to specify 'mssql_firewall_ipv4_allow_list' to restrict inbound connections"
  type        = bool
  default     = false
}

variable "mssql_version" {
  description = "Specify the version of Microsoft SQL Server you want to run"
  type        = string
  default     = "12.0"
}

variable "enable_mssql_vulnerability_assessment" {
  description = "Vulnerability assessment can discover, track, and help you remediate potential database vulnerabilities"
  type        = bool
  default     = true
}

variable "mssql_security_storage_firewall_ipv4_allow_list" {
  description = "Additional IP addresses to add to the Storage Account that holds the Vulnerability Assessments"
  type        = list(string)
  default     = []
}

variable "mssql_managed_identity_assign_role" {
  description = "Assign the 'Storage Blob Data Contributor' Role to the SQL Server User-Assigned Managed Identity. Note: If you do not have 'Microsoft.Authorization/roleAssignments/write' permission, you will need to manually assign the 'Storage Blob Data Contributor' Role to the identity"
  type        = bool
  default     = true
}

variable "enable_postgresql_database" {
  type        = bool
  description = "Set to true to create an Azure Postgres server/database, with a private endpoint within the virtual network"
  default     = false
}

variable "postgresql_server_version" {
  type        = string
  description = "Specify the version of postgres server to run (either 11,12,13 or 14)"
  default     = ""
}

variable "postgresql_administrator_login" {
  type        = string
  description = "Specify a login that will be assigned to the administrator when creating the Postgres server"
  default     = ""
}

variable "postgresql_administrator_password" {
  type        = string
  description = "Specify a password that will be assigned to the administrator when creating the Postgres server"
  default     = ""
}

variable "postgresql_availability_zone" {
  type        = string
  description = "Specify the availibility zone in which the Postgres server should be located"
  default     = "1"
}

variable "postgresql_max_storage_mb" {
  type        = number
  description = "Specify the max amount of storage allowed for the Postgres server"
  default     = 32768
}

variable "postgresql_sku_name" {
  type        = string
  description = "Specify the SKU to be used for the Postgres server"
  default     = "B_Standard_B1ms"
}

variable "postgresql_collation" {
  type        = string
  description = "Specify the collation to be used for the Postgres database"
  default     = "en_US.utf8"
}

variable "postgresql_charset" {
  type        = string
  description = "Specify the charset to be used for the Postgres database"
  default     = "utf8"
}

variable "postgresql_enabled_extensions" {
  type        = string
  description = "Specify a comma seperated list of Postgres extensions to enable. See https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-extensions#postgres-14-extensions"
  default     = ""
}

variable "postgresql_network_connectivity_method" {
  type        = string
  description = "Specify postgresql networking method, public or private. See https://learn.microsoft.com/en-gb/azure/postgresql/flexible-server/concepts-networking"
  default     = "private"
  validation {
    condition     = contains(["public", "private"], var.postgresql_network_connectivity_method)
    error_message = "Valid values for postgresql_network_connectivity_method are public or private."
  }
}

variable "postgresql_firewall_ipv4_allow" {
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  description = "Map of IP address ranges to add into the postgres firewall. Note: only applicable if postgresql_network_connectivity_method is set to public."
  default     = {}
}

variable "enable_redis_cache" {
  description = "Set to true to create an Azure Redis Cache, with a private endpoint within the virtual network"
  type        = bool
  default     = false
}

variable "redis_cache_family" {
  description = "Redis Cache family"
  type        = string
  default     = "C"
}

variable "redis_cache_sku" {
  description = "Redis Cache SKU"
  type        = string
  default     = "Basic"
}

variable "redis_cache_capacity" {
  description = "Redis Cache Capacity"
  type        = number
  default     = 0
}

variable "redis_cache_patch_schedule_day" {
  description = "Redis Cache patch schedule day"
  type        = string
  default     = "Sunday"
}

variable "redis_cache_patch_schedule_hour" {
  description = "Redis Cache patch schedule hour"
  type        = number
  default     = 18
}

variable "redis_cache_version" {
  description = "Redis Cache version"
  type        = number
  default     = 6
}

variable "redis_cache_firewall_ipv4_allow_list" {
  description = "A list of IPv4 address that require remote access to the Redis server"
  type        = list(string)
  default     = []
}

variable "redis_config" {
  description = "Overrides for Redis Cache Configuration options"
  type = object({
    maxmemory_reserved : optional(number),
    maxmemory_delta : optional(number),
    maxfragmentationmemory_reserved : optional(number),
    maxmemory_policy : optional(string),
  })
  default = {}
}

variable "image_name" {
  description = "Image name"
  type        = string
}

variable "image_tag" {
  description = "Image tag"
  type        = string
  default     = "latest"
}

variable "container_cpu" {
  description = "Number of container CPU cores"
  type        = number
  default     = 1
}

variable "container_memory" {
  description = "Container memory in GB"
  type        = number
  default     = 2
}

variable "container_min_replicas" {
  description = "Container min replicas"
  type        = number
  default     = 1
}

variable "container_max_replicas" {
  description = "Container max replicas"
  type        = number
  default     = 2
}

variable "container_scale_out_at_defined_time" {
  description = "Should the Container App scale out to the max-replicas during a specified time window?"
  type        = bool
  default     = false
}

variable "container_scale_out_rule_start" {
  description = "Specify a time using Linux cron format that represents the start of the scale-out window. Defaults to 08:00"
  type        = string
  default     = "0 8 * * *"
}

variable "container_scale_out_rule_end" {
  description = "Specify a time using Linux cron format that represents the end of the scale-out window. Defaults to 18:00"
  type        = string
  default     = "0 18 * * *"
}

variable "container_scale_http_concurrency" {
  description = "When the number of concurrent HTTP requests exceeds this value, then another replica is added. Replicas continue to add to the pool up to the max-replicas amount."
  type        = number
  default     = 10
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 80
}

variable "container_app_name_override" {
  type        = string
  description = "A custom name for the Container App"
  default     = ""
}

variable "enable_container_health_probe" {
  description = "Enable liveness probes for the Container"
  type        = bool
  default     = true
}

variable "container_health_probe_interval" {
  description = "How often in seconds to poll the Container to determine liveness"
  type        = number
  default     = 30
}

variable "container_health_probe_path" {
  description = "Specifies the path that is used to determine the liveness of the Container"
  type        = string
  default     = "/"
}

variable "container_health_probe_protocol" {
  description = "Use HTTPS or a TCP connection for the Container liveness probe"
  type        = string
  default     = "http"
}

variable "container_command" {
  description = "Container command"
  type        = list(any)
  default     = []
}

variable "container_environment_variables" {
  description = "Container environment variables"
  type        = map(string)
  default     = {}
}

variable "container_secret_environment_variables" {
  description = "Container environment variables, which are defined as `secrets` within the container app configuration. This is to help reduce the risk of accidentally exposing secrets."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "enable_worker_container" {
  description = "Conditionally launch a worker container. This container uses the same image and environment variables as the default container app, but allows a different container command to be run. The worker container does not expose any ports."
  type        = bool
  default     = false
}

variable "worker_container_command" {
  description = "Container command for the Worker container. `enable_worker_container` must be set to true for this to have any effect."
  type        = list(string)
  default     = []
}

variable "worker_container_min_replicas" {
  description = "Worker container min replicas"
  type        = number
  default     = 1
}

variable "worker_container_max_replicas" {
  description = "Worker ontainer max replicas"
  type        = number
  default     = 2
}

variable "enable_dns_zone" {
  description = "Conditionally create a DNS zone"
  type        = bool
  default     = false
}

variable "dns_zone_domain_name" {
  description = "DNS zone domain name. If created, records will automatically be created to point to the CDN."
  type        = string
  default     = ""
}

variable "dns_zone_soa_record" {
  description = "DNS zone SOA record block (https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_zone#soa_record)"
  type        = map(string)
  default     = {}
}

variable "dns_a_records" {
  description = "DNS A records to add to the DNS Zone"
  type = map(
    object({
      ttl : optional(number, 300),
      records : list(string)
    })
  )
  default = {}
}

variable "dns_alias_records" {
  description = "DNS ALIAS records to add to the DNS Zone"
  type = map(
    object({
      ttl : optional(number, 300),
      target_resource_id : string
    })
  )
  default = {}
}

variable "dns_aaaa_records" {
  description = "DNS AAAA records to add to the DNS Zone"
  type = map(
    object({
      ttl : optional(number, 300),
      records : list(string)
    })
  )
  default = {}
}

variable "dns_caa_records" {
  description = "DNS CAA records to add to the DNS Zone"
  type = map(
    object({
      ttl : optional(number, 300),
      records : list(
        object({
          flags : number,
          tag : string,
          value : string
        })
      )
    })
  )
  default = {}
}

variable "dns_cname_records" {
  description = "DNS CNAME records to add to the DNS Zone"
  type = map(
    object({
      ttl : optional(number, 300),
      record : string
    })
  )
  default = {}
}

variable "dns_mx_records" {
  description = "DNS MX records to add to the DNS Zone"
  type = map(
    object({
      ttl : optional(number, 300),
      records : list(
        object({
          preference : number,
          exchange : string
        })
      )
    })
  )
  default = {}
}

variable "dns_ns_records" {
  description = "DNS NS records to add to the DNS Zone"
  type = map(
    object({
      ttl : optional(number, 300),
      records : list(string)
    })
  )
  default = {}
}

variable "dns_ptr_records" {
  description = "DNS PTR records to add to the DNS Zone"
  type = map(
    object({
      ttl : optional(number, 300),
      records : list(string)
    })
  )
  default = {}
}

variable "dns_srv_records" {
  description = "DNS SRV records to add to the DNS Zone"
  type = map(
    object({
      ttl : optional(number, 300),
      records : list(
        object({
          priority : number,
          weight : number,
          port : number,
          target : string
        })
      )
    })
  )
  default = {}
}

variable "dns_txt_records" {
  description = "DNS TXT records to add to the DNS Zone"
  type = map(
    object({
      ttl : optional(number, 300),
      records : list(string)
    })
  )
  default = {}
}

variable "enable_cdn_frontdoor" {
  description = "Enable Azure CDN Front Door. This will use the Container Apps endpoint as the origin."
  type        = bool
  default     = false
}

variable "cdn_frontdoor_enable_waf_logs" {
  description = "Toggle the Diagnostic Setting to log Web Application Firewall requests"
  type        = bool
  default     = true
}

variable "cdn_frontdoor_enable_access_logs" {
  description = "Toggle the Diagnostic Setting to log Access requests"
  type        = bool
  default     = false
}

variable "cdn_frontdoor_enable_health_probe_logs" {
  description = "Toggle the Diagnostic Setting to log Health Probe requests"
  type        = bool
  default     = false
}

variable "restrict_container_apps_to_cdn_inbound_only" {
  description = "Restricts access to the Container Apps by creating a network security group rule that only allows 'AzureFrontDoor.Backend' inbound, and attaches it to the subnet of the container app environment."
  type        = bool
  default     = true
}

variable "container_apps_allow_ips_inbound" {
  description = "Restricts access to the Container Apps by creating a network security group rule that only allow inbound traffic from the provided list of IPs"
  type        = list(string)
  default     = []
}

variable "container_app_environment_internal_load_balancer_enabled" {
  description = "Should the Container Environment operate in Internal Load Balancing Mode?"
  type        = bool
  default     = false
}

variable "cdn_frontdoor_sku" {
  description = "Azure CDN Front Door SKU"
  type        = string
  default     = "Standard_AzureFrontDoor"
}

variable "enable_cdn_frontdoor_health_probe" {
  description = "Enable CDN Front Door health probe"
  type        = bool
  default     = true
}

variable "cdn_frontdoor_health_probe_protocol" {
  description = "Use Http or Https"
  type        = string
  default     = "Https"
}

variable "cdn_frontdoor_health_probe_interval" {
  description = "Specifies the number of seconds between health probes."
  type        = number
  default     = 120
}

variable "cdn_frontdoor_health_probe_path" {
  description = "Specifies the path relative to the origin that is used to determine the health of the origin."
  type        = string
  default     = "/"
}

variable "cdn_frontdoor_health_probe_request_type" {
  description = "Specifies the type of health probe request that is made."
  type        = string
  default     = "GET"
}

variable "cdn_frontdoor_response_timeout" {
  description = "Azure CDN Front Door response timeout in seconds"
  type        = number
  default     = 120
}

variable "cdn_frontdoor_custom_domains" {
  description = "Azure CDN Front Door custom domains"
  type        = list(string)
  default     = []
}

variable "cdn_frontdoor_custom_domains_create_dns_records" {
  description = "Should the TXT records and ALIAS/CNAME records be automatically created if the custom domains exist within the DNS Zone?"
  type        = bool
  default     = true
}

variable "cdn_frontdoor_host_redirects" {
  description = "CDN FrontDoor host redirects `[{ \"from\" = \"example.com\", \"to\" = \"www.example.com\" }]`"
  type        = list(map(string))
  default     = []
}

variable "cdn_frontdoor_enable_rate_limiting" {
  description = "Enable CDN Front Door Rate Limiting. This will create a WAF policy, and CDN security policy. For pricing reasons, there will only be one WAF policy created."
  type        = bool
  default     = false
}

variable "cdn_frontdoor_rate_limiting_duration_in_minutes" {
  description = "CDN Front Door rate limiting duration in minutes"
  type        = number
  default     = 1
}

variable "cdn_frontdoor_rate_limiting_threshold" {
  description = "Maximum number of concurrent requests before Rate Limiting policy is applied"
  type        = number
  default     = 300
}

variable "cdn_frontdoor_rate_limiting_bypass_ip_list" {
  description = "List if IP CIDRs to bypass CDN Front Door rate limiting"
  type        = list(string)
  default     = []
}

variable "cdn_frontdoor_waf_mode" {
  description = "CDN Front Door waf mode"
  type        = string
  default     = "Prevention"
}

variable "cdn_frontdoor_host_add_response_headers" {
  description = "List of response headers to add at the CDN Front Door `[{ \"Name\" = \"Strict-Transport-Security\", \"value\" = \"max-age=31536000\" }]`"
  type        = list(map(string))
  default     = []
}

variable "cdn_frontdoor_remove_response_headers" {
  description = "List of response headers to remove at the CDN Front Door"
  type        = list(string)
  default     = []
}

variable "cdn_frontdoor_origin_fqdn_override" {
  description = "Manually specify the hostname that the CDN Front Door should target. Defaults to the Container App FQDN"
  type        = string
  default     = ""
}

variable "cdn_frontdoor_origin_host_header_override" {
  description = "Manually specify the host header that the CDN sends to the target. Defaults to the recieved host header. Set to null to set it to the host_name (`cdn_frontdoor_origin_fqdn_override`)"
  type        = string
  default     = ""
  nullable    = true
}

variable "cdn_frontdoor_origin_http_port" {
  description = "The value of the HTTP port used for the CDN Origin. Must be between 1 and 65535. Defaults to 80"
  type        = number
  default     = 80
}

variable "cdn_frontdoor_origin_https_port" {
  description = "The value of the HTTPS port used for the CDN Origin. Must be between 1 and 65535. Defaults to 443"
  type        = number
  default     = 443
}

variable "cdn_frontdoor_forwarding_protocol" {
  description = "Azure CDN Front Door forwarding protocol"
  type        = string
  default     = "HttpsOnly"
}

variable "cdn_frontdoor_waf_custom_rules" {
  description = "Map of all Custom rules you want to apply to the CDN WAF"
  type = map(object({
    priority : number,
    action : string
    match_conditions : map(object({
      match_variable : string,
      match_values : optional(list(string), []),
      operator : optional(string, "Any"),
      selector : optional(string, null),
      negation_condition : optional(bool, false),
    }))
  }))
  default = {}
}

variable "cdn_frontdoor_waf_managed_rulesets" {
  description = "Map of all Managed rules you want to apply to the CDN WAF, including any overrides, or exclusions"
  type = map(object({
    version : string,
    action : optional(string, "Block"),
    exclusions : optional(map(object({
      match_variable : string,
      operator : string,
      selector : string
    })), {})
    overrides : optional(map(map(object({
      action : string,
      enabled : optional(bool, true),
      exclusions : optional(map(object({
        match_variable : string,
        operator : string,
        selector : string
      })), {})
    }))), {})
  }))
  default = {}
}

variable "enable_event_hub" {
  description = "Send Azure Container App logs to an Event Hub sink"
  type        = bool
  default     = false
}

variable "enable_logstash_consumer" {
  description = "Create an Event Hub consumer group for Logstash"
  type        = bool
  default     = false
}

variable "eventhub_export_log_analytics_table_names" {
  description = "List of Log Analytics table names that you want to export to Event Hub. See https://learn.microsoft.com/en-gb/azure/azure-monitor/logs/logs-data-export?tabs=portal#supported-tables for a list of supported tables"
  type        = list(string)
  default     = []
}

variable "enable_app_insights_integration" {
  description = "Deploy an App Insights instance and connect your Container Apps to it"
  type        = bool
  default     = true
}

variable "app_insights_retention_days" {
  description = "Number of days to retain App Insights data for (Default: 2 years)"
  type        = number
  default     = 730
}

variable "app_insights_smart_detection_enabled" {
  description = "Enable or Disable Smart Detection with App Insights"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Create an App Insights instance and notification group for the Container App"
  type        = bool
  default     = false
}

variable "monitor_email_receivers" {
  description = "A list of email addresses that should be notified by monitoring alerts"
  type        = list(string)
  default     = []
}

variable "existing_logic_app_workflow" {
  description = "Name, Resource Group and HTTP Trigger URL of an existing Logic App Workflow to route Alerts to"
  type = object({
    name : string
    resource_group_name : string
  })
  default = {
    name                = ""
    resource_group_name = ""
  }
}

variable "monitor_endpoint_healthcheck" {
  description = "Specify a route that should be monitored for a 200 OK status"
  type        = string
  default     = "/"
}

variable "alarm_log_ingestion_gb_per_day" {
  description = "Define an alarm threshold for Log Analytics ingestion rate in GB (per day) (Defaults to no limit)"
  type        = number
  default     = 0
}

variable "alarm_cpu_threshold_percentage" {
  description = "Specify a number (%) which should be set as a threshold for a CPU usage monitoring alarm"
  type        = number
  default     = 80
}

variable "alarm_memory_threshold_percentage" {
  description = "Specify a number (%) which should be set as a threshold for a memory usage monitoring alarm"
  type        = number
  default     = 80
}

variable "alarm_latency_threshold_ms" {
  description = "Specify a number in milliseconds which should be set as a threshold for a request latency monitoring alarm"
  type        = number
  default     = 1000
}

variable "enable_network_watcher" {
  description = "Enable network watcher. Note: only 1 network watcher per subscription can be created."
  type        = bool
  default     = false
}

variable "existing_network_watcher_name" {
  description = "Use an existing network watcher to add flow logs."
  type        = string
  default     = ""
}

variable "existing_network_watcher_resource_group_name" {
  description = "Existing network watcher resource group."
  type        = string
  default     = ""
}

variable "network_watcher_flow_log_retention" {
  description = "Number of days to retain flow logs. Set to 0 to keep all logs."
  type        = number
  default     = 90
}

variable "enable_network_watcher_traffic_analytics" {
  description = "Enable network watcher traffic analytics (Requires `enable_network_watcher` to be true)"
  type        = bool
  default     = true
}

variable "network_watcher_traffic_analytics_interval" {
  description = "Interval in minutes for Traffic Analytics."
  type        = number
  default     = 60
}

variable "enable_container_app_blob_storage" {
  description = "Create an Azure Storage Account and Storage Container to be used for this app"
  type        = bool
  default     = false
}

variable "container_app_blob_storage_public_access_enabled" {
  description = "Enable anonymous public read access to blobs in Azure Storage?"
  type        = bool
  default     = false
}

variable "enable_container_app_file_share" {
  description = "Create an Azure Storage Account and File Share to be mounted to the Container Apps"
  type        = bool
  default     = false
}

variable "storage_account_public_access_enabled" {
  description = "Should the Azure Storage Account have Public visibility?"
  type        = bool
  default     = false
}

variable "storage_account_sas_expiration_period" {
  description = "The SAS expiration period in format of DD.HH:MM:SS"
  type        = string
  default     = "02.00:00:00"
}

variable "container_app_storage_account_shared_access_key_enabled" {
  description = "Should the storage account for the container app permit requests to be authorized with the account access key via Shared Key?"
  type        = bool
  default     = true
}

variable "mssql_storage_account_shared_access_key_enabled" {
  description = "Should the storage account for mssql security permit requests to be authorized with the account access key via Shared Key?"
  type        = bool
  default     = true
}

variable "storage_account_file_share_quota_gb" {
  description = "The maximum size of the share, in gigabytes."
  type        = number
  default     = 2
}

variable "container_app_file_share_mount_path" {
  description = "A path inside your container where the File Share will be mounted to"
  type        = string
  default     = "/srv/app/storage"
}

variable "storage_account_ipv4_allow_list" {
  description = "A list of public IPv4 address to grant access to the Storage Account"
  type        = list(string)
  default     = []
}

variable "custom_container_apps" {
  description = "Custom container apps, by default deployed within the container app environment managed by this module."
  type = map(object({
    container_app_environment_id = optional(string, "")
    resource_group_name          = optional(string, "")
    revision_mode                = optional(string, "Single")
    container_port               = optional(number, 0)
    ingress = optional(object({
      external_enabled = optional(bool, true)
      target_port      = optional(number, null)
      traffic_weight = object({
        percentage = optional(number, 100)
      })
      cdn_frontdoor_custom_domain                = optional(string, "")
      cdn_frontdoor_origin_fqdn_override         = optional(string, "")
      cdn_frontdoor_origin_host_header_override  = optional(string, "")
      enable_cdn_frontdoor_health_probe          = optional(bool, false)
      cdn_frontdoor_health_probe_protocol        = optional(string, "")
      cdn_frontdoor_health_probe_interval        = optional(number, 120)
      cdn_frontdoor_health_probe_request_type    = optional(string, "")
      cdn_frontdoor_health_probe_path            = optional(string, "")
      cdn_frontdoor_forwarding_protocol_override = optional(string, "")
    }), null)
    identity = optional(list(object({
      type         = string
      identity_ids = list(string)
    })), [])
    secrets = optional(list(object({
      name  = string
      value = string
    })), [])
    registry = optional(object({
      server               = optional(string, "")
      username             = optional(string, "")
      password_secret_name = optional(string, "")
      identity             = optional(string, "")
    }), null),
    image   = string
    cpu     = number
    memory  = number
    command = list(string)
    liveness_probes = optional(list(object({
      interval_seconds = number
      transport        = string
      port             = number
      path             = optional(string, null)
    })), [])
    env = optional(list(object({
      name      = string
      value     = optional(string, null)
      secretRef = optional(string, null)
    })), [])
    min_replicas = number
    max_replicas = number
  }))
  default = {}
}

variable "container_apps_infra_subnet_service_endpoints" {
  description = "Endpoints to assign to infra subnet"
  type        = list(string)
  default     = []
}

variable "container_app_use_managed_identity" {
  description = "Deploy a User Assigned Managed Identity and attach it to the Container App"
  type        = bool
  default     = true
}

variable "container_app_identities" {
  description = "Additional User Assigned Managed Identity Resource IDs to attach to the Container App"
  type        = list(string)
  default     = []
}

variable "existing_key_vault" {
  description = "An existing Key Vault that you want to store Container App secrets in"
  type        = string
  default     = ""
}

variable "escrow_container_app_secrets_in_key_vault" {
  description = "Set sensitive Container App secrets in Key Vault"
  type        = bool
  default     = false
}

variable "key_vault_managed_identity_assign_role" {
  description = "Assign the Key Vault Secret User role to the Container App managed identity"
  type        = bool
  default     = false
}

variable "key_vault_access_ipv4" {
  description = "List of IPv4 Addresses that are permitted to access the Key Vault"
  type        = list(string)
  default     = []
}

variable "storage_account_access_key_rotation_reminder_days" {
  description = "Number of days to set for access key rotation reminder on Storage Accounts"
  type        = number
  default     = 90
}

variable "mssql_security_storage_access_key_rotation_reminder_days" {
  description = "Number of days to set for access key rotation reminder on the SQL Security Storage Account. If not set will default to 'storage_account_access_key_rotation_reminder_days'"
  type        = number
  default     = 0
}

variable "network_watcher_nsg_storage_access_key_rotation_reminder_days" {
  description = "Number of days to set for access key rotation reminder on the Network Watcher NSG Flow Log Storage Account. If not set will default to 'storage_account_access_key_rotation_reminder_days'"
  type        = number
  default     = 0
}

variable "container_app_storage_cross_tenant_replication_enabled" {
  description = "Should cross Tenant replication be enabled?"
  type        = bool
  default     = false
}

variable "mssql_security_storage_cross_tenant_replication_enabled" {
  description = "Should cross Tenant replication be enabled?"
  type        = bool
  default     = false
}

variable "create_container_app_blob_storage_sas" {
  description = "Generate a SAS connection string that is exposed to your App as an environment variable so that it can connect to the Storage Account"
  type        = bool
  default     = true
}

variable "container_app_file_share_security_profile" {
  description = "Choose whether the SMB protocol should be configured for maximum security, or maximum compatibility"
  type        = string
  default     = "security"
  validation {
    condition     = contains(["security", "compatibility"], lower(var.container_app_file_share_security_profile))
    error_message = "Valid values for container_app_file_share_security_profile are 'security' or 'compatibility'."
  }
}

variable "enable_app_configuration" {
  description = "Deploy an Azure App Configuration resource"
  type        = bool
  default     = false
}

variable "app_configuration_sku" {
  description = "The SKU name of the App Configuration. Possible values are free and standard. Defaults to free."
  type        = string
  default     = "free"
}

variable "app_configuration_assign_role" {
  description = "Assign the 'App Configuration Data Reader' Role to the Container App User-Assigned Managed Identity. Note: If you do not have 'Microsoft.Authorization/roleAssignments/write' permission, you will need to manually assign the 'App Configuration Data Reader' Role to the identity"
  type        = bool
  default     = false
}

variable "enable_init_container" {
  description = "Deploy an Init Container. Init containers run before the primary app container and are used to perform initialization tasks such as downloading data or preparing the environment"
  type        = bool
  default     = false
}

variable "init_container_image" {
  description = "Image name for the Init Container. Leave blank to use the same Container image from the primary app"
  type        = string
  default     = ""
}

variable "init_container_command" {
  description = "Container command for the Init Container"
  type        = list(any)
  default     = []
}

variable "enable_health_insights_api" {
  description = "Deploys a Function App that exposes the last 3 HTTP Web Tests via an API endpoint. 'enable_app_insights_integration' and 'enable_monitoring' must be set to 'true'."
  type        = bool
  default     = false
}

variable "health_insights_api_cors_origins" {
  description = "List of hostnames that are permitted to contact the Health insights API"
  type        = list(string)
  default     = ["*"]
}

variable "health_insights_api_ipv4_allow_list" {
  description = "List of IPv4 addresses that are permitted to contact the Health insights API"
  type        = list(string)
  default     = []
}

variable "enable_cdn_frontdoor_vdp_redirects" {
  description = "Deploy redirects for security.txt and thanks.txt to an external Vulnerability Disclosure Program service"
  type        = bool
  default     = false
}

variable "cdn_frontdoor_vdp_destination_hostname" {
  description = "Requires 'enable_cdn_frontdoor_vdp_redirects' to be set to 'true'. Hostname to redirect security.txt and thanks.txt to"
  type        = string
  default     = ""
}

variable "linux_function_apps" {
  description = "A list of Linux Function Apps with their corresponding app settings"
  type = map(object({
    runtime                                        = string
    runtime_version                                = string
    app_settings                                   = optional(map(string), {})
    allowed_origins                                = optional(list(string), ["*"])
    ftp_publish_basic_authentication_enabled       = optional(bool, false)
    webdeploy_publish_basic_authentication_enabled = optional(bool, false)
    ipv4_access                                    = optional(list(string), [])
  }))
  default = {}
}
