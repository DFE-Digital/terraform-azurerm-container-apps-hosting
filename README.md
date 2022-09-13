# Azure Container Apps Hosting terraform module

This module creates and manages [Azure Container Apps][1], deployed within an [Azure Virtual Network][2].

## Usage

```hcl
module "azure_container_apps_hosting" {
  source  = "github.com/DFE-Digital/terraform-azurem-container-apps-hosting?ref=main"

  environment    = "dev"
  project_name   = "myproject"
  azure_location = "uksouth"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.9 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >= 0.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.20.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | 0.5.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.22.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.container_app_env](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.default](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_container_registry.acr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry) | resource |
| [azurerm_log_analytics_workspace.container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_resource_group.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_route_table.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_subnet.container_apps_infra_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_route_table_association.container_apps_infra_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_virtual_network.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_location"></a> [azure\_location](#input\_azure\_location) | Azure location in which to launch resources. | `string` | n/a | yes |
| <a name="input_container_command"></a> [container\_command](#input\_container\_command) | Container command | `list(any)` | `[]` | no |
| <a name="input_container_cpu"></a> [container\_cpu](#input\_container\_cpu) | Number of container CPU cores | `number` | `1` | no |
| <a name="input_container_environment_variables"></a> [container\_environment\_variables](#input\_container\_environment\_variables) | Container environment variables | `map(string)` | `{}` | no |
| <a name="input_container_max_replicas"></a> [container\_max\_replicas](#input\_container\_max\_replicas) | Container max replicas | `number` | `2` | no |
| <a name="input_container_memory"></a> [container\_memory](#input\_container\_memory) | Container memory in GB | `number` | `2` | no |
| <a name="input_container_min_replicas"></a> [container\_min\_replicas](#input\_container\_min\_replicas) | Container min replicas | `number` | `1` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | Container port | `number` | `80` | no |
| <a name="input_enable_container_registry"></a> [enable\_container\_registry](#input\_enable\_container\_registry) | Set to true to create a container registry | `bool` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name. Will be used along with `project_name` as a prefix for all resources. | `string` | n/a | yes |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Image name | `string` | n/a | yes |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Image tag | `string` | `"latest"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name. Will be used along with `environment` as a prefix for all resources. | `string` | n/a | yes |
| <a name="input_registry_password"></a> [registry\_password](#input\_registry\_password) | Container registry password (required if `enable_container_registry` is false) | `string` | `""` | no |
| <a name="input_registry_server"></a> [registry\_server](#input\_registry\_server) | Container registry server (required if `enable_container_registry` is false) | `string` | `""` | no |
| <a name="input_registry_username"></a> [registry\_username](#input\_registry\_username) | Container registry username (required if `enable_container_registry` is false) | `string` | `""` | no |
| <a name="input_virtual_network_address_space"></a> [virtual\_network\_address\_space](#input\_virtual\_network\_address\_space) | Virtual Network address space CIDR | `string` | `"172.16.0.0/12"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

[1]: https://azure.microsoft.com/en-us/services/container-apps
[2]: https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview
