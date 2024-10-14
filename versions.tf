terraform {
  required_version = ">= 1.9.5, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.13.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.6.0"
    }
  }
}
