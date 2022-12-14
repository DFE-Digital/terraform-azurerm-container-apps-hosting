resource "azurerm_dns_zone" "default" {
  count = local.enable_dns_zone ? 1 : 0

  name                = local.dns_zone_domain_name
  resource_group_name = local.resource_group.name

  dynamic "soa_record" {
    for_each = lookup(local.dns_zone_soa_record, "email", "") == "" ? [] : [1]

    content {
      email         = lookup(local.dns_zone_soa_record, "email", "hello.example.com")
      host_name     = lookup(local.dns_zone_soa_record, "host_name", "ns1-03.azure-dns.com.")
      expire_time   = lookup(local.dns_zone_soa_record, "expire_time", "2419200")
      minimum_ttl   = lookup(local.dns_zone_soa_record, "minimum_ttl", "300")
      refresh_time  = lookup(local.dns_zone_soa_record, "refresh_time", "3600")
      retry_time    = lookup(local.dns_zone_soa_record, "retry_time", "300")
      serial_number = lookup(local.dns_zone_soa_record, "serial_number", "1")
      ttl           = lookup(local.dns_zone_soa_record, "ttl", "3600")
    }
  }

  tags = local.tags
}

resource "azurerm_dns_txt_record" "frontdoor_custom_domain" {
  for_each = local.cdn_frontdoor_custom_domain_dns_names

  name                = trim(join(".", ["_dnsauth", each.value]), ".")
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.custom_domain["${each.value}${local.dns_zone_domain_name}"].validation_token
  }
}

resource "azurerm_dns_a_record" "frontdoor_custom_domain" {
  for_each = local.cdn_frontdoor_custom_domain_dns_names

  name                = trim(each.value, ".") == "" ? "@" : trim(each.value, ".")
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 300
  target_resource_id  = azurerm_cdn_frontdoor_endpoint.endpoint[0].id
}
