resource "azurerm_container_app_environment" "container_app_env" {
  count = local.existing_container_app_environment.name == "" ? 1 : 0

  name                           = "${local.resource_prefix}containerapp"
  location                       = local.resource_group.location
  resource_group_name            = local.resource_group.name
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.container_app.id
  infrastructure_subnet_id       = local.launch_in_vnet ? azurerm_subnet.container_apps_infra_subnet[0].id : null
  internal_load_balancer_enabled = local.container_app_environment_internal_load_balancer_enabled
  logs_destination               = "log-analytics"

  tags = local.tags
}

resource "azurerm_monitor_diagnostic_setting" "container_app_env" {
  count = local.existing_container_app_environment.name == "" ? 1 : 0

  name                       = "${local.resource_prefix}-containerapp-diag"
  target_resource_id         = local.container_app_environment.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.container_app.id
  eventhub_name              = local.enable_event_hub ? azurerm_eventhub.container_app[0].name : null

  enabled_log {
    category_group = "Audit"
  }

  # The below metrics are kept in to avoid a diff in the Terraform Plan output
  metric {
    category = "AllMetrics"
    enabled  = false
  }
}

resource "azurerm_container_app_environment_storage" "container_app_env" {
  count = local.enable_container_app_file_share ? 1 : 0

  name                         = "h${local.resource_prefix_sha_short}-storage"
  container_app_environment_id = local.container_app_environment.id
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
  container_app_environment_id = local.container_app_environment.id
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
    for_each = local.escrow_container_app_secrets_in_key_vault ? {} : local.container_app_secrets

    content {
      name  = secret.value["name"]
      value = secret.value["value"]
    }
  }

  dynamic "secret" {
    for_each = local.container_app_secrets_in_key_vault

    content {
      name                = secret.value["name"]
      key_vault_secret_id = secret.value["key_vault_secret_id"]
      identity            = azurerm_user_assigned_identity.containerapp[0].id
    }
  }

  dynamic "identity" {
    for_each = length(local.container_app_identity_ids) > 0 ? [1] : []

    content {
      type         = "UserAssigned"
      identity_ids = local.container_app_identity_ids
    }
  }

  registry {
    server               = local.registry_server
    username             = local.registry_use_managed_identity == false ? local.registry_username : null
    password_secret_name = local.registry_use_managed_identity == false ? "acr-password" : null
    identity             = local.registry_use_managed_identity ? azurerm_user_assigned_identity.containerapp[0].id : null
  }

  template {
    dynamic "init_container" {
      for_each = each.value == "main" && local.enable_init_container ? [1] : []

      content {
        name    = "${each.value}-init"
        image   = local.init_container_image != "" ? local.init_container_image : "${local.registry_server}/${local.image_name}:${local.image_tag}"
        cpu     = local.container_cpu
        memory  = "${local.container_memory}Gi"
        command = local.init_container_command

        dynamic "env" {
          for_each = local.container_app_env_vars

          content {
            name        = env.value["name"]
            secret_name = lookup(env.value, "secretRef", null)
            value       = lookup(env.value, "value", null)
          }
        }
      }
    }

    container {
      name    = each.value
      image   = "${local.registry_server}/${local.image_name}:${local.image_tag}"
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
        for_each = local.container_app_env_vars

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
