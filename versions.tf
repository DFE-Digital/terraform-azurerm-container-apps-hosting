terraform {
  required_version = ">= 1.3.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.35.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.1.0"
    }
  }
}
