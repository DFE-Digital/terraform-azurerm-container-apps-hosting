locals {
  environment                        = var.environment
  project_name                       = var.project_name
  resource_prefix                    = "${local.environment}${local.project_name}"
  azure_location                     = var.azure_location
  virtual_network_address_space      = var.virtual_network_address_space
  virtual_network_address_space_mask = element(split("/", local.virtual_network_address_space), 1)
  container_apps_infra_subnet_cidr   = cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 0)
  enable_container_registry          = var.enable_container_registry
  registry_server                    = local.enable_container_registry ? azurerm_container_registry.acr[0].login_server : var.registry_server
  registry_username                  = local.enable_container_registry ? azurerm_container_registry.acr[0].admin_username : var.registry_username
  registry_password                  = local.enable_container_registry ? azurerm_container_registry.acr[0].admin_password : var.registry_password
  image_name                         = var.image_name
  image_tag                          = var.image_tag
  container_cpu                      = var.container_cpu
  container_memory                   = var.container_memory
  container_min_replicas             = var.container_min_replicas
  container_max_replicas             = var.container_max_replicas
  container_port                     = var.container_port
  container_command                  = var.container_command
  container_environment_variables    = var.container_environment_variables
}
