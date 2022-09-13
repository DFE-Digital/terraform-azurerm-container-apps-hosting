terraform {
  required_version = ">= 1.2.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.20.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 0.5.0"
    }
  }
}
