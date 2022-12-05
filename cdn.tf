resource "azurerm_cdn_frontdoor_profile" "cdn" {
  count = local.enable_cdn_frontdoor ? 1 : 0

  name                     = "${local.resource_prefix}cdn"
  resource_group_name      = local.resource_group.name
  sku_name                 = local.cdn_frontdoor_sku
  response_timeout_seconds = local.cdn_frontdoor_response_timeout
  tags                     = local.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "group" {
  count = local.enable_cdn_frontdoor ? 1 : 0

  name                     = "${local.resource_prefix}origingroup"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn[0].id

  load_balancing {}
}

resource "azurerm_cdn_frontdoor_origin" "origin" {
  count = local.enable_cdn_frontdoor ? 1 : 0

  name                           = "${local.resource_prefix}origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.group[0].id
  enabled                        = true
  certificate_name_check_enabled = true
  host_name                      = jsondecode(azapi_resource.default.output).properties.configuration.ingress.fqdn
  origin_host_header             = jsondecode(azapi_resource.default.output).properties.configuration.ingress.fqdn
  http_port                      = 80
  https_port                     = 443
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  count = local.enable_cdn_frontdoor ? 1 : 0

  name                     = "${local.resource_prefix}cdnendpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn[0].id
  tags                     = local.tags
}

resource "azurerm_cdn_frontdoor_custom_domain" "custom_domain" {
  for_each = local.enable_cdn_frontdoor ? toset(local.cdn_frontdoor_custom_domains) : []

  name                     = "${local.resource_prefix}custom-domain${index(local.cdn_frontdoor_custom_domains, each.value)}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn[0].id
  dns_zone_id              = local.enable_dns_zone && endswith(each.value, local.dns_zone_domain_name) ? azurerm_dns_zone.default[0].id : null
  host_name                = each.value

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_route" "route" {
  count = local.enable_cdn_frontdoor ? 1 : 0

  name                          = "${local.resource_prefix}route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint[0].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.group[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.origin[0].id]
  cdn_frontdoor_rule_set_ids    = local.ruleset_ids
  enabled                       = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cdn_frontdoor_custom_domain_ids = [
    for custom_domain in azurerm_cdn_frontdoor_custom_domain.custom_domain : custom_domain.id
  ]

  link_to_default_domain = true

  cache {
    query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
    query_strings                 = ["account", "settings"]
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "custom_domain_association" {
  for_each = local.enable_cdn_frontdoor ? [] : toset(local.cdn_frontdoor_custom_domains)

  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.custom_domain[each.value].id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.route[0].id]
}

resource "azurerm_cdn_frontdoor_rule_set" "redirects" {
  count = local.enable_cdn_frontdoor && length(local.cdn_frontdoor_host_redirects) > 0 ? 1 : 0

  name                     = "${replace(local.resource_prefix, "-", "")}redirects"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn[0].id
}

resource "azurerm_cdn_frontdoor_rule" "redirect" {
  for_each = local.enable_cdn_frontdoor ? { for index, host_redirect in local.cdn_frontdoor_host_redirects : index => { "from" : host_redirect.from, "to" : host_redirect.to } } : {}

  depends_on = [azurerm_cdn_frontdoor_origin_group.group, azurerm_cdn_frontdoor_origin.origin]

  name                      = "redirect${each.key}"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.redirects[0].id
  order                     = each.key
  behavior_on_match         = "Continue"

  actions {
    url_redirect_action {
      redirect_type        = "Moved"
      redirect_protocol    = "Https"
      destination_hostname = each.value.to
    }
  }

  conditions {
    host_name_condition {
      operator         = "Equal"
      negate_condition = false
      match_values     = [each.value.from]
      transforms       = ["Lowercase", "Trim"]
    }
  }
}
