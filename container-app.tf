resource "azurerm_log_analytics_workspace" "container_app" {
  name                = "${local.resource_prefix}containerapp"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azapi_resource" "container_app_env" {
  type      = "Microsoft.App/managedEnvironments@2022-03-01"
  parent_id = local.resource_group.id
  location  = local.resource_group.location
  name      = "${local.resource_prefix}containerapp"

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
  name      = "${local.resource_prefix}-${local.image_name}"
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
            name  = "main"
            image = "${local.registry_server}/${local.image_name}:${local.image_tag}"
            resources = {
              cpu    = local.container_cpu
              memory = "${local.container_memory}Gi"
            }
            command = local.container_command
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
          minReplicas = local.container_min_replicas
          maxReplicas = local.container_max_replicas
        }
      }
    }
  })
  tags = local.tags
}
