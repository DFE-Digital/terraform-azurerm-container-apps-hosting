resource "azapi_resource" "custom_container_apps" {
  for_each = local.custom_container_apps

  type                   = "Microsoft.App/containerApps@2022-03-01"
  parent_id              = local.resource_group.id
  location               = local.resource_group.location
  name                   = "${local.resource_prefix}${each.key}containerapp"
  body                   = jsonencode(each.value["body"])
  response_export_values = each.value["response_export_values"]

  tags = local.tags
}
