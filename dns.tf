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
  for_each = local.enable_dns_zone && local.cdn_frontdoor_custom_domains_create_dns_records ? local.cdn_frontdoor_custom_domain_dns_names : []

  name                = trim(join(".", ["_dnsauth", each.value]), ".")
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.custom_domain["${each.value}${local.dns_zone_domain_name}"].validation_token
  }

  tags = local.tags
}

resource "azurerm_dns_a_record" "frontdoor_custom_domain" {
  for_each = local.enable_dns_zone && local.cdn_frontdoor_custom_domains_create_dns_records ? local.cdn_frontdoor_custom_domain_dns_names : []

  name                = trim(each.value, ".") == "" ? "@" : trim(each.value, ".")
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 60
  target_resource_id  = azurerm_cdn_frontdoor_endpoint.endpoint[0].id

  tags = local.tags
}

resource "azurerm_dns_txt_record" "custom_container_frontdoor_custom_domain" {
  for_each = local.enable_dns_zone && local.cdn_frontdoor_custom_domains_create_dns_records ? local.custom_container_apps_cdn_frontdoor_custom_domain_dns_names : {}

  name                = trim(join(".", ["_dnsauth", each.value]), ".")
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.custom_container_apps[each.key].validation_token
  }

  tags = local.tags
}

resource "azurerm_dns_a_record" "custom_container_frontdoor_custom_domain" {
  for_each = local.enable_dns_zone && local.cdn_frontdoor_custom_domains_create_dns_records ? local.custom_container_apps_cdn_frontdoor_custom_domain_dns_names : {}

  name                = trim(each.value, ".") == "" ? "@" : trim(each.value, ".")
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = 60
  target_resource_id  = azurerm_cdn_frontdoor_endpoint.custom_container_apps[each.key].id

  tags = local.tags
}

resource "azurerm_dns_a_record" "dns_a_records" {
  for_each = local.enable_dns_zone ? local.dns_a_records : {}

  name                = each.key
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = lookup(each.value, "ttl", "300")
  records             = each.value["records"]

  tags = local.tags
}

resource "azurerm_dns_a_record" "dns_alias_records" {
  for_each = local.enable_dns_zone ? local.dns_alias_records : {}

  name                = each.key
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = lookup(each.value, "ttl", "300")
  target_resource_id  = each.value["target_resource_id"]

  tags = local.tags
}

resource "azurerm_dns_aaaa_record" "dns_aaaa_records" {
  for_each = local.enable_dns_zone ? local.dns_aaaa_records : {}

  name                = each.key
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = lookup(each.value, "ttl", "300")
  records             = each.value["records"]

  tags = local.tags
}

resource "azurerm_dns_caa_record" "dns_caa_records" {
  for_each = local.enable_dns_zone ? local.dns_caa_records : {}

  name                = each.key
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = lookup(each.value, "ttl", "300")

  dynamic "record" {
    for_each = each.value["records"]
    content {
      flags = record.flags
      tag   = record.tag
      value = record.value
    }
  }

  tags = local.tags
}

resource "azurerm_dns_cname_record" "dns_cname_records" {
  for_each = local.enable_dns_zone ? local.dns_cname_records : {}

  name                = each.key
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = lookup(each.value, "ttl", "300")
  record              = each.value["record"]

  tags = local.tags
}

resource "azurerm_dns_mx_record" "dns_mx_records" {
  for_each = local.enable_dns_zone ? local.dns_mx_records : {}

  name                = each.key
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = lookup(each.value, "ttl", "300")

  dynamic "record" {
    for_each = each.value["records"]
    content {
      preference = record.value.preference
      exchange   = record.value.exchange
    }
  }

  tags = local.tags
}

resource "azurerm_dns_ns_record" "dns_ns_records" {
  for_each = local.enable_dns_zone ? local.dns_ns_records : {}

  name                = each.key
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = lookup(each.value, "ttl", "300")
  records             = each.value["records"]

  tags = local.tags
}

resource "azurerm_dns_ptr_record" "dns_ptr_records" {
  for_each = local.enable_dns_zone ? local.dns_ptr_records : {}

  name                = each.key
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = lookup(each.value, "ttl", "300")
  records             = each.value["records"]

  tags = local.tags
}

resource "azurerm_dns_srv_record" "dns_srv_records" {
  for_each = local.enable_dns_zone ? local.dns_srv_records : {}

  name                = each.key
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = lookup(each.value, "ttl", "300")

  dynamic "record" {
    for_each = each.value["records"]
    content {
      priority = record.priority
      weight   = record.weight
      port     = record.port
      target   = record.target
    }
  }

  tags = local.tags
}

resource "azurerm_dns_txt_record" "dns_txt_records" {
  for_each = local.enable_dns_zone ? local.dns_txt_records : {}

  name                = each.key
  zone_name           = azurerm_dns_zone.default[0].name
  resource_group_name = local.resource_group.name
  ttl                 = lookup(each.value, "ttl", "300")

  dynamic "record" {
    for_each = each.value["records"]
    content {
      value = record.value
    }
  }

  tags = local.tags
}
