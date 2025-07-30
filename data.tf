data "azurerm_virtual_network" "existing_virtual_network" {
  count = local.existing_virtual_network == "" ? 0 : 1

  name                = local.existing_virtual_network
  resource_group_name = local.existing_resource_group
}

data "azurerm_resource_group" "existing_resource_group" {
  count = local.existing_resource_group == "" ? 0 : 1

  name = local.existing_resource_group
}

data "azurerm_container_app_environment" "existing_container_app_environment" {
  count = local.existing_container_app_environment.name == "" ? 0 : 1

  name                = local.existing_container_app_environment.name
  resource_group_name = local.existing_container_app_environment.resource_group
}

data "azurerm_subscription" "current" {}

data "azurerm_logic_app_workflow" "existing_logic_app_workflow" {
  count = local.existing_logic_app_workflow.name == "" ? 0 : 1

  name                = local.existing_logic_app_workflow.name
  resource_group_name = local.existing_logic_app_workflow.resource_group_name
}

# There is not currently a way to get the full HTTP Trigger callback URL from a Logic App
# so we have to use AzAPI to query the Logic App Workflow for the value instead.
# https://github.com/hashicorp/terraform-provider-azurerm/issues/18866
data "azapi_resource_action" "existing_logic_app_workflow_callback_url" {
  count = local.existing_logic_app_workflow.name == "" ? 0 : 1

  resource_id = "${data.azurerm_logic_app_workflow.existing_logic_app_workflow[0].id}/triggers/http-request-trigger"
  action      = "listCallbackUrl"
  type        = "Microsoft.Logic/workflows/triggers@2019-05-01"

  depends_on = [
    data.azurerm_logic_app_workflow.existing_logic_app_workflow[0]
  ]

  response_export_values = ["value"]
}

data "azurerm_key_vault" "existing_key_vault" {
  count = local.existing_key_vault == "" ? 0 : 1

  name                = local.existing_key_vault
  resource_group_name = local.existing_resource_group
}

data "archive_file" "azure_function" {
  for_each = local.linux_function_health_insights_api

  type        = "zip"
  output_path = "${path.module}/functions/dist/${each.key}.zip"
  source_dir  = "${path.module}/functions/src/${each.key}/"
}

data "azurerm_application_gateway" "existing_agw" {
  count = local.launch_in_vnet && local.restrict_container_apps_to_agw_inbound_only && local.container_apps_allow_agw_resource.name != "" ? 1 : 0

  name                = local.container_apps_allow_agw_resource.name
  resource_group_name = local.container_apps_allow_agw_resource.resource_group_name
}

data "azurerm_virtual_network" "existing_agw_vnet" {
  count = local.launch_in_vnet && local.restrict_container_apps_to_agw_inbound_only && local.container_apps_allow_agw_resource.vnet_name != "" ? 1 : 0

  name                = local.container_apps_allow_agw_resource.vnet_name
  resource_group_name = local.container_apps_allow_agw_resource.resource_group_name
}

data "azurerm_public_ip" "existing_agw_ip" {
  count = local.container_apps_allow_agw_pip_resource_id != null ? 1 : 0

  name                = element(local.container_apps_allow_agw_pip_resource_id, 8)
  resource_group_name = element(local.container_apps_allow_agw_pip_resource_id, 4)
}

resource "terraform_data" "function_app_package_sha" {
  for_each = local.linux_function_health_insights_api

  input = filesha256(data.archive_file.azure_function[each.key].output_path)
}
