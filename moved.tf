moved {
  from = azurerm_private_dns_zone.storage_private_link[0]
  to   = azurerm_private_dns_zone.storage_private_link_blob[0]
}

moved {
  from = azurerm_private_dns_zone_virtual_network_link.storage_private_link[0]
  to   = azurerm_private_dns_zone_virtual_network_link.storage_private_link_blob[0]
}

moved {
  from = azurerm_private_dns_a_record.storage_private_link[0]
  to   = azurerm_private_dns_a_record.storage_private_link_blob[0]
}
