resource "azurerm_resource_group" "default" {
  count = local.existing_resource_group == "" ? 1 : 0

  name     = local.resource_prefix
  location = local.azure_location
  tags     = local.tags
}

resource "azurerm_management_lock" "default" {
  count = local.enable_resource_group_lock ? 1 : 0

  name       = "${local.resource_prefix}-lock"
  scope      = local.resource_group.id
  lock_level = "CanNotDelete"
  notes      = "Resources in this Resource Group cannot be deleted. Please remove the lock first."
}
