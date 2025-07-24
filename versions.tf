terraform {
  required_version = "~> 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.37"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.13"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.6"
    }
  }
}
