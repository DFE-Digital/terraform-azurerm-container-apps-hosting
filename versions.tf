terraform {
  required_version = ">= 1.4.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.76.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.13.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
  }
}
