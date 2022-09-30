# Azure Container Apps Hosting terraform module

[![Terraform CI](https://github.com/DFE-Digital/terraform-azurerm-container-apps-hosting/actions/workflows/continuous-integration-terraform.yml/badge.svg?branch=main)](https://github.com/DFE-Digital/terraform-azurerm-container-apps-hosting/actions/workflows/continuous-integration-terraform.yml?branch=main)
[![GitHub release](https://img.shields.io/github/release/DFE-Digital/terraform-azurerm-container-apps-hosting)](https://github.com/DFE-Digital/terraform-azurerm-container-apps-hosting/releases)

This module creates and manages [Azure Container Apps][1], deployed within an [Azure Virtual Network][2].

## Usage

```hcl
module "azure_container_apps_hosting" {
  source  = "github.com/DFE-Digital/terraform-azurerm-container-apps-hosting?ref=v0.5.1"

  environment    = "dev"
  project_name   = "myproject"
  azure_location = "uksouth"

  enable_container_registry = true

  image_name        = "myimage"
  container_command = ["/bin/bash", "-c". "echo hello && sleep 86400"]

  # Note: It is recommended to use `container_secret_environment_variables` rather than `container_environment_variables`.
  #       This ensures that environment variables are set as `secrets` within the container app revision.
  #       If they are set directly as `env`, they can be exposed when running `az containerapp` commands, especially
  #       if those commands are ran as part of CI/CD.
  container_secret_environment_variables = {
    "FOO" = "bar"
  }

  enable_mssql_database       = true
  mssql_server_admin_password = "S3crEt"
  mssql_database_name         = "mydatabase"
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
| [azurerm_mssql_database.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database) | resource |
| [azurerm_mssql_database_extended_auditing_policy.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database_extended_auditing_policy) | resource |
| [azurerm_mssql_server.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server) | resource |
| [azurerm_mssql_server_extended_auditing_policy.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server_extended_auditing_policy) | resource |
| [azurerm_private_dns_a_record.mssql_private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_zone.mssql_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.mssql_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.default_mssql](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_resource_group.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_route_table.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_storage_account.mssql_security_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_subnet.container_apps_infra_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.container_instances_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.mssql_private_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_route_table_association.container_apps_infra_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.containerinstances_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.mssql_private_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_virtual_network.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_resource_group.existing_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_virtual_network.existing_virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

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
| <a name="input_container_secret_environment_variables"></a> [container\_secret\_environment\_variables](#input\_container\_secret\_environment\_variables) | Container environment variables, which are defined as `secrets` within the container app configuration. This is to help reduce the risk of accidently exposing secrets. | `map(string)` | `{}` | no |
| <a name="input_enable_container_registry"></a> [enable\_container\_registry](#input\_enable\_container\_registry) | Set to true to create a container registry | `bool` | n/a | yes |
| <a name="input_enable_mssql_database"></a> [enable\_mssql\_database](#input\_enable\_mssql\_database) | Set to true to create an Azure SQL server/database, with a private endpoint within the virtual network | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name. Will be used along with `project_name` as a prefix for all resources. | `string` | n/a | yes |
| <a name="input_existing_resource_group"></a> [existing\_resource\_group](#input\_existing\_resource\_group) | Conditionally launch resources into an exiting resource group. Specifying this will not reate a new resource group. | `string` | `""` | no |
| <a name="input_existing_virtual_network"></a> [existing\_virtual\_network](#input\_existing\_virtual\_network) | Conditionally use an existing virtual network. The `virtual_network_address_space` must match an existing address space in the VNet. This also requires the resource group name. | `string` | `""` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Image name | `string` | n/a | yes |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Image tag | `string` | `"latest"` | no |
| <a name="input_launch_in_vnet"></a> [launch\_in\_vnet](#input\_launch\_in\_vnet) | Conditionally launch into a VNet | `bool` | `true` | no |
| <a name="input_mssql_database_name"></a> [mssql\_database\_name](#input\_mssql\_database\_name) | The name of the MSSQL database to create. Must be set if `enable_mssql_database` is true | `string` | `""` | no |
| <a name="input_mssql_max_size_gb"></a> [mssql\_max\_size\_gb](#input\_mssql\_max\_size\_gb) | The max size of the database in gigabytes | `number` | `2` | no |
| <a name="input_mssql_server_admin_password"></a> [mssql\_server\_admin\_password](#input\_mssql\_server\_admin\_password) | The administrator password for the MSSQL server. Must be set if `enable_mssql_database` is true | `string` | `""` | no |
| <a name="input_mssql_sku_name"></a> [mssql\_sku\_name](#input\_mssql\_sku\_name) | Specifies the name of the SKU used by the database | `string` | `"Basic"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name. Will be used along with `environment` as a prefix for all resources. | `string` | n/a | yes |
| <a name="input_registry_password"></a> [registry\_password](#input\_registry\_password) | Container registry password (required if `enable_container_registry` is false) | `string` | `""` | no |
| <a name="input_registry_server"></a> [registry\_server](#input\_registry\_server) | Container registry server (required if `enable_container_registry` is false) | `string` | `""` | no |
| <a name="input_registry_username"></a> [registry\_username](#input\_registry\_username) | Container registry username (required if `enable_container_registry` is false) | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_virtual_network_address_space"></a> [virtual\_network\_address\_space](#input\_virtual\_network\_address\_space) | Virtual Network address space CIDR | `string` | `"172.16.0.0/12"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_azurerm_resource_group_default"></a> [azurerm\_resource\_group\_default](#output\_azurerm\_resource\_group\_default) | n/a |
<!-- END_TF_DOCS -->

[1]: https://azure.microsoft.com/en-us/services/container-apps
[2]: https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview
