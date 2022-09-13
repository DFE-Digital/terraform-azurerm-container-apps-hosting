# Azure Container Apps Hosting terraform module

This module creates and manages [Azure Container Apps][1], deployed within an [Azure Virtual Network][2].

## Usage

```hcl
module "azure_container_apps_hosting" {
  source  = "github.com/DFE-Digital/terraform-azurem-container-apps-hosting?ref=main"
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

No providers.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->

[1]: https://azure.microsoft.com/en-us/services/container-apps
[2]: https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview
