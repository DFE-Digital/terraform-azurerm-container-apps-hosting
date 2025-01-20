resource "azurerm_container_app" "custom_container_apps" {
  for_each = local.custom_container_apps

  name                         = each.key
  container_app_environment_id = each.value.container_app_environment_id == "" ? local.container_app_environment.id : each.value.container_app_environment_id
  resource_group_name          = each.value.resource_group_name == "" ? local.resource_group.name : each.value.resource_group_name
  revision_mode                = each.value.revision_mode

  dynamic "ingress" {
    for_each = each.value.ingress != null ? [1] : []

    content {
      external_enabled = each.value.ingress.external_enabled
      target_port      = each.value.ingress.target_port
      traffic_weight {
        percentage      = each.value.ingress.traffic_weight.percentage
        latest_revision = true
      }
    }
  }

  dynamic "secret" {
    for_each = { for i, v in concat(
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
      each.value.secrets
    ) : v.name => v }

    content {
      name  = secret.value["name"]
      value = secret.value["value"]
    }
  }

  dynamic "identity" {
    for_each = each.value.identity

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "registry" {
    for_each = each.value.registry != null ? [1] : []

    content {
      server               = each.value.registry.server != "" ? each.value.registry.server : local.registry_server
      username             = each.value.registry.identity == "" ? each.value.registry.username != "" ? each.value.registry.username : local.registry_username : null
      password_secret_name = each.value.registry.identity == "" ? each.value.registry.password_secret_name != "" ? each.value.registry.password_secret_name : "acr-password" : null
      identity             = each.value.registry.identity != "" ? each.value.registry.identity : null
    }
  }

  template {
    container {
      name    = each.key
      image   = each.value.image
      cpu     = each.value.cpu
      memory  = "${each.value.memory}Gi"
      command = each.value.command
      dynamic "liveness_probe" {
        for_each = each.value.liveness_probes

        content {
          interval_seconds = liveness_probe.interval_seconds
          transport        = liveness_probe.transport
          port             = liveness_probe.port
          path             = liveness_probe.path
        }
      }
      dynamic "env" {
        for_each = { for i, v in concat(
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
          each.value.env,
        ) : v.name => v }

        content {
          name        = env.value["name"]
          secret_name = lookup(env.value, "secretRef", null)
          value       = lookup(env.value, "value", null)
        }
      }
    }
    min_replicas = each.value.min_replicas
    max_replicas = each.value.max_replicas
  }

  tags = local.tags
}
