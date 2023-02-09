# Azure Container Apps Hosting terraform module

[![Terraform CI](https://github.com/DFE-Digital/terraform-azurerm-container-apps-hosting/actions/workflows/continuous-integration-terraform.yml/badge.svg?branch=main)](https://github.com/DFE-Digital/terraform-azurerm-container-apps-hosting/actions/workflows/continuous-integration-terraform.yml?branch=main)
[![GitHub release](https://img.shields.io/github/release/DFE-Digital/terraform-azurerm-container-apps-hosting)](https://github.com/DFE-Digital/terraform-azurerm-container-apps-hosting/releases)

This module creates and manages [Azure Container Apps][1], deployed within an [Azure Virtual Network][2].

## Usage

```hcl
module "azure_container_apps_hosting" {
  source  = "github.com/DFE-Digital/terraform-azurerm-container-apps-hosting?ref=v0.13.3"

  environment    = "dev"
  project_name   = "myproject"
  azure_location = "uksouth"

  enable_container_registry = true

  image_name        = "myimage"
  container_command = ["/bin/bash", "-c". "echo hello && sleep 86400"]

  # Note: It is recommended to use `container_secret_environment_variables` rather than `container_environment_variables`.
  #       This ensures that environment variables are set as `secrets` within the container app revision.
  #       If they are set directly as `env`, they can be exposed when running `az containerapp` commands, especially
  #       if those commands are ran as part of CI/CD.
  container_secret_environment_variables = {
    "FOO" = "bar"
  }

  enable_mssql_database       = true
  mssql_server_admin_password = "S3crEt"
  mssql_database_name         = "mydatabase"

  enable_redis_cache              = true
  redis_cache_version             = 6
  redis_cache_family              = "C"
  redis_cache_sku                 = "Basic"
  redis_cache_capacity            = 0
  redis_cache_patch_schedule_day  = "Wednesday"
  redis_cache_patch_schedule_hour = 18

  enable_dns_zone      = true
  dns_zone_domain_name = "example.com"
  dns_zone_soa_record  = {
    email         = "hello.example.com"
    host_name     = "ns1-03.azure-dns.com."
    expire_time   = "2419200"
    minimum_ttl   = "300"
    refresh_time  = "3600"
    retry_time    = "300"
    serial_number = "1"
    ttl           = "3600"
  }

  enable_cdn_frontdoor                = true
  cdn_frontdoor_sku                   = "Standard_AzureFrontDoor"
  cdn_frontdoor_health_probe_interval = 30
  cdn_frontdoor_health_probe_path     = "/"
  cdn_frontdoor_response_timeout      = 120
  cdn_frontdoor_custom_domains = [
    "example.com",
    "www.example.com"
  ]
  cdn_frontdoor_host_redirects = [
    {
      "from" = "example.com",
      "to"   = "www.example.com",
    }
  ]
  cdn_frontdoor_enable_rate_limiting              = true
  cdn_frontdoor_rate_limiting_duration_in_minutes = 1
  cdn_frontdoor_rate_limiting_threshold           = 300
  cdn_frontdoor_rate_limiting_bypass_ip_list      = ["8.8.8.8/32"]
  cdn_frontdoor_waf_mode                          = "Prevention"
  cdn_frontdoor_host_add_response_headers = [
    {
      "name"  = "Strict-Transport-Security",
      "value" = "max-age=31536000",
    }
  ]
  cdn_frontdoor_remove_response_headers = [
    "Server",
  ]

  # Logs are by default exported to a Log Analytics Workspace so enabling these two values are only necessary if you
  # want to ingest the logs using a 3rd party service (e.g. logit.io)
  enable_event_hub = true
  enable_logstash_consumer = true

  # Monitoring is disabled by default. If enabled, the following metrics will be monitored:
  # Container App: CPU usage, Memory usage, Revision count, HTTP regional availability
  # Redis (if enabled): Server Load Average
  enable_monitoring = true
  monitor_email_receivers = [ "list@email.com ]
  monitor_endpoint_healthcheck = "/healthcheck"
  alarm_cpu_threshold_percentage = 80
  alarm_memory_threshold_percentage = 80

  # Note that only 1 network watcher can be created within a subscription
  # It would probably be advisable to create a Network Watcher outside of this module, as it
  # may need to be used by other things
  enable_network_watcher                       = false
  existing_network_watcher_name                = "MyNetworkWatcher"
  existing_network_watcher_resource_group_name = "NetworkWatcherRG"
  network_watcher_retention                    = 90
  enable_network_watcher_traffic_analytics     = true
  network_watcher_traffic_analytics_interval   = 60
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.6 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >= 1.1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.41.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | 1.3.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.41.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.1 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.container_app_env](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.default](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.worker](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_application_insights.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_application_insights_standard_web_test.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_standard_web_test) | resource |
| [azurerm_cdn_frontdoor_custom_domain.custom_domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain) | resource |
| [azurerm_cdn_frontdoor_custom_domain_association.custom_domain_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain_association) | resource |
| [azurerm_cdn_frontdoor_endpoint.endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_endpoint) | resource |
| [azurerm_cdn_frontdoor_firewall_policy.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_firewall_policy) | resource |
| [azurerm_cdn_frontdoor_origin.origin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin) | resource |
| [azurerm_cdn_frontdoor_origin_group.group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin_group) | resource |
| [azurerm_cdn_frontdoor_profile.cdn](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_profile) | resource |
| [azurerm_cdn_frontdoor_route.route](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_route) | resource |
| [azurerm_cdn_frontdoor_rule.add_response_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.redirect](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.remove_response_header](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule_set.add_response_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_rule_set.redirects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_rule_set.remove_response_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_security_policy.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_security_policy) | resource |
| [azurerm_container_registry.acr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry) | resource |
| [azurerm_dns_a_record.frontdoor_custom_domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_dns_txt_record.frontdoor_custom_domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_txt_record) | resource |
| [azurerm_dns_zone.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_zone) | resource |
| [azurerm_eventhub.container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) | resource |
| [azurerm_eventhub_authorization_rule.listen_only](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_authorization_rule) | resource |
| [azurerm_eventhub_consumer_group.logstash](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_consumer_group) | resource |
| [azurerm_eventhub_namespace.container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) | resource |
| [azurerm_log_analytics_data_export_rule.container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_data_export_rule) | resource |
| [azurerm_log_analytics_workspace.container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_log_analytics_workspace.default_network_watcher_nsg_flow_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_monitor_action_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | resource |
| [azurerm_monitor_metric_alert.count](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.cpu](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.http](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.latency](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.memory](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.redis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_mssql_database.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database) | resource |
| [azurerm_mssql_database_extended_auditing_policy.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database_extended_auditing_policy) | resource |
| [azurerm_mssql_server.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server) | resource |
| [azurerm_mssql_server_extended_auditing_policy.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server_extended_auditing_policy) | resource |
| [azurerm_network_security_group.container_apps_infra_allow_frontdoor_inbound_only](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_watcher.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher) | resource |
| [azurerm_network_watcher_flow_log.default_network_watcher_nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher_flow_log) | resource |
| [azurerm_private_dns_a_record.mssql_private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.redis_cache_private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_zone.mssql_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.redis_cache_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.mssql_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.redis_cache_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.default_mssql](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.default_redis_cache](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_redis_cache.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redis_cache) | resource |
| [azurerm_redis_firewall_rule.container_app_default_static_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redis_firewall_rule) | resource |
| [azurerm_redis_firewall_rule.container_app_worker_static_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redis_firewall_rule) | resource |
| [azurerm_resource_group.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_route_table.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_storage_account.default_network_watcher_nsg_flow_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account.mssql_security_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_subnet.container_apps_infra_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.container_instances_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.mssql_private_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.redis_cache_private_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.redis_cache_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.container_apps_infra_allow_frontdoor_inbound_only](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_route_table_association.container_apps_infra_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.containerinstances_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.mssql_private_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.redis_cache_private_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.redis_cache_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_virtual_network.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [null_resource.tagging](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [azurerm_resource_group.existing_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |
| [azurerm_virtual_network.existing_virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_cpu_threshold_percentage"></a> [alarm\_cpu\_threshold\_percentage](#input\_alarm\_cpu\_threshold\_percentage) | Specify a number (%) which should be set as a threshold for a CPU usage monitoring alarm | `number` | `80` | no |
| <a name="input_alarm_latency_threshold_ms"></a> [alarm\_latency\_threshold\_ms](#input\_alarm\_latency\_threshold\_ms) | Specify a number in milliseconds which should be set as a threshold for a request latency monitoring alarm | `number` | `1000` | no |
| <a name="input_alarm_memory_threshold_percentage"></a> [alarm\_memory\_threshold\_percentage](#input\_alarm\_memory\_threshold\_percentage) | Specify a number (%) which should be set as a threshold for a memory usage monitoring alarm | `number` | `80` | no |
| <a name="input_azure_location"></a> [azure\_location](#input\_azure\_location) | Azure location in which to launch resources. | `string` | n/a | yes |
| <a name="input_cdn_frontdoor_custom_domains"></a> [cdn\_frontdoor\_custom\_domains](#input\_cdn\_frontdoor\_custom\_domains) | Azure CDN Front Door custom domains. If they are within the DNS zone (optionally created), the Validation TXT records and ALIAS/CNAME records will be created | `list(string)` | `[]` | no |
| <a name="input_cdn_frontdoor_enable_rate_limiting"></a> [cdn\_frontdoor\_enable\_rate\_limiting](#input\_cdn\_frontdoor\_enable\_rate\_limiting) | Enable CDN Front Door Rate Limiting. This will create a WAF policy, and CDN security policy. For pricing reasons, there will only be one WAF policy created. | `bool` | `false` | no |
| <a name="input_cdn_frontdoor_health_probe_interval"></a> [cdn\_frontdoor\_health\_probe\_interval](#input\_cdn\_frontdoor\_health\_probe\_interval) | Specifies the number of seconds between health probes. | `number` | `30` | no |
| <a name="input_cdn_frontdoor_health_probe_path"></a> [cdn\_frontdoor\_health\_probe\_path](#input\_cdn\_frontdoor\_health\_probe\_path) | Specifies the path relative to the origin that is used to determine the health of the origin. | `string` | `"/"` | no |
| <a name="input_cdn_frontdoor_host_add_response_headers"></a> [cdn\_frontdoor\_host\_add\_response\_headers](#input\_cdn\_frontdoor\_host\_add\_response\_headers) | List of response headers to add at the CDN Front Door `[{ "Name" = "Strict-Transport-Security", "value" = "max-age=31536000" }]` | `list(map(string))` | `[]` | no |
| <a name="input_cdn_frontdoor_host_redirects"></a> [cdn\_frontdoor\_host\_redirects](#input\_cdn\_frontdoor\_host\_redirects) | CDN FrontDoor host redirects `[{ "from" = "example.com", "to" = "www.example.com" }]` | `list(map(string))` | `[]` | no |
| <a name="input_cdn_frontdoor_rate_limiting_bypass_ip_list"></a> [cdn\_frontdoor\_rate\_limiting\_bypass\_ip\_list](#input\_cdn\_frontdoor\_rate\_limiting\_bypass\_ip\_list) | List if IP CIDRs to bypass CDN Front Door rate limiting | `list(string)` | `[]` | no |
| <a name="input_cdn_frontdoor_rate_limiting_duration_in_minutes"></a> [cdn\_frontdoor\_rate\_limiting\_duration\_in\_minutes](#input\_cdn\_frontdoor\_rate\_limiting\_duration\_in\_minutes) | CDN Front Door rate limiting duration in minutes | `number` | `1` | no |
| <a name="input_cdn_frontdoor_rate_limiting_threshold"></a> [cdn\_frontdoor\_rate\_limiting\_threshold](#input\_cdn\_frontdoor\_rate\_limiting\_threshold) | CDN Front Door rate limiting duration in minutes | `number` | `300` | no |
| <a name="input_cdn_frontdoor_remove_response_headers"></a> [cdn\_frontdoor\_remove\_response\_headers](#input\_cdn\_frontdoor\_remove\_response\_headers) | List of response headers to remove at the CDN Front Door | `list(string)` | `[]` | no |
| <a name="input_cdn_frontdoor_response_timeout"></a> [cdn\_frontdoor\_response\_timeout](#input\_cdn\_frontdoor\_response\_timeout) | Azure CDN Front Door response timeout in seconds | `number` | `120` | no |
| <a name="input_cdn_frontdoor_sku"></a> [cdn\_frontdoor\_sku](#input\_cdn\_frontdoor\_sku) | Azure CDN Front Door SKU | `string` | `"Standard_AzureFrontDoor"` | no |
| <a name="input_cdn_frontdoor_waf_mode"></a> [cdn\_frontdoor\_waf\_mode](#input\_cdn\_frontdoor\_waf\_mode) | CDN Front Door waf mode | `string` | `"Prevention"` | no |
| <a name="input_container_command"></a> [container\_command](#input\_container\_command) | Container command | `list(any)` | `[]` | no |
| <a name="input_container_cpu"></a> [container\_cpu](#input\_container\_cpu) | Number of container CPU cores | `number` | `1` | no |
| <a name="input_container_environment_variables"></a> [container\_environment\_variables](#input\_container\_environment\_variables) | Container environment variables | `map(string)` | `{}` | no |
| <a name="input_container_health_probe_interval"></a> [container\_health\_probe\_interval](#input\_container\_health\_probe\_interval) | How often in seconds to poll the Container to determine liveness | `number` | `30` | no |
| <a name="input_container_health_probe_path"></a> [container\_health\_probe\_path](#input\_container\_health\_probe\_path) | Specifies the path that is used to determine the liveness of the Container | `string` | `"/"` | no |
| <a name="input_container_max_replicas"></a> [container\_max\_replicas](#input\_container\_max\_replicas) | Container max replicas | `number` | `2` | no |
| <a name="input_container_memory"></a> [container\_memory](#input\_container\_memory) | Container memory in GB | `number` | `2` | no |
| <a name="input_container_min_replicas"></a> [container\_min\_replicas](#input\_container\_min\_replicas) | Container min replicas | `number` | `1` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | Container port | `number` | `80` | no |
| <a name="input_container_secret_environment_variables"></a> [container\_secret\_environment\_variables](#input\_container\_secret\_environment\_variables) | Container environment variables, which are defined as `secrets` within the container app configuration. This is to help reduce the risk of accidentally exposing secrets. | `map(string)` | `{}` | no |
| <a name="input_dns_zone_domain_name"></a> [dns\_zone\_domain\_name](#input\_dns\_zone\_domain\_name) | DNS zone domain name. If created, records will automatically be created to point to the CDN. | `string` | `""` | no |
| <a name="input_dns_zone_soa_record"></a> [dns\_zone\_soa\_record](#input\_dns\_zone\_soa\_record) | DNS zone SOA record block (https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_zone#soa_record) | `map(string)` | `{}` | no |
| <a name="input_enable_cdn_frontdoor"></a> [enable\_cdn\_frontdoor](#input\_enable\_cdn\_frontdoor) | Enable Azure CDN Front Door. This will use the Container Apps endpoint as the origin. | `bool` | `false` | no |
| <a name="input_enable_cdn_frontdoor_health_probe"></a> [enable\_cdn\_frontdoor\_health\_probe](#input\_enable\_cdn\_frontdoor\_health\_probe) | Enable CDN Front Door health probe | `bool` | `true` | no |
| <a name="input_enable_container_health_probe"></a> [enable\_container\_health\_probe](#input\_enable\_container\_health\_probe) | Enable liveness probes for the Container | `bool` | `true` | no |
| <a name="input_enable_container_registry"></a> [enable\_container\_registry](#input\_enable\_container\_registry) | Set to true to create a container registry | `bool` | n/a | yes |
| <a name="input_enable_dns_zone"></a> [enable\_dns\_zone](#input\_enable\_dns\_zone) | Conditionally create a DNS zone | `bool` | `false` | no |
| <a name="input_enable_event_hub"></a> [enable\_event\_hub](#input\_enable\_event\_hub) | Send Azure Container App logs to an Event Hub sink | `bool` | `false` | no |
| <a name="input_enable_logstash_consumer"></a> [enable\_logstash\_consumer](#input\_enable\_logstash\_consumer) | Create an Event Hub consumer group for Logstash | `bool` | `false` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Create an App Insights instance and notification group for the Container App | `bool` | `false` | no |
| <a name="input_enable_mssql_database"></a> [enable\_mssql\_database](#input\_enable\_mssql\_database) | Set to true to create an Azure SQL server/database, with a private endpoint within the virtual network | `bool` | `false` | no |
| <a name="input_enable_network_watcher"></a> [enable\_network\_watcher](#input\_enable\_network\_watcher) | Enable network watcher. Note: only 1 network watcher per subscription can be created. | `bool` | `false` | no |
| <a name="input_enable_network_watcher_traffic_analytics"></a> [enable\_network\_watcher\_traffic\_analytics](#input\_enable\_network\_watcher\_traffic\_analytics) | Enable network watcher traffic analytics (Requires `enable_network_watcher` to be true) | `bool` | `true` | no |
| <a name="input_enable_redis_cache"></a> [enable\_redis\_cache](#input\_enable\_redis\_cache) | Set to true to create an Azure Redis Cache, with a private endpoint within the virtual network | `bool` | `false` | no |
| <a name="input_enable_worker_container"></a> [enable\_worker\_container](#input\_enable\_worker\_container) | Conditionally launch a worker container. This container uses the same image and environment variables as the default container app, but allows a different container command to be run. The worker container does not expose any ports. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name. Will be used along with `project_name` as a prefix for all resources. | `string` | n/a | yes |
| <a name="input_existing_network_watcher_name"></a> [existing\_network\_watcher\_name](#input\_existing\_network\_watcher\_name) | Use an existing network watcher to add flow logs. | `string` | `""` | no |
| <a name="input_existing_network_watcher_resource_group_name"></a> [existing\_network\_watcher\_resource\_group\_name](#input\_existing\_network\_watcher\_resource\_group\_name) | Existing network watcher resource group. | `string` | `""` | no |
| <a name="input_existing_resource_group"></a> [existing\_resource\_group](#input\_existing\_resource\_group) | Conditionally launch resources into an existing resource group. Specifying this will NOT create a resource group. | `string` | `""` | no |
| <a name="input_existing_virtual_network"></a> [existing\_virtual\_network](#input\_existing\_virtual\_network) | Conditionally use an existing virtual network. The `virtual_network_address_space` must match an existing address space in the VNet. This also requires the resource group name. | `string` | `""` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Image name | `string` | n/a | yes |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Image tag | `string` | `"latest"` | no |
| <a name="input_launch_in_vnet"></a> [launch\_in\_vnet](#input\_launch\_in\_vnet) | Conditionally launch into a VNet | `bool` | `true` | no |
| <a name="input_monitor_email_receivers"></a> [monitor\_email\_receivers](#input\_monitor\_email\_receivers) | A list of email addresses that should be notified by monitoring alerts | `list(string)` | `[]` | no |
| <a name="input_monitor_endpoint_healthcheck"></a> [monitor\_endpoint\_healthcheck](#input\_monitor\_endpoint\_healthcheck) | Specify a route that should be monitored for a 200 OK status | `string` | `"/"` | no |
| <a name="input_mssql_database_name"></a> [mssql\_database\_name](#input\_mssql\_database\_name) | The name of the MSSQL database to create. Must be set if `enable_mssql_database` is true | `string` | `""` | no |
| <a name="input_mssql_max_size_gb"></a> [mssql\_max\_size\_gb](#input\_mssql\_max\_size\_gb) | The max size of the database in gigabytes | `number` | `2` | no |
| <a name="input_mssql_server_admin_password"></a> [mssql\_server\_admin\_password](#input\_mssql\_server\_admin\_password) | The administrator password for the MSSQL server. Must be set if `enable_mssql_database` is true | `string` | `""` | no |
| <a name="input_mssql_sku_name"></a> [mssql\_sku\_name](#input\_mssql\_sku\_name) | Specifies the name of the SKU used by the database | `string` | `"Basic"` | no |
| <a name="input_network_watcher_flow_log_retention"></a> [network\_watcher\_flow\_log\_retention](#input\_network\_watcher\_flow\_log\_retention) | Number of days to retain flow logs. Set to 0 to keep all logs. | `number` | `90` | no |
| <a name="input_network_watcher_traffic_analytics_interval"></a> [network\_watcher\_traffic\_analytics\_interval](#input\_network\_watcher\_traffic\_analytics\_interval) | Interval in minutes for Traffic Analytics. | `number` | `60` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name. Will be used along with `environment` as a prefix for all resources. | `string` | n/a | yes |
| <a name="input_redis_cache_capacity"></a> [redis\_cache\_capacity](#input\_redis\_cache\_capacity) | Redis Cache Capacity | `number` | `0` | no |
| <a name="input_redis_cache_family"></a> [redis\_cache\_family](#input\_redis\_cache\_family) | Redis Cache family | `string` | `"C"` | no |
| <a name="input_redis_cache_patch_schedule_day"></a> [redis\_cache\_patch\_schedule\_day](#input\_redis\_cache\_patch\_schedule\_day) | Redis Cache patch schedule day | `string` | `"Wednesday"` | no |
| <a name="input_redis_cache_patch_schedule_hour"></a> [redis\_cache\_patch\_schedule\_hour](#input\_redis\_cache\_patch\_schedule\_hour) | Redis Cache patch schedule hour | `number` | `18` | no |
| <a name="input_redis_cache_sku"></a> [redis\_cache\_sku](#input\_redis\_cache\_sku) | Redis Cache SKU | `string` | `"Basic"` | no |
| <a name="input_redis_cache_version"></a> [redis\_cache\_version](#input\_redis\_cache\_version) | Redis Cache version | `number` | `6` | no |
| <a name="input_registry_password"></a> [registry\_password](#input\_registry\_password) | Container registry password (required if `enable_container_registry` is false) | `string` | `""` | no |
| <a name="input_registry_server"></a> [registry\_server](#input\_registry\_server) | Container registry server (required if `enable_container_registry` is false) | `string` | `""` | no |
| <a name="input_registry_username"></a> [registry\_username](#input\_registry\_username) | Container registry username (required if `enable_container_registry` is false) | `string` | `""` | no |
| <a name="input_restrict_container_apps_to_cdn_inbound_only"></a> [restrict\_container\_apps\_to\_cdn\_inbound\_only](#input\_restrict\_container\_apps\_to\_cdn\_inbound\_only) | Restricts access to the Container Apps by creating a network security group that only allows 'AzureFrontDoor.Backend' inbound, and attaches it to the subnet of the container app environment. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_virtual_network_address_space"></a> [virtual\_network\_address\_space](#input\_virtual\_network\_address\_space) | Virtual Network address space CIDR | `string` | `"172.16.0.0/12"` | no |
| <a name="input_worker_container_command"></a> [worker\_container\_command](#input\_worker\_container\_command) | Container command for the Worker container. `enable_worker_container` must be set to true for this to have any effect. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_azurerm_resource_group_default"></a> [azurerm\_resource\_group\_default](#output\_azurerm\_resource\_group\_default) | n/a |
<!-- END_TF_DOCS -->

[1]: https://azure.microsoft.com/en-us/services/container-apps
[2]: https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview
