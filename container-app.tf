resource "azapi_resource" "container_app_env" {
  type      = "Microsoft.App/managedEnvironments@2022-03-01"
  parent_id = local.resource_group.id
  location  = local.resource_group.location
  name      = local.container_app_env_name

  body = jsonencode({
    properties = {
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = azurerm_log_analytics_workspace.container_app.workspace_id
          sharedKey  = azurerm_log_analytics_workspace.container_app.primary_shared_key
        }
      }
      vnetConfiguration = local.launch_in_vnet ? {
        infrastructureSubnetId = azurerm_subnet.container_apps_infra_subnet[0].id
        internal               = false
      } : null
    }
  })

  response_export_values = [
    "properties.staticIp",
  ]

  tags = local.tags
}

resource "azapi_resource" "default" {
  type      = "Microsoft.App/containerApps@2022-03-01"
  parent_id = local.resource_group.id
  location  = local.resource_group.location
  name      = local.container_app_name
  body = jsonencode({
    properties : {
      managedEnvironmentId = azapi_resource.container_app_env.id
      configuration = {
        ingress = {
          external   = true
          targetPort = local.container_port
        }
        secrets = concat([
          {
            "name" : "acr-password",
            "value" : local.registry_password
          },
          {
            "name" : "applicationinsights--connectionstring",
            "value" : azurerm_application_insights.main.connection_string
          },
          {
            "name" : "applicationinsights--instrumentationkey",
            "value" : azurerm_application_insights.main.instrumentation_key
          },
          ],
          local.enable_redis_cache ? [
            {
              name  = "connectionstrings--redis",
              value = azurerm_redis_cache.default[0].primary_connection_string
            }
          ] : [],
          local.container_app_blob_storage_sas_secret,
          [
            for env_name, env_value in local.container_secret_environment_variables : {
              name  = lower(replace(env_name, "_", "-"))
              value = env_value
            }
        ])
        registries = [
          {
            "server" : local.registry_server,
            "username" : local.registry_username,
            "passwordSecretRef" : "acr-password"
          }
        ]
      }
      template = {
        containers = [
          {
            name  = "main"
            image = "${local.registry_server}/${local.image_name}:${local.image_tag}"
            resources = {
              cpu    = local.container_cpu
              memory = "${local.container_memory}Gi"
            }
            command = local.container_command
            probes  = local.enable_container_health_probe ? local.container_health_probe : null
            env = concat(
              [
                {
                  "name" : "ApplicationInsights__ConnectionString",
                  "secretRef" : "applicationinsights--connectionstring"
                },
                {
                  "name" : "ApplicationInsights__InstrumentationKey",
                  "secretRef" : "applicationinsights--instrumentationkey"
                }
              ],
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
                for env_name, env_value in local.container_secret_environment_variables : {
                  name      = env_name
                  secretRef = lower(replace(env_name, "_", "-"))
                }
            ])
          }
        ]
        scale = {
          minReplicas = local.container_min_replicas
          maxReplicas = local.container_max_replicas
          rules = [
            {
              name = "concurrent-http-requests",
              http = {
                metadata = {
                  concurrentRequests = local.container_scale_rule_concurrent_request_count
                }
              }
            },
            local.container_scale_rule_scale_down_out_of_hours ?
            {
              name = "outside-of-normal-operating-hours",
              custom = {
                type = "cron"
                metadata = {
                  timezone        = "Europe/London"
                  start           = local.container_scale_rule_out_of_hours_start
                  end             = local.container_scale_rule_out_of_hours_end
                  desiredReplicas = local.container_min_replicas
                }
              }
            } : null,
          ]
        }
      }
    }
  })

  response_export_values = [
    "properties.outboundIpAddresses",
    "properties.configuration.ingress.fqdn",
  ]

  tags = local.tags
}

resource "azapi_resource" "worker" {
  count = local.enable_worker_container ? 1 : 0

  type      = "Microsoft.App/containerApps@2022-03-01"
  parent_id = local.resource_group.id
  location  = local.resource_group.location
  name      = local.container_app_worker_name
  body = jsonencode({
    properties : {
      managedEnvironmentId = azapi_resource.container_app_env.id
      configuration = {
        secrets = concat([
          {
            "name" : "acr-password",
            "value" : local.registry_password
          }
          ],
          [
            for env_name, env_value in local.container_secret_environment_variables : {
              name  = lower(replace(env_name, "_", "-"))
              value = env_value
            }
        ])
        registries = [
          {
            "server" : local.registry_server,
            "username" : local.registry_username,
            "passwordSecretRef" : "acr-password"
          }
        ]
      }
      template = {
        containers = [
          {
            name  = "worker"
            image = "${local.registry_server}/${local.image_name}:${local.image_tag}"
            resources = {
              cpu    = local.container_cpu
              memory = "${local.container_memory}Gi"
            }
            command = local.worker_container_command
            env = concat([
              for env_name, env_value in local.container_environment_variables : {
                name  = env_name
                value = env_value
              }
              ],
              [
                for env_name, env_value in local.container_secret_environment_variables : {
                  name      = env_name
                  secretRef = lower(replace(env_name, "_", "-"))
                }
            ])
          }
        ]
        scale = {
          minReplicas = local.worker_container_min_replicas
          maxReplicas = local.worker_container_max_replicas
        }
      }
    }
  })

  response_export_values = [
    "properties.outboundIpAddresses",
  ]

  tags = local.tags
}
