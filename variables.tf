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

variable "enable_mssql_database" {
  description = "Set to true to create an Azure SQL server/database, with a private endpoint within the virtual network"
  type        = bool
  default     = false
}

variable "mssql_server_admin_password" {
  description = "The administrator password for the MSSQL server. Must be set if `enable_mssql_database` is true"
  type        = string
  default     = ""
  sensitive   = true
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
  default     = "Wednesday"
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

variable "container_scale_rule_concurrent_request_count" {
  description = "Maximum number of concurrent HTTP requests before a new replica is created"
  type        = number
  default     = 10
}

variable "container_scale_rule_scale_down_out_of_hours" {
  description = "Should the Container App scale down to the minReplicas outside of normal operating hours?"
  type        = bool
  default     = false
}

variable "container_scale_rule_out_of_hours_start" {
  description = "Specify a time using Linux cron format that represents the start of the out-of-hours window. Defaults to 23:00"
  type        = string
  default     = "0 23 * * *"
}

variable "container_scale_rule_out_of_hours_end" {
  description = "Specify a time using Linux cron format that represents the end of the out-of-hours window. Defaults to 06:00"
  type        = string
  default     = "0 6 * * *"
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 80
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

variable "enable_cdn_frontdoor" {
  description = "Enable Azure CDN Front Door. This will use the Container Apps endpoint as the origin."
  type        = bool
  default     = false
}

variable "restrict_container_apps_to_cdn_inbound_only" {
  description = "Restricts access to the Container Apps by creating a network security group that only allows 'AzureFrontDoor.Backend' inbound, and attaches it to the subnet of the container app environment."
  type        = bool
  default     = true
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
  description = "Azure CDN Front Door custom domains. If they are within the DNS zone (optionally created), the Validation TXT records and ALIAS/CNAME records will be created"
  type        = list(string)
  default     = []
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
  description = "CDN Front Door rate limiting duration in minutes"
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

variable "monitor_enable_slack_webhook" {
  description = "Enable slack webhooks to send monitoring notifications to a channel"
  type        = bool
  default     = false
}

variable "monitor_slack_webhook_receiver" {
  description = "A Slack App webhook URL"
  type        = string
  default     = ""
}

variable "monitor_slack_channel" {
  description = "Slack channel name/id to send messages to"
  type        = string
  default     = ""
}

variable "monitor_endpoint_healthcheck" {
  description = "Specify a route that should be monitored for a 200 OK status"
  type        = string
  default     = "/"
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
