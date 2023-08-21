output "azurerm_resource_group_default" {
  value       = local.existing_resource_group == "" ? azurerm_resource_group.default[0] : null
  description = "Default Azure Resource Group"
}

output "azurerm_log_analytics_workspace_container_app" {
  value       = azurerm_log_analytics_workspace.container_app
  description = "Container App Log Analytics Workspace"
}

output "azurerm_eventhub_container_app" {
  value       = local.enable_event_hub ? azurerm_eventhub.container_app[0] : null
  description = "Container App Event Hub"
}

output "azurerm_dns_zone_name_servers" {
  value       = local.enable_dns_zone ? azurerm_dns_zone.default[0].name_servers : null
  description = "Name servers of the DNS Zone"
}

output "cdn_frontdoor_dns_records" {
  value = local.cdn_frontdoor_custom_domains_create_dns_records == false ? concat([
    for domain in local.cdn_frontdoor_custom_domain_dns_names : {
      name  = trim(domain, ".") == "" ? "@" : trim(domain, ".")
      type  = "CNAME"
      ttl   = 300
      value = azurerm_cdn_frontdoor_endpoint.endpoint[0].host_name
    }
    ], local.dns_zone_domain_name != "" ? [
    for domain in local.cdn_frontdoor_custom_domain_dns_names : {
      name  = trim(join(".", ["_dnsauth", domain]), ".")
      type  = "TXT"
      ttl   = 3600
      value = azurerm_cdn_frontdoor_custom_domain.custom_domain["${domain}${local.dns_zone_domain_name}"].validation_token
    }
    ] : []
  ) : null
  description = "Azure Front Door DNS Records that must be created manually"
}

output "networking" {
  value = local.launch_in_vnet ? {
    vnet_id : local.existing_virtual_network == "" ? azurerm_virtual_network.default[0].id : null
    subnet_id : azurerm_subnet.container_apps_infra_subnet[0].id
  } : null
  description = "IDs for various VNet resources if created"
}

output "container_fqdn" {
  description = "FQDN for the Container App"
  value       = local.container_fqdn
}
