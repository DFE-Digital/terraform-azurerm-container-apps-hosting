locals {
  environment                        = var.environment
  project_name                       = var.project_name
  resource_prefix                    = "${local.environment}${local.project_name}"
  azure_location                     = var.azure_location
  virtual_network_address_space      = var.virtual_network_address_space
  virtual_network_address_space_mask = element(split("/", local.virtual_network_address_space), 1)
  container_apps_infra_subnet_cidr   = cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 0)
  enable_container_registry          = var.enable_container_registry
}
