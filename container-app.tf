resource "azurerm_log_analytics_workspace" "container_app" {
  name                = "${local.resource_prefix}containerapp"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azapi_resource" "container_app_env" {
  type      = "Microsoft.App/managedEnvironments@2022-03-01"
  parent_id = azurerm_resource_group.default.id
  location  = azurerm_resource_group.default.location
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
      vnetConfiguration = {
        infrastructureSubnetId = azurerm_subnet.container_apps_infra_subnet.id
        internal               = false
      }
    }
  })
}

resource "azapi_resource" "default" {
  type      = "Microsoft.App/containerApps@2022-03-01"
  parent_id = azurerm_resource_group.default.id
  location  = azurerm_resource_group.default.location
  name      = "${local.resource_prefix}-${local.image_name}"
  body = jsonencode({
    properties : {
      managedEnvironmentId = azapi_resource.container_app_env.id
      configuration = {
        ingress = {
          external   = true
          targetPort = local.container_port
        }
        secrets = [
          {
            "name" : "acr-password",
            "value" : local.registry_password
          }
        ]
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
            env = [
              for env_name, env_value in local.container_environment_variables : {
                name  = env_name
                value = env_value
              }
            ]
          }
        ]
        scale = {
          minReplicas = local.container_min_replicas
          maxReplicas = local.container_max_replicas
        }
      }
    }
  })
}
