terraform {
  required_version = ">= 1.2.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.25.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.0.0"
    }
  }
}
