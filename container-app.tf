resource "azurerm_container_app_environment" "container_app_env" {
  name                           = "${local.resource_prefix}containerapp"
  location                       = local.resource_group.location
  resource_group_name            = local.resource_group.name
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.container_app.id
  infrastructure_subnet_id       = local.launch_in_vnet ? azurerm_subnet.container_apps_infra_subnet[0].id : null
  internal_load_balancer_enabled = local.container_app_environment_internal_load_balancer_enabled

  tags = local.tags
}

resource "azurerm_monitor_diagnostic_setting" "container_app_env" {
  name                       = "${local.resource_prefix}-containerapp-diag"
  target_resource_id         = azurerm_container_app_environment.container_app_env.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.container_app.id
  eventhub_name              = local.enable_event_hub ? azurerm_eventhub.container_app[0].name : null

  enabled_log {
    category_group = "Audit"
  }
}

resource "azurerm_container_app_environment_storage" "container_app_env" {
  count = local.enable_container_app_file_share ? 1 : 0

  name                         = "${local.resource_prefix}containerappstorage"
  container_app_environment_id = azurerm_container_app_environment.container_app_env.id
  account_name                 = azurerm_storage_account.container_app[0].name
  share_name                   = azurerm_storage_share.container_app[0].name
  access_key                   = azurerm_storage_account.container_app[0].primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app" "container_apps" {
  for_each = toset(concat(
    ["main"],
    local.enable_worker_container ? ["worker"] : [],
  ))

  name                         = each.value == "worker" ? "${local.container_app_name}-worker" : local.container_app_name
  container_app_environment_id = azurerm_container_app_environment.container_app_env.id
  resource_group_name          = local.resource_group.name
  revision_mode                = "Single"

  dynamic "ingress" {
    for_each = each.value == "main" ? [1] : []

    content {
      external_enabled = true
      target_port      = local.container_port
      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
  }

  dynamic "secret" {
    for_each = { for i, v in concat(
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
      local.container_app_blob_storage_sas_secret,
      [for env_name, env_value in nonsensitive(local.container_secret_environment_variables) : {
        name  = lower(replace(env_name, "_", "-"))
        value = sensitive(env_value)
        }
      ]
    ) : v.name => v }

    content {
      name  = secret.value["name"]
      value = secret.value["value"]
    }
  }

  dynamic "identity" {
    for_each = local.registry_use_managed_identity ? [1] : []

    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.containerapp[0].id]
    }
  }

  dynamic "identity" {
    for_each = local.container_app_identities != null ? [1] : []

    content {
      type         = local.container_app_identities.type
      identity_ids = local.container_app_identities.identity_ids
    }
  }

  registry {
    server               = local.registry_server
    username             = local.registry_use_managed_identity == false ? local.registry_username : null
    password_secret_name = local.registry_use_managed_identity == false ? "acr-password" : null
    identity             = local.registry_use_managed_identity ? azurerm_user_assigned_identity.containerapp[0].id : null
  }

  template {
    container {
      name    = each.value
      image   = local.use_external_container_registry ? local.registry_custom_image_url : "${local.registry_server}/${local.image_name}:${local.image_tag}"
      cpu     = local.container_cpu
      memory  = "${local.container_memory}Gi"
      command = each.value == "worker" ? local.worker_container_command : local.container_command

      dynamic "volume_mounts" {
        for_each = local.enable_container_app_file_share ? [1] : []

        content {
          name = azurerm_container_app_environment_storage.container_app_env[0].name
          path = local.container_app_file_share_mount_path
        }
      }

      dynamic "liveness_probe" {
        for_each = each.value == "main" && local.enable_container_health_probe ? [1] : []

        content {
          interval_seconds = lookup(local.container_health_probe, "interval_seconds", null)
          transport        = lookup(local.container_health_probe, "transport", null)
          port             = lookup(local.container_health_probe, "port", local.container_port)
          path             = lookup(local.container_health_probe, "path", null)
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
          local.enable_container_app_blob_storage ?
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

        content {
          name        = env.value["name"]
          secret_name = lookup(env.value, "secretRef", null)
          value       = lookup(env.value, "value", null)
        }
      }
    }

    min_replicas = each.value == "worker" ? local.worker_container_min_replicas : local.container_min_replicas
    max_replicas = each.value == "worker" ? local.worker_container_max_replicas : local.container_max_replicas

    http_scale_rule {
      name                = "scale-up-down-http-requests"
      concurrent_requests = local.container_scale_http_concurrency
    }

    dynamic "custom_scale_rule" {
      for_each = local.container_scale_out_at_defined_time ? [1] : []

      content {
        name             = "scale-down-out-of-hours"
        custom_rule_type = "cron"
        metadata = {
          timezone        = "Europe/London"
          start           = local.container_scale_out_rule_start
          end             = local.container_scale_out_rule_end
          desiredReplicas = each.value == "worker" ? local.worker_container_max_replicas : local.container_max_replicas
        }
      }
    }

    dynamic "volume" {
      for_each = local.enable_container_app_file_share ? [1] : []

      content {
        name         = azurerm_container_app_environment_storage.container_app_env[0].name
        storage_name = azurerm_container_app_environment_storage.container_app_env[0].name
        storage_type = "AzureFile"
      }
    }
  }

  tags = local.tags
}
