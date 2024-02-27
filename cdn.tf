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

  dynamic "health_probe" {
    for_each = local.enable_cdn_frontdoor_health_probe ? [0] : []

    content {
      protocol            = local.cdn_frontdoor_health_probe_protocol
      interval_in_seconds = local.cdn_frontdoor_health_probe_interval
      request_type        = local.cdn_frontdoor_health_probe_request_type
      path                = local.cdn_frontdoor_health_probe_path
    }
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "custom_container_apps" {
  for_each = local.enable_cdn_frontdoor ? { for name, container in local.custom_container_apps : name => container
    if container.ingress.external_enabled
  } : {}

  name                     = "${local.resource_prefix}origingroup${replace(each.key, "-", "")}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn[0].id

  load_balancing {}

  dynamic "health_probe" {
    for_each = each.value.ingress.enable_cdn_frontdoor_health_probe ? [0] : []

    content {
      protocol            = each.value.ingress.cdn_frontdoor_health_probe_protocol
      interval_in_seconds = each.value.ingress.cdn_frontdoor_health_probe_interval
      request_type        = each.value.ingress.cdn_frontdoor_health_probe_request_type
      path                = each.value.ingress.cdn_frontdoor_health_probe_path
    }
  }
}

resource "azurerm_cdn_frontdoor_origin" "origin" {
  count = local.enable_cdn_frontdoor ? 1 : 0

  name                           = "${local.resource_prefix}origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.group[0].id
  enabled                        = true
  certificate_name_check_enabled = true
  host_name                      = local.cdn_frontdoor_origin_fqdn_override
  origin_host_header             = local.cdn_frontdoor_origin_host_header_override
  http_port                      = local.cdn_frontdoor_origin_http_port
  https_port                     = local.cdn_frontdoor_origin_https_port
}

resource "azurerm_cdn_frontdoor_origin" "custom_container_apps" {
  for_each = local.enable_cdn_frontdoor ? { for name, container in local.custom_container_apps : name => container
    if container.ingress.external_enabled
  } : {}

  name                           = "${local.resource_prefix}origin${replace(each.key, "-", "")}"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.custom_container_apps[each.key].id
  enabled                        = true
  certificate_name_check_enabled = true
  host_name                      = each.value.ingress.cdn_frontdoor_origin_fqdn_override != "" ? each.value.ingress.cdn_frontdoor_origin_fqdn_override : azurerm_container_app.custom_container_apps[each.key].ingress[0].fqdn
  origin_host_header             = each.value.ingress.cdn_frontdoor_origin_host_header_override != "" ? each.value.ingress.cdn_frontdoor_origin_host_header_override : azurerm_container_app.custom_container_apps[each.key].ingress[0].fqdn
  http_port                      = local.cdn_frontdoor_origin_http_port
  https_port                     = local.cdn_frontdoor_origin_https_port

  depends_on = [azurerm_container_app.custom_container_apps]
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  count = local.enable_cdn_frontdoor ? 1 : 0

  name                     = "${local.resource_prefix}cdnendpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn[0].id
  tags                     = local.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "custom_container_apps" {
  for_each = local.enable_cdn_frontdoor ? { for name, container in local.custom_container_apps : name => container
    if container.ingress.external_enabled
  } : {}

  name                     = "${local.resource_prefix}cdnendpoint-${replace(each.key, "-", "")}"
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

resource "azurerm_cdn_frontdoor_custom_domain" "custom_container_apps" {
  for_each = local.enable_cdn_frontdoor ? { for name, container in local.custom_container_apps : name => container
    if container.ingress.external_enabled && container.ingress.cdn_frontdoor_custom_domain != ""
  } : {}

  name                     = "${local.resource_prefix}custom-domain-${each.key}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn[0].id
  dns_zone_id              = local.enable_dns_zone && endswith(each.value.ingress.cdn_frontdoor_custom_domain, local.dns_zone_domain_name) ? azurerm_dns_zone.default[0].id : null
  host_name                = each.value.ingress.cdn_frontdoor_custom_domain

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

  forwarding_protocol    = local.cdn_frontdoor_forwarding_protocol
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cdn_frontdoor_custom_domain_ids = [
    for custom_domain in azurerm_cdn_frontdoor_custom_domain.custom_domain : custom_domain.id
  ]

  link_to_default_domain = true
}

resource "azurerm_cdn_frontdoor_route" "custom_container_apps" {
  for_each = local.enable_cdn_frontdoor ? { for name, container in local.custom_container_apps : name => container
    if container.ingress.external_enabled
  } : {}

  name                          = "${local.resource_prefix}route-${replace(each.key, "-", "")}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.custom_container_apps[each.key].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.custom_container_apps[each.key].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.custom_container_apps[each.key].id]
  cdn_frontdoor_rule_set_ids    = local.ruleset_ids
  enabled                       = true

  forwarding_protocol    = each.value.ingress.cdn_frontdoor_forwarding_protocol_override != "" ? each.value.ingress.cdn_frontdoor_forwarding_protocol_override : local.cdn_frontdoor_forwarding_protocol
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cdn_frontdoor_custom_domain_ids = each.value.ingress.cdn_frontdoor_custom_domain != "" ? [azurerm_cdn_frontdoor_custom_domain.custom_container_apps[each.key].id] : []
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

resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {
  count = local.cdn_frontdoor_enable_waf ? 1 : 0

  name                              = "${replace(local.resource_prefix, "-", "")}waf"
  resource_group_name               = local.resource_group.name
  sku_name                          = azurerm_cdn_frontdoor_profile.cdn[0].sku_name
  enabled                           = true
  mode                              = local.cdn_frontdoor_waf_mode
  custom_block_response_status_code = 403
  custom_block_response_body        = filebase64("${path.module}/html/waf-response.html")

  dynamic "custom_rule" {
    for_each = local.cdn_frontdoor_enable_rate_limiting ? [0] : []
    content {
      name                           = "RateLimiting"
      enabled                        = true
      priority                       = 1
      rate_limit_duration_in_minutes = local.cdn_frontdoor_rate_limiting_duration_in_minutes
      rate_limit_threshold           = local.cdn_frontdoor_rate_limiting_threshold
      type                           = "RateLimitRule"
      action                         = "Block"

      dynamic "match_condition" {
        for_each = length(local.cdn_frontdoor_rate_limiting_bypass_ip_list) > 0 ? [0] : []

        content {
          match_variable     = "RemoteAddr"
          operator           = "IPMatch"
          negation_condition = true
          match_values       = local.cdn_frontdoor_rate_limiting_bypass_ip_list
        }
      }

      match_condition {
        match_variable     = "RequestUri"
        operator           = "RegEx"
        negation_condition = false
        match_values       = ["/.*"]
      }

    }
  }

  tags = local.tags
}

resource "azurerm_cdn_frontdoor_security_policy" "waf" {
  count = local.cdn_frontdoor_enable_waf ? 1 : 0

  name                     = "${replace(local.resource_prefix, "-", "")}wafsecuritypolicy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn[0].id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.waf[0].id

      association {
        patterns_to_match = ["/*"]

        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.endpoint[0].id
        }

        dynamic "domain" {
          for_each = local.enable_cdn_frontdoor ? { for name, container in local.custom_container_apps : name => container
            if container.ingress.external_enabled
          } : {}

          content {
            cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.custom_container_apps[domain.key].id
          }
        }

        dynamic "domain" {
          for_each = toset(local.cdn_frontdoor_custom_domains)

          content {
            cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.custom_domain[domain.value].id
          }
        }

        dynamic "domain" {
          for_each = local.enable_cdn_frontdoor ? { for name, container in local.custom_container_apps : name => container
            if container.ingress.external_enabled && container.ingress.cdn_frontdoor_custom_domain != ""
          } : {}

          content {
            cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.custom_container_apps[domain.key].id
          }
        }
      }
    }
  }
}

resource "azurerm_cdn_frontdoor_rule_set" "add_response_headers" {
  count = local.enable_cdn_frontdoor && length(local.cdn_frontdoor_host_add_response_headers) > 0 ? 1 : 0

  name                     = "${replace(local.resource_prefix, "-", "")}addresponseheaders"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn[0].id
}

resource "azurerm_cdn_frontdoor_rule" "add_response_headers" {
  for_each = local.enable_cdn_frontdoor ? { for index, response_header in local.cdn_frontdoor_host_add_response_headers : index => { "name" : response_header.name, "value" : response_header.value } } : {}

  depends_on = [azurerm_cdn_frontdoor_origin_group.group, azurerm_cdn_frontdoor_origin.origin]

  name                      = replace("addresponseheaders${each.key}", "-", "")
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.add_response_headers[0].id
  order                     = each.key
  behavior_on_match         = "Continue"

  actions {
    response_header_action {
      header_action = "Overwrite"
      header_name   = each.value.name
      value         = each.value.value
    }
  }
}

resource "azurerm_cdn_frontdoor_rule_set" "remove_response_headers" {
  count = local.enable_cdn_frontdoor && length(local.cdn_frontdoor_remove_response_headers) > 0 ? 1 : 0

  name                     = "${replace(local.resource_prefix, "-", "")}removeresponseheaders"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn[0].id
}

resource "azurerm_cdn_frontdoor_rule" "remove_response_header" {
  for_each = local.enable_cdn_frontdoor ? toset(local.cdn_frontdoor_remove_response_headers) : []

  depends_on = [azurerm_cdn_frontdoor_origin_group.group, azurerm_cdn_frontdoor_origin.origin]

  name                      = replace("removeresponseheader${each.value}", "-", "")
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.remove_response_headers[0].id
  order                     = index(local.cdn_frontdoor_remove_response_headers, each.value)
  behavior_on_match         = "Continue"

  actions {
    response_header_action {
      header_action = "Delete"
      header_name   = each.value
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "cdn" {
  count = local.enable_cdn_frontdoor ? 1 : 0

  name                           = "${local.resource_prefix}cdn"
  target_resource_id             = azurerm_cdn_frontdoor_profile.cdn[0].id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.container_app.id
  log_analytics_destination_type = "AzureDiagnostics"

  dynamic "enabled_log" {
    for_each = local.cdn_frontdoor_enable_waf_logs ? [1] : []

    content {
      category = "FrontdoorWebApplicationFirewallLog"
    }
  }

  dynamic "enabled_log" {
    for_each = local.cdn_frontdoor_enable_access_logs ? [1] : []

    content {
      category = "FrontdoorAccessLog"
    }
  }

  dynamic "enabled_log" {
    for_each = local.cdn_frontdoor_enable_health_probe_logs ? [1] : []

    content {
      category = "FrontdoorHealthProbeLog"
    }
  }
}
