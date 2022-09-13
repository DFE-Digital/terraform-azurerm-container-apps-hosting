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
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.22.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_location"></a> [azure\_location](#input\_azure\_location) | Azure location in which to launch resources. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name. Will be used along with `project_name` as a prefix for all resources. | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name. Will be used along with `environment` as a prefix for all resources. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

[1]: https://azure.microsoft.com/en-us/services/container-apps
[2]: https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview
