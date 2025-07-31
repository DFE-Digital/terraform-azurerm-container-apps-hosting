# Azure Container Apps Hosting terraform module

[![Terraform CI](https://github.com/DFE-Digital/terraform-azurerm-container-apps-hosting/actions/workflows/continuous-integration-terraform.yml/badge.svg?branch=main)](https://github.com/DFE-Digital/terraform-azurerm-container-apps-hosting/actions/workflows/continuous-integration-terraform.yml?branch=main)
[![Tflint](https://github.com/DFE-Digital/terraform-azurerm-container-apps-hosting/actions/workflows/continuous-integration-tflint.yml/badge.svg?branch=main)](https://github.com/DFE-Digital/terraform-azurerm-container-apps-hosting/actions/workflows/continuous-integration-tflint.yml?branch=main)
[![GitHub release](https://img.shields.io/github/release/DFE-Digital/terraform-azurerm-container-apps-hosting)](https://github.com/DFE-Digital/terraform-azurerm-container-apps-hosting/releases)

This module creates and manages [Azure Container Apps][1], deployed within an [Azure Virtual Network][2].

## Usage

### Terraform

```hcl
module "azure_container_apps_hosting" {
  source = "github.com/DFE-Digital/terraform-azurerm-container-apps-hosting?ref=v2.0.0"

  environment    = "dev"
  project_name   = "myproject"
  azure_location = "uksouth"

  ## Set launch_in_vnet to false to prevent deploying a new Virtual Network
  # launch_in_vnet = false

  ## Specify the name of an existing Virtual Network if you want to use that instead of creating a new one
  # existing_virtual_network = "my-vnet-example-name"

  ## Specify the name of an existing Resource Group to deploy resources into
  # existing_resource_group = "my-existing-resource-group"

  # Set the default IP Range that will be assigned to the Virtual Network used by the Container Apps
  virtual_network_address_space = "172.32.10.0/24"

  # Create an Azure Container Registry and connect it to the Container App Environment
  enable_container_registry = true
  # registry_ipv4_allow_list = [ "8.8.8.8/32" ]
  ## Specify the connection details for an existing Container Registry if 'enable_container_registry' is false
  # registry_server                     = ""
  # registry_username                   = ""
  # registry_password                   = ""
  ## Change the SKU of ACR from "Standard"
  # registry_sku = "Premium"
  ## Change the retention period (only applicable to Premium SKU)
  # enable_registry_retention_policy = true
  # registry_retention_days          = 90
  ## Disable admin username and access keys if authenticating using a service principal
  # registry_admin_enabled = false
  ## If you dont need a public registry, set this to false to prevent internet access
  # registry_public_access_enabled = false
  ## If 'registry_admin_enabled' is disabled, you can create a User Assigned Managed Identity to authenticate with ACR
  # registry_use_managed_identity = true
  ## The UAMI needs the 'AcrPull' role assignment which can be done manually or applied with terraform
  # registry_managed_identity_assign_role = false

  ## Specify a custom name for the Container App
  # container_app_name_override = "my-awesome-app"

  # Specify the Container Image and Tag that will get pulled from the Container Registry
  image_name = "my-app"
  image_tag  = "latest"

  ## Deploy an Azure SQL Server and create an initial database
  # enable_mssql_database          = true
  # mssql_sku_name                 = "Basic"
  # mssql_max_size_gb              = 2
  # mssql_database_name            = "my-database"
  # mssql_firewall_ipv4_allow_list = [ "8.8.8.8", "1.1.1.1" ]
  # mssql_server_public_access_enabled = true
  # mssql_version = "12.0"
  ## If you want to use a local SQL administrator account you can set a password with
  # mssql_server_admin_password    = "change-me-!!!"
  ## Or, if you want to assign an Azure AD Administrator you must specify
  # mssql_azuread_admin_username = "my-email-address@DOMAIN"
  # mssql_azuread_admin_object_id = "aaaa-bbbb-cccc-dddd"
  ## Restrict SQL authentication to Azure AD
  # mssql_azuread_auth_only = true

  ## Deploy an Azure Database for PostgreSQL flexible server and create an initial database
  # enable_postgresql_database        = true
  # postgresql_server_version         = "11"
  # postgresql_administrator_password = "change-me-!!!"
  # postgresql_administrator_login    = "my-admin-user"
  # postgresql_availability_zone      = "1"
  # postgresql_max_storage_mb         = 32768
  # postgresql_sku_name               = "B_Standard_B1ms"
  # postgresql_collation              = "en_US.utf8"
  # postgresql_charset                = "utf8"
  # postgresql_enabled_extensions     = "citext,pgcrypto"
  # postgresql_network_connectivity_method = "private" # or "public" to enable Public network access
  # postgresql_firewall_ipv4_allow = {
  #   "my-rule-1" = {
  #     start_ip_address = "0.0.0.0",
  #     end_ip_address = "0.0.0.0"
  #   }
  #   # etc
  # }

  ## Deploy an Azure Cache for Redis instance
  # enable_redis_cache                   = true
  # redis_cache_version                  = 6
  # redis_cache_family                   = "C"
  # redis_cache_sku                      = "Basic"
  # redis_cache_capacity                 = 1
  # redis_cache_patch_schedule_day       = "Sunday"
  # redis_cache_patch_schedule_hour      = 23
  # redis_cache_firewall_ipv4_allow_list = [ "8.8.8.8", "1.1.1.1" ]

  ## Deploy a Health insights Azure function
  # enable_health_insights_api = true

  ## Deploy custom Azure Functions
  ## Note: Terraform will not deploy the app source itself, you will need to do that
  # linux_function_apps = {
  #   "my-function" = {
  #     runtime         = "python"
  #     runtime_version = "3.11"
  #     app_settings = {
  #       "MY_APP_SETTING" = "foo"
  #     }
  #     allowed_origins                                = ["*"]
  #   }
  # }

  ## Deploy an Azure Storage Account and connect it to the Container App
  # enable_container_app_blob_storage                = false
  # container_app_blob_storage_public_access_enabled = false
  # container_app_blob_storage_ipv4_allow_list       = [ "8.8.8.8", "1.1.1.1" ]
  ## This will remove the automatically generated 'ConnectionStrings__BlobStorage' environment var from the Container App
  create_container_app_blob_storage_sas = false
  ## Change the expiration date for SAS tokens. Format 'DD.HH:MM:SS'
  # storage_account_sas_expiration_period = "00.01:00:00"
  ## Deploy a File Share
  # enable_container_app_file_share = true
  ## If you need maximum SMB compatibility for your File Share
  # container_app_file_share_security_profile = "compatibility"
  ## Increase the hardware resources given to each Container
  # container_cpu    = 1 # core count
  # container_memory = 2 # gigabyte

  # Change the Port number that the Container is listening on
  # container_port = 80

  # Change the number of replicas (commonly called 'instances') for the Container.
  # Setting 'container_max_replicas' to 1 will prevent scaling
  container_min_replicas = 2
  container_max_replicas = 10

  # Maximum number of concurrent HTTP requests before a new replica is created
  container_scale_http_concurrency = 100

  ## Enable out-of-hours scale down to reduce resource usage
  # container_scale_out_at_defined_time = false
  # container_scale_out_rule_start      = "0 9 * * *" # Must be a valid cron time
  # container_scale_out_rule_end        = "0 17 * * *" # Must be a valid cron time

  # Enable a Liveness probe that checks to ensure the Container is responding. If this fails, the Container is restarted
  enable_container_health_probe   = true
  container_health_probe_interval = 60 # seconds
  container_health_probe_protocol = "https" # or "tcp"
  container_health_probe_path     = "/" # relative url to your status page (e.g. /healthcheck, /health, /status)

  # What command should be used to start your Container
  container_command = [ "/bin/bash", "-c", "echo hello && sleep 86400" ]

  ## Set environment variables that are passed to the Container at runtime. (See note below)
  ## It is strongly recommended not to include any sensitive or secret values here
  # container_environment_variables = {
  #   "Environment" = "Development"
  # }

  ## Note: It is recommended to use `container_secret_environment_variables` rather than `container_environment_variables`.
  ##       This ensures that environment variables are set as `secrets` within the container app revision.
  ##       If they are set directly as `env`, they can be exposed when running `az containerapp` commands, especially
  ##       if those commands are ran as part of CI/CD.
  # container_secret_environment_variables = {
  #   "RedirectUri" = "https://www.example.com/signin"
  # }

  ## If you want to secure your Container Secrets further, you can leverage Key Vault with RBAC roles
  escrow_container_app_secrets_in_key_vault = true # Store all secret environment variables in a Key Vault
  #existing_key_vault = "my-key-vault" # Set this to the name of an existing Key Vault to prevent the deployment of a new one
  #key_vault_managed_identity_assign_role = true
  key_vault_access_ipv4 = [ 8.8.8.8/32 ] # List of IP addresses that are permitted to modify the Key Vault that holds the secrets

  ## If your app requires a worker container, you can enable it by setting 'enable_worker_container' to true
  # enable_worker_container       = false
  # worker_container_command      = [ "/bin/bash", "-c", "echo hello && sleep 86400" ]
  # worker_container_min_replicas = 1
  # worker_container_max_replicas = 1

  ## Custom container apps
  # custom_container_apps = {
  #   "my-container-app" = {
  #     # managedEnvironmentId = "/existing-managed-environment-id" # Use this if
  #     #                        you need to launch the container in a different
  #     #                        container app environment
  #     configuration = {
  #       activeRevisionsMode = "single",
  #       secrets = [
  #         {
  #           "name"  = "my-secret",
  #           "value" = "S3creTz"
  #         }
  #       ],
  #       ingress = {
  #         external = false
  #       },
  #       registries = [
  #         {
  #           "server"            = "my-registry.com",
  #           "username"          = "me",
  #           "passwordSecretRef" = "my-secret"
  #         }
  #       ],
  #       dapr = {
  #         enabled = false
  #       }
  #     },
  #     template = {
  #       revisionSuffix = "my-container-app",
  #       containers = [
  #         {
  #           name  = "app",
  #           image = "my-registry.com/my-app:latest",
  #           resources = {
  #             cpu = 0.25,
  #             memory = "0.5Gi"
  #           },
  #           command = [
  #             "say",
  #             "'hello world'",
  #             "-v",
  #             "10"
  #           ]
  #         }
  #       ],
  #       scale = {
  #         minReplicas = 0,
  #         maxReplicas = 1
  #       },
  #       volumes = [
  #         {
  #           "name": "myempty",
  #           "storageType": "EmptyDir"
  #         },
  #         {
  #           "name": "azure-files-volume",
  #           "storageType": "AzureFile",
  #           "storageName": "myazurefiles"
  #         }
  #       ]
  #     }
  #   }
  # }

  # Create a DNS Zone, associate a primary domain and map different DNS Records as you require.
  enable_dns_zone      = true
  dns_zone_domain_name = "example.com"

  ## The SOA record contains important information about a domain and who is responsible for it
  # dns_zone_soa_record  = {
  #   email         = "hello.example.com"
  #   host_name     = "ns1-03.azure-dns.com."
  #   expire_time   = "2419200"
  #   minimum_ttl   = "300"
  #   refresh_time  = "3600"
  #   retry_time    = "300"
  #   serial_number = "1"
  #   ttl           = "3600"
  # }

  ## An A record maps a domain to the physical IP address of the computer hosting that domain
  # dns_a_records = {
  #   "example" = {
  #     ttl = 300,
  #     records = [
  #       "1.2.3.4",
  #       "5.6.7.8",
  #     ]
  #   }
  # }

  ## An ALIAS record is a virtual record type DNSimple created to provide CNAME-like behavior on apex domains
  # dns_alias_records = {
  #   "alias-example" = {
  #     ttl = 300,
  #     target_resource_id = "azure_resource_id",
  #   }
  # }

  ## An AAAA record type is a foundational DNS record when IPv6 addresses are used
  # dns_aaaa_records = {
  #   "aaaa-example" = {
  #     ttl = 300,
  #     records = [
  #       "2001:db8::1:0:0:1",
  #       "2606:2800:220:1:248:1893:25c8:1946",
  #     ]
  #   }
  # }

  # A CAA record is used to specify which certificate authorities (CAs) are allowed to issue certificates for a domain
  # dns_caa_records = {
  #   "caa-example" = {
  #     ttl = 300,
  #     records = [
  #       {
  #         flags = 0,
  #         tag   = "issue",
  #         value = "example.com"
  #       },
  #       {
  #         flags = 0
  #         tag   = "issuewild"
  #         value = ";"
  #       },
  #       {
  #         flags = 0
  #         tag   = "iodef"
  #         value = "mailto:caa@example.com"
  #       }
  #     ]
  #   }
  # }

  ## A CNAME record provides an alias for another domain
  # dns_cname_records = {
  #   "cname-example" = {
  #     ttl    = 300,
  #     record = "example.com",
  #   }
  # }

  ## A MX record directs email to a mail server
  # dns_mx_records = {
  #   "mx-example" = {
  #     ttl = 300,
  #     records = [
  #       {
  #         preference = 10,
  #         exchange   = "mail.example.com"
  #       }
  #     ]
  #   }
  # }

  ## An NS record contains the name of the authoritative name server within the DNS zone
  # dns_ns_records = {
  #   "ns-example" = {
  #     ttl = 300,
  #     records = [
  #       "ns-1.net",
  #       "ns-1.com",
  #       "ns-1.org",
  #       "ns-1.info"
  #     ]
  #   }
  # }

  ## A PTR record is used for reverse DNS lookups, and it matches domain names with IP addresses
  # dns_ptr_records = {
  #   "ptr-example" = {
  #     ttl = 300,
  #     records = [
  #       "example.com",
  #     ]
  #   }
  # }

  ## A SRV record specifies a host and port for specific services such as voice over IP (VoIP), instant messaging etc
  # dns_srv_records = {
  #   "srv-example" = {
  #     ttl = 300,
  #     records = [
  #       {
  #         priority = 1,
  #         weight   = 5,
  #         port     = 8080
  #         target   = target.example.com
  #       }
  #     ]
  #   }
  # }

  ## A TXT record stores text notes on a DNS server
  # dns_txt_records = {
  #   "txt-example" = {
  #     ttl = 300,
  #     records = [
  #       "google-site-authenticator",
  #       "more site information here"
  #     ]
  #   }
  # }

  ## Add additional service endpoints to the infrastructure subnet
  # container_apps_infra_subnet_service_endpoints = ["Microsoft.KeyVault"]

  # Deploy an Azure Front Door CDN. This will be configured as the entrypoint for all traffic accessing your Containers
  enable_cdn_frontdoor           = true
  # cdn_frontdoor_sku            = "Standard_AzureFrontDoor"
  cdn_frontdoor_response_timeout = 300 # seconds

  # Any domains defined here will be associated to the Front Door as acceptable hosts
  cdn_frontdoor_custom_domains = [
    "example.com",
    "www.example.com"
  ]

  # If you want to set up specific domain redirects, you can specify them with 'cdn_frontdoor_host_redirects'
  cdn_frontdoor_host_redirects = [
    {
      "from" = "example.com",
      "to"   = "www.example.com",
    }
  ]

  ## Override the default Origin hostname if you do not want to use the FQDN of the Container App
  # cdn_frontdoor_origin_fqdn_override = "my-backend-host.acme.org"

  ## Override the default origin ports of 80 (HTTP) and 443 (HTTPS) if required
  # cdn_frontdoor_origin_http_port = 8080
  # cdn_frontdoor_origin_https_port = 4443

  # Add additional HTTP Response Headers to include on every response
  cdn_frontdoor_host_add_response_headers = [
    {
      "name"  = "Strict-Transport-Security",
      "value" = "max-age=31536000",
    }
  ]

  # Remove any surplus HTTP Response Headers that you might not want to include
  cdn_frontdoor_remove_response_headers = [
    "Server",
  ]

  # Deploy an Azure Front Door WAF Rate Limiting Policy
  cdn_frontdoor_enable_rate_limiting              = true

  ## Available options are "Prevention" for blocking any matching traffic, or "Detection" just to report on it
  # cdn_frontdoor_waf_mode                        = "Prevention"

  ## Number of minutes to block the requester's IP Address
  cdn_frontdoor_rate_limiting_duration_in_minutes = 5

  ## How many requests can a single IP make in a minute before the WAF policy gets applied
  # cdn_frontdoor_rate_limiting_threshold         = 300

  ## Provide a list of IP Addresses or Ranges that should be exempt from the WAF Policy
  # cdn_frontdoor_rate_limiting_bypass_ip_list    = [ "8.8.8.8/32" ]

  # Prevent traffic from accessing the Container Apps directly
  restrict_container_apps_to_cdn_inbound_only     = true

  ## Should the CDN keep monitoring the backend pool to ensure traffic can be routed?
  enable_cdn_frontdoor_health_probe       = true
  cdn_frontdoor_health_probe_interval     = 300 # seconds
  cdn_frontdoor_health_probe_path         = "/" # relative url to your status page (e.g. /healthcheck, /health, /status)
  cdn_frontdoor_health_probe_request_type = "GET" # HTTP Method (e.g. GET, POST, HEAD etc)

  ## Switch on/off diagnostic settings for the Azure Front Door CDN
  # cdn_frontdoor_enable_waf_logs        = false
  cdn_frontdoor_enable_access_logs       = true # default: false
  cdn_frontdoor_enable_health_probe_logs = true # default: false

  ## Logs are by default exported to a Log Analytics Workspace so enabling these two values are only necessary if you
  ## want to ingest the logs using a 3rd party service (e.g. logit.io)
  # enable_event_hub = true
  # enable_logstash_consumer = true
  ## Specify which Log Analytics tables you want to send to Event Hub
  # eventhub_export_log_analytics_table_names = [
  #   "AppExceptions"
  # ]

  # Monitoring is disabled by default. If enabled, the following metrics will be monitored:
  # Container App: CPU usage, Memory usage, Latency, Revision count, HTTP regional availability
  # Redis (if enabled): Server Load Average
  enable_monitoring                 = true
  monitor_email_receivers           = [ "list@email.com" ]
  monitor_endpoint_healthcheck      = "/"
  ## If you have an existing Logic App Workflow for routing Alerts then you can specify it here
  # existing_logic_app_workflow = {
  #   name                = "my-logic-app"
  #   resource_group_name = "my-other-rg"
  #   trigger_url         = "https://my-callback-url.tld"
  # }
  alarm_cpu_threshold_percentage    = 80
  alarm_memory_threshold_percentage = 80
  alarm_latency_threshold_ms        = 1000
  alarm_log_ingestion_gb_per_day    = 1

  # Note: that only 1 network watcher can be created within an Azure Subscription
  #     It would probably be advisable to create a Network Watcher outside of this module, as it
  #     may need to be used by other things

  ## Deploy an Azure Network Watcher
  # enable_network_watcher                     = true
  existing_network_watcher_name                = "MyNetworkWatcher"
  existing_network_watcher_resource_group_name = "NetworkWatcherRG"
  # network_watcher_flow_log_retention         = 90 # Days
  # enable_network_watcher_traffic_analytics   = true
  # network_watcher_traffic_analytics_interval = 60

  ## Use a user assigned identity on the Container App.
  # container_app_identities = [azurerm_user_assigned_identity.user_assigned_identity.id]

  # A user assigned managed identity is created for the container app by default, but can be disabled.
  # container_app_use_managed_identity = false

  # Tags are applied to every resource deployed by this module
  # Include them as Key:Value pairs
  tags = {
    "Environment"   = "Dev",
    "My Custom Tag" = "My Value"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.6 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 1.13 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.37 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | ~> 2.6 |
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | ~> 1.13 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.37 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Resources

| Name | Type |
|------|------|
| [azapi_update_resource.container_app_storage_key_rotation_reminder](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/update_resource) | resource |
| [azapi_update_resource.default_network_watcher_nsg_storage_key_rotation_reminder](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/update_resource) | resource |
| [azapi_update_resource.function_app_storage_key_rotation_reminder](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/update_resource) | resource |
| [azapi_update_resource.mssql_security_storage_key_rotation_reminder](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/update_resource) | resource |
| [azapi_update_resource.mssql_threat_protection](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/update_resource) | resource |
| [azurerm_app_configuration.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_configuration) | resource |
| [azurerm_application_insights.function_apps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_application_insights.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_application_insights_smart_detection_rule.ai_data_volume](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_smart_detection_rule) | resource |
| [azurerm_application_insights_smart_detection_rule.ai_dependency_duration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_smart_detection_rule) | resource |
| [azurerm_application_insights_smart_detection_rule.ai_exception_volume](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_smart_detection_rule) | resource |
| [azurerm_application_insights_smart_detection_rule.ai_long_dependency_duration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_smart_detection_rule) | resource |
| [azurerm_application_insights_smart_detection_rule.ai_memory](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_smart_detection_rule) | resource |
| [azurerm_application_insights_smart_detection_rule.ai_response_time](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_smart_detection_rule) | resource |
| [azurerm_application_insights_smart_detection_rule.ai_security](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_smart_detection_rule) | resource |
| [azurerm_application_insights_smart_detection_rule.ai_slow_page](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_smart_detection_rule) | resource |
| [azurerm_application_insights_smart_detection_rule.ai_slow_server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_smart_detection_rule) | resource |
| [azurerm_application_insights_smart_detection_rule.ai_trace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_smart_detection_rule) | resource |
| [azurerm_application_insights_standard_web_test.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_standard_web_test) | resource |
| [azurerm_cdn_frontdoor_custom_domain.custom_container_apps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain) | resource |
| [azurerm_cdn_frontdoor_custom_domain.custom_domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain) | resource |
| [azurerm_cdn_frontdoor_custom_domain_association.custom_domain_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain_association) | resource |
| [azurerm_cdn_frontdoor_endpoint.custom_container_apps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_endpoint) | resource |
| [azurerm_cdn_frontdoor_endpoint.endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_endpoint) | resource |
| [azurerm_cdn_frontdoor_firewall_policy.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_firewall_policy) | resource |
| [azurerm_cdn_frontdoor_origin.custom_container_apps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin) | resource |
| [azurerm_cdn_frontdoor_origin.origin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin) | resource |
| [azurerm_cdn_frontdoor_origin_group.custom_container_apps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin_group) | resource |
| [azurerm_cdn_frontdoor_origin_group.group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin_group) | resource |
| [azurerm_cdn_frontdoor_profile.cdn](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_profile) | resource |
| [azurerm_cdn_frontdoor_route.custom_container_apps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_route) | resource |
| [azurerm_cdn_frontdoor_route.route](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_route) | resource |
| [azurerm_cdn_frontdoor_rule.add_response_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.redirect](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.remove_response_header](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.vdp_security_txt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.vdp_thanks_txt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule_set.add_response_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_rule_set.redirects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_rule_set.remove_response_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_rule_set.vdp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_security_policy.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_security_policy) | resource |
| [azurerm_container_app.container_apps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) | resource |
| [azurerm_container_app.custom_container_apps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) | resource |
| [azurerm_container_app_environment.container_app_env](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) | resource |
| [azurerm_container_app_environment_storage.container_app_env](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment_storage) | resource |
| [azurerm_container_registry.acr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry) | resource |
| [azurerm_dns_a_record.custom_container_frontdoor_custom_domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_dns_a_record.dns_a_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_dns_a_record.dns_alias_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_dns_a_record.frontdoor_custom_domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_dns_aaaa_record.dns_aaaa_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_aaaa_record) | resource |
| [azurerm_dns_caa_record.dns_caa_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_caa_record) | resource |
| [azurerm_dns_cname_record.dns_cname_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_mx_record.dns_mx_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_mx_record) | resource |
| [azurerm_dns_ns_record.dns_ns_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_ns_record) | resource |
| [azurerm_dns_ptr_record.dns_ptr_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_ptr_record) | resource |
| [azurerm_dns_srv_record.dns_srv_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_srv_record) | resource |
| [azurerm_dns_txt_record.custom_container_frontdoor_custom_domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_txt_record) | resource |
| [azurerm_dns_txt_record.dns_txt_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_txt_record) | resource |
| [azurerm_dns_txt_record.frontdoor_custom_domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_txt_record) | resource |
| [azurerm_dns_zone.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_zone) | resource |
| [azurerm_eventhub.container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) | resource |
| [azurerm_eventhub_authorization_rule.listen_only](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_authorization_rule) | resource |
| [azurerm_eventhub_consumer_group.logstash](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_consumer_group) | resource |
| [azurerm_eventhub_namespace.container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) | resource |
| [azurerm_key_vault.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_key_vault_secret.secret_app_setting](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_linux_function_app.function_apps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_linux_function_app.health_api](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_log_analytics_data_export_rule.container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_data_export_rule) | resource |
| [azurerm_log_analytics_query_pack.container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_query_pack) | resource |
| [azurerm_log_analytics_workspace.app_insights](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_log_analytics_workspace.container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_log_analytics_workspace.default_network_watcher_nsg_flow_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_log_analytics_workspace.function_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_management_lock.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_monitor_action_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | resource |
| [azurerm_monitor_activity_log_alert.delete_container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_activity_log_alert.delete_dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_activity_log_alert.delete_frontdoor_cdn](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_activity_log_alert.delete_postgresql_database](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_activity_log_alert.delete_redis_cache](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_activity_log_alert.delete_sql_database](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_activity_log_alert.delete_vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_diagnostic_setting.blobs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.cdn](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.container_app_env](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.default_redis_cache](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.event_hub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.files](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.function_app_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.function_apps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.mssql_security_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.nsg_flow_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_metric_alert.count](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.cpu](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.http](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.latency](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.memory](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.redis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.sql_cpu](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.sql_dtu](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_scheduled_query_rules_alert_v2.exceptions](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2) | resource |
| [azurerm_monitor_scheduled_query_rules_alert_v2.log-analytics-ingestion](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2) | resource |
| [azurerm_monitor_scheduled_query_rules_alert_v2.traces](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2) | resource |
| [azurerm_monitor_smart_detector_alert_rule.ai_smart_dependency_degradation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_smart_detector_alert_rule) | resource |
| [azurerm_monitor_smart_detector_alert_rule.ai_smart_exception_volume](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_smart_detector_alert_rule) | resource |
| [azurerm_monitor_smart_detector_alert_rule.ai_smart_failures](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_smart_detector_alert_rule) | resource |
| [azurerm_monitor_smart_detector_alert_rule.ai_smart_memory_leak](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_smart_detector_alert_rule) | resource |
| [azurerm_monitor_smart_detector_alert_rule.ai_smart_performance_degradation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_smart_detector_alert_rule) | resource |
| [azurerm_monitor_smart_detector_alert_rule.ai_smart_trace_severity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_smart_detector_alert_rule) | resource |
| [azurerm_mssql_database.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database) | resource |
| [azurerm_mssql_database_extended_auditing_policy.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database_extended_auditing_policy) | resource |
| [azurerm_mssql_firewall_rule.default_mssql](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_firewall_rule) | resource |
| [azurerm_mssql_server.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server) | resource |
| [azurerm_mssql_server_extended_auditing_policy.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server_extended_auditing_policy) | resource |
| [azurerm_network_security_group.app_configuration_infra](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.container_apps_infra](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.mssql_infra](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.postgresql_infra](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.redis_infra](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.registry_infra](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.storage_infra](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_rule.allow_app_configuration_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.allow_mssql_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.allow_postgresql_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.allow_redis_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.allow_registry_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.allow_storage_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.allow_subnet_internal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.container_apps_infra_allow_appgateway_inbound_only](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.container_apps_infra_allow_frontdoor_inbound_only](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.container_apps_infra_allow_ips_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_watcher.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher) | resource |
| [azurerm_network_watcher_flow_log.default_network_watcher_nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher_flow_log) | resource |
| [azurerm_postgresql_flexible_server.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server_configuration.extensions](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_database.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |
| [azurerm_postgresql_flexible_server_firewall_rule.firewall_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_firewall_rule) | resource |
| [azurerm_private_dns_a_record.app_configuration_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.container_app_environment_root](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.container_app_environment_wildcard](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.mssql_private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.postgresql_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.redis_cache_private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.registry_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.storage_private_link_blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.storage_private_link_file](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_zone.app_configuration_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.container_app_environment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.mssql_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.postgresql_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.redis_cache_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.registry_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.storage_private_link_blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.storage_private_link_file](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.app_configuration_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.container_app_environment_agw_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.mssql_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.postgresql_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.redis_cache_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.registry_private_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.storage_private_link_blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.storage_private_link_file](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_redis_cache.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redis_cache) | resource |
| [azurerm_redis_firewall_rule.container_app_default_static_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redis_firewall_rule) | resource |
| [azurerm_redis_firewall_rule.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redis_firewall_rule) | resource |
| [azurerm_resource_group.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.containerapp_acrpull](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.containerapp_appconfig_read](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.kv_secret_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.mssql_storageblobdatacontributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_route_table.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_service_plan.function_apps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_storage_account.container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account.default_network_watcher_nsg_flow_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account.function_app_backing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account.mssql_security_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account_network_rules.container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account_network_rules) | resource |
| [azurerm_storage_account_network_rules.default_network_watcher_nsg_flow_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account_network_rules) | resource |
| [azurerm_storage_account_network_rules.function_app_backing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account_network_rules) | resource |
| [azurerm_storage_account_network_rules.mssql_security_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account_network_rules) | resource |
| [azurerm_storage_container.container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_storage_container.mssql_security_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_storage_management_policy.mssql_security_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_management_policy) | resource |
| [azurerm_storage_share.container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) | resource |
| [azurerm_subnet.app_configuration_private_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.container_apps_infra_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.mssql_private_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.postgresql_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.redis_cache_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.registry_private_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.storage_private_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.app_configuration_infra](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.container_apps_infra](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.mssql_infra](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.postgresql_infra](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.redis_infra](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.registry_infra](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.storage_infra](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_route_table_association.app_configuration_private_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.container_apps_infra_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.mssql_private_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.postgresql_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.redis_cache_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.registry_private_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.storage_private_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_user_assigned_identity.containerapp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_user_assigned_identity.function_apps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_user_assigned_identity.mssql](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_virtual_network.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_virtual_network_peering.peered_vnet_app_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |
| [terraform_data.function_app_package_sha](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [archive_file.azure_function](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [azapi_resource_action.existing_logic_app_workflow_callback_url](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource_action) | data source |
| [azurerm_application_gateway.existing_agw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/application_gateway) | data source |
| [azurerm_container_app_environment.existing_container_app_environment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/container_app_environment) | data source |
| [azurerm_key_vault.existing_key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_logic_app_workflow.existing_logic_app_workflow](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/logic_app_workflow) | data source |
| [azurerm_public_ip.existing_agw_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) | data source |
| [azurerm_resource_group.existing_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_storage_account_blob_container_sas.container_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account_blob_container_sas) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |
| [azurerm_virtual_network.existing_agw_vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |
| [azurerm_virtual_network.existing_virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_cpu_threshold_percentage"></a> [alarm\_cpu\_threshold\_percentage](#input\_alarm\_cpu\_threshold\_percentage) | Specify a number (%) which should be set as a threshold for a CPU usage monitoring alarm | `number` | `80` | no |
| <a name="input_alarm_for_delete_events"></a> [alarm\_for\_delete\_events](#input\_alarm\_for\_delete\_events) | Should Alert Rules be created for Administrative 'Delete' actions? | `bool` | `true` | no |
| <a name="input_alarm_latency_threshold_ms"></a> [alarm\_latency\_threshold\_ms](#input\_alarm\_latency\_threshold\_ms) | Specify a number in milliseconds which should be set as a threshold for a request latency monitoring alarm | `number` | `1000` | no |
| <a name="input_alarm_log_ingestion_gb_per_day"></a> [alarm\_log\_ingestion\_gb\_per\_day](#input\_alarm\_log\_ingestion\_gb\_per\_day) | Define an alarm threshold for Log Analytics ingestion rate in GB (per day) (Defaults to no limit) | `number` | `0` | no |
| <a name="input_alarm_memory_threshold_percentage"></a> [alarm\_memory\_threshold\_percentage](#input\_alarm\_memory\_threshold\_percentage) | Specify a number (%) which should be set as a threshold for a memory usage monitoring alarm | `number` | `80` | no |
| <a name="input_app_configuration_assign_role"></a> [app\_configuration\_assign\_role](#input\_app\_configuration\_assign\_role) | Assign the 'App Configuration Data Reader' Role to the Container App User-Assigned Managed Identity. Note: If you do not have 'Microsoft.Authorization/roleAssignments/write' permission, you will need to manually assign the 'App Configuration Data Reader' Role to the identity | `bool` | `false` | no |
| <a name="input_app_configuration_sku"></a> [app\_configuration\_sku](#input\_app\_configuration\_sku) | The SKU name of the App Configuration. Possible values are free and standard. Defaults to free. | `string` | `"free"` | no |
| <a name="input_app_configuration_subnet_cidr"></a> [app\_configuration\_subnet\_cidr](#input\_app\_configuration\_subnet\_cidr) | Specify a subnet prefix to use for the app\_configuration subnet | `string` | `""` | no |
| <a name="input_app_insights_retention_days"></a> [app\_insights\_retention\_days](#input\_app\_insights\_retention\_days) | Number of days to retain App Insights data for (Default: 2 years) | `number` | `730` | no |
| <a name="input_app_insights_smart_detection_enabled"></a> [app\_insights\_smart\_detection\_enabled](#input\_app\_insights\_smart\_detection\_enabled) | Enable or Disable Smart Detection with App Insights | `bool` | `true` | no |
| <a name="input_azure_location"></a> [azure\_location](#input\_azure\_location) | Azure location in which to launch resources. | `string` | n/a | yes |
| <a name="input_cdn_frontdoor_custom_domains"></a> [cdn\_frontdoor\_custom\_domains](#input\_cdn\_frontdoor\_custom\_domains) | Azure CDN Front Door custom domains | `list(string)` | `[]` | no |
| <a name="input_cdn_frontdoor_custom_domains_create_dns_records"></a> [cdn\_frontdoor\_custom\_domains\_create\_dns\_records](#input\_cdn\_frontdoor\_custom\_domains\_create\_dns\_records) | Should the TXT records and ALIAS/CNAME records be automatically created if the custom domains exist within the DNS Zone? | `bool` | `true` | no |
| <a name="input_cdn_frontdoor_enable_access_logs"></a> [cdn\_frontdoor\_enable\_access\_logs](#input\_cdn\_frontdoor\_enable\_access\_logs) | Toggle the Diagnostic Setting to log Access requests | `bool` | `false` | no |
| <a name="input_cdn_frontdoor_enable_health_probe_logs"></a> [cdn\_frontdoor\_enable\_health\_probe\_logs](#input\_cdn\_frontdoor\_enable\_health\_probe\_logs) | Toggle the Diagnostic Setting to log Health Probe requests | `bool` | `false` | no |
| <a name="input_cdn_frontdoor_enable_rate_limiting"></a> [cdn\_frontdoor\_enable\_rate\_limiting](#input\_cdn\_frontdoor\_enable\_rate\_limiting) | Enable CDN Front Door Rate Limiting. This will create a WAF policy, and CDN security policy. For pricing reasons, there will only be one WAF policy created. | `bool` | `false` | no |
| <a name="input_cdn_frontdoor_enable_waf_logs"></a> [cdn\_frontdoor\_enable\_waf\_logs](#input\_cdn\_frontdoor\_enable\_waf\_logs) | Toggle the Diagnostic Setting to log Web Application Firewall requests | `bool` | `true` | no |
| <a name="input_cdn_frontdoor_forwarding_protocol"></a> [cdn\_frontdoor\_forwarding\_protocol](#input\_cdn\_frontdoor\_forwarding\_protocol) | Azure CDN Front Door forwarding protocol | `string` | `"HttpsOnly"` | no |
| <a name="input_cdn_frontdoor_health_probe_interval"></a> [cdn\_frontdoor\_health\_probe\_interval](#input\_cdn\_frontdoor\_health\_probe\_interval) | Specifies the number of seconds between health probes. | `number` | `120` | no |
| <a name="input_cdn_frontdoor_health_probe_path"></a> [cdn\_frontdoor\_health\_probe\_path](#input\_cdn\_frontdoor\_health\_probe\_path) | Specifies the path relative to the origin that is used to determine the health of the origin. | `string` | `"/"` | no |
| <a name="input_cdn_frontdoor_health_probe_protocol"></a> [cdn\_frontdoor\_health\_probe\_protocol](#input\_cdn\_frontdoor\_health\_probe\_protocol) | Use Http or Https | `string` | `"Https"` | no |
| <a name="input_cdn_frontdoor_health_probe_request_type"></a> [cdn\_frontdoor\_health\_probe\_request\_type](#input\_cdn\_frontdoor\_health\_probe\_request\_type) | Specifies the type of health probe request that is made. | `string` | `"GET"` | no |
| <a name="input_cdn_frontdoor_host_add_response_headers"></a> [cdn\_frontdoor\_host\_add\_response\_headers](#input\_cdn\_frontdoor\_host\_add\_response\_headers) | List of response headers to add at the CDN Front Door `[{ "Name" = "Strict-Transport-Security", "value" = "max-age=31536000" }]` | `list(map(string))` | `[]` | no |
| <a name="input_cdn_frontdoor_host_redirects"></a> [cdn\_frontdoor\_host\_redirects](#input\_cdn\_frontdoor\_host\_redirects) | CDN FrontDoor host redirects `[{ "from" = "example.com", "to" = "www.example.com" }]` | `list(map(string))` | `[]` | no |
| <a name="input_cdn_frontdoor_origin_fqdn_override"></a> [cdn\_frontdoor\_origin\_fqdn\_override](#input\_cdn\_frontdoor\_origin\_fqdn\_override) | Manually specify the hostname that the CDN Front Door should target. Defaults to the Container App FQDN | `string` | `""` | no |
| <a name="input_cdn_frontdoor_origin_host_header_override"></a> [cdn\_frontdoor\_origin\_host\_header\_override](#input\_cdn\_frontdoor\_origin\_host\_header\_override) | Manually specify the host header that the CDN sends to the target. Defaults to the recieved host header. Set to null to set it to the host\_name (`cdn_frontdoor_origin_fqdn_override`) | `string` | `""` | no |
| <a name="input_cdn_frontdoor_origin_http_port"></a> [cdn\_frontdoor\_origin\_http\_port](#input\_cdn\_frontdoor\_origin\_http\_port) | The value of the HTTP port used for the CDN Origin. Must be between 1 and 65535. Defaults to 80 | `number` | `80` | no |
| <a name="input_cdn_frontdoor_origin_https_port"></a> [cdn\_frontdoor\_origin\_https\_port](#input\_cdn\_frontdoor\_origin\_https\_port) | The value of the HTTPS port used for the CDN Origin. Must be between 1 and 65535. Defaults to 443 | `number` | `443` | no |
| <a name="input_cdn_frontdoor_rate_limiting_bypass_ip_list"></a> [cdn\_frontdoor\_rate\_limiting\_bypass\_ip\_list](#input\_cdn\_frontdoor\_rate\_limiting\_bypass\_ip\_list) | List if IP CIDRs to bypass CDN Front Door rate limiting | `list(string)` | `[]` | no |
| <a name="input_cdn_frontdoor_rate_limiting_duration_in_minutes"></a> [cdn\_frontdoor\_rate\_limiting\_duration\_in\_minutes](#input\_cdn\_frontdoor\_rate\_limiting\_duration\_in\_minutes) | CDN Front Door rate limiting duration in minutes | `number` | `1` | no |
| <a name="input_cdn_frontdoor_rate_limiting_threshold"></a> [cdn\_frontdoor\_rate\_limiting\_threshold](#input\_cdn\_frontdoor\_rate\_limiting\_threshold) | Maximum number of concurrent requests before Rate Limiting policy is applied | `number` | `300` | no |
| <a name="input_cdn_frontdoor_remove_response_headers"></a> [cdn\_frontdoor\_remove\_response\_headers](#input\_cdn\_frontdoor\_remove\_response\_headers) | List of response headers to remove at the CDN Front Door | `list(string)` | `[]` | no |
| <a name="input_cdn_frontdoor_response_timeout"></a> [cdn\_frontdoor\_response\_timeout](#input\_cdn\_frontdoor\_response\_timeout) | Azure CDN Front Door response timeout in seconds | `number` | `120` | no |
| <a name="input_cdn_frontdoor_sku"></a> [cdn\_frontdoor\_sku](#input\_cdn\_frontdoor\_sku) | Azure CDN Front Door SKU | `string` | `"Standard_AzureFrontDoor"` | no |
| <a name="input_cdn_frontdoor_vdp_destination_hostname"></a> [cdn\_frontdoor\_vdp\_destination\_hostname](#input\_cdn\_frontdoor\_vdp\_destination\_hostname) | Requires 'enable\_cdn\_frontdoor\_vdp\_redirects' to be set to 'true'. Hostname to redirect security.txt and thanks.txt to | `string` | `""` | no |
| <a name="input_cdn_frontdoor_waf_custom_rules"></a> [cdn\_frontdoor\_waf\_custom\_rules](#input\_cdn\_frontdoor\_waf\_custom\_rules) | Map of all Custom rules you want to apply to the CDN WAF | <pre>map(object({<br/>    priority : number,<br/>    action : string<br/>    match_conditions : map(object({<br/>      match_variable : string,<br/>      match_values : optional(list(string), []),<br/>      operator : optional(string, "Any"),<br/>      selector : optional(string, null),<br/>      negation_condition : optional(bool, false),<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_cdn_frontdoor_waf_managed_rulesets"></a> [cdn\_frontdoor\_waf\_managed\_rulesets](#input\_cdn\_frontdoor\_waf\_managed\_rulesets) | Map of all Managed rules you want to apply to the CDN WAF, including any overrides, or exclusions | <pre>map(object({<br/>    version : string,<br/>    action : optional(string, "Block"),<br/>    exclusions : optional(map(object({<br/>      match_variable : string,<br/>      operator : string,<br/>      selector : string<br/>    })), {})<br/>    overrides : optional(map(map(object({<br/>      action : string,<br/>      enabled : optional(bool, true),<br/>      exclusions : optional(map(object({<br/>        match_variable : string,<br/>        operator : string,<br/>        selector : string<br/>      })), {})<br/>    }))), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_cdn_frontdoor_waf_mode"></a> [cdn\_frontdoor\_waf\_mode](#input\_cdn\_frontdoor\_waf\_mode) | CDN Front Door waf mode | `string` | `"Prevention"` | no |
| <a name="input_container_app_blob_storage_public_access_enabled"></a> [container\_app\_blob\_storage\_public\_access\_enabled](#input\_container\_app\_blob\_storage\_public\_access\_enabled) | Enable anonymous public read access to blobs in Azure Storage? | `bool` | `false` | no |
| <a name="input_container_app_environment_internal_load_balancer_enabled"></a> [container\_app\_environment\_internal\_load\_balancer\_enabled](#input\_container\_app\_environment\_internal\_load\_balancer\_enabled) | Should the Container Environment operate in Internal Load Balancing Mode? | `bool` | `false` | no |
| <a name="input_container_app_environment_max_host_count"></a> [container\_app\_environment\_max\_host\_count](#input\_container\_app\_environment\_max\_host\_count) | The maximum number of hosts in the Container App environment cluster. Not applicable if using Consumption profile type | `number` | `1` | no |
| <a name="input_container_app_environment_min_host_count"></a> [container\_app\_environment\_min\_host\_count](#input\_container\_app\_environment\_min\_host\_count) | The minimum number of hosts in the Container App environment cluster. Not applicable if using Consumption profile type | `number` | `1` | no |
| <a name="input_container_app_environment_workload_profile_type"></a> [container\_app\_environment\_workload\_profile\_type](#input\_container\_app\_environment\_workload\_profile\_type) | Specify the type of workflow profile this Container App environment requires. Defaults to PAYG (Consumption) | `string` | `"Consumption"` | no |
| <a name="input_container_app_file_share_mount_path"></a> [container\_app\_file\_share\_mount\_path](#input\_container\_app\_file\_share\_mount\_path) | A path inside your container where the File Share will be mounted to | `string` | `"/srv/app/storage"` | no |
| <a name="input_container_app_file_share_security_profile"></a> [container\_app\_file\_share\_security\_profile](#input\_container\_app\_file\_share\_security\_profile) | Choose whether the SMB protocol should be configured for maximum security, or maximum compatibility | `string` | `"security"` | no |
| <a name="input_container_app_identities"></a> [container\_app\_identities](#input\_container\_app\_identities) | Additional User Assigned Managed Identity Resource IDs to attach to the Container App | `list(string)` | `[]` | no |
| <a name="input_container_app_name_override"></a> [container\_app\_name\_override](#input\_container\_app\_name\_override) | A custom name for the Container App | `string` | `""` | no |
| <a name="input_container_app_storage_account_shared_access_key_enabled"></a> [container\_app\_storage\_account\_shared\_access\_key\_enabled](#input\_container\_app\_storage\_account\_shared\_access\_key\_enabled) | Should the storage account for the container app permit requests to be authorized with the account access key via Shared Key? | `bool` | `true` | no |
| <a name="input_container_app_storage_cross_tenant_replication_enabled"></a> [container\_app\_storage\_cross\_tenant\_replication\_enabled](#input\_container\_app\_storage\_cross\_tenant\_replication\_enabled) | Should cross Tenant replication be enabled? | `bool` | `false` | no |
| <a name="input_container_app_use_managed_identity"></a> [container\_app\_use\_managed\_identity](#input\_container\_app\_use\_managed\_identity) | Deploy a User Assigned Managed Identity and attach it to the Container App | `bool` | `true` | no |
| <a name="input_container_apps_allow_agw_resource"></a> [container\_apps\_allow\_agw\_resource](#input\_container\_apps\_allow\_agw\_resource) | Resource name and resource group of your App Gateway V2 resource | <pre>object({<br/>    name                = string<br/>    resource_group_name = string<br/>    vnet_name           = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "name": "",<br/>  "resource_group_name": "",<br/>  "vnet_name": ""<br/>}</pre> | no |
| <a name="input_container_apps_allow_ips_inbound"></a> [container\_apps\_allow\_ips\_inbound](#input\_container\_apps\_allow\_ips\_inbound) | Restricts access to the Container Apps by creating a network security group rule that only allow inbound traffic from the provided list of IPs | `list(string)` | `[]` | no |
| <a name="input_container_apps_infra_subnet_cidr"></a> [container\_apps\_infra\_subnet\_cidr](#input\_container\_apps\_infra\_subnet\_cidr) | Specify a subnet prefix to use for the container\_apps\_infra subnet | `string` | `""` | no |
| <a name="input_container_apps_infra_subnet_service_endpoints"></a> [container\_apps\_infra\_subnet\_service\_endpoints](#input\_container\_apps\_infra\_subnet\_service\_endpoints) | Endpoints to assign to infra subnet | `list(string)` | `[]` | no |
| <a name="input_container_command"></a> [container\_command](#input\_container\_command) | Container command | `list(any)` | `[]` | no |
| <a name="input_container_cpu"></a> [container\_cpu](#input\_container\_cpu) | Number of container CPU cores | `number` | `1` | no |
| <a name="input_container_environment_variables"></a> [container\_environment\_variables](#input\_container\_environment\_variables) | Container environment variables | `map(string)` | `{}` | no |
| <a name="input_container_health_probe_interval"></a> [container\_health\_probe\_interval](#input\_container\_health\_probe\_interval) | How often in seconds to poll the Container to determine liveness | `number` | `30` | no |
| <a name="input_container_health_probe_path"></a> [container\_health\_probe\_path](#input\_container\_health\_probe\_path) | Specifies the path that is used to determine the liveness of the Container | `string` | `"/"` | no |
| <a name="input_container_health_probe_protocol"></a> [container\_health\_probe\_protocol](#input\_container\_health\_probe\_protocol) | Use HTTPS or a TCP connection for the Container liveness probe | `string` | `"http"` | no |
| <a name="input_container_max_replicas"></a> [container\_max\_replicas](#input\_container\_max\_replicas) | Container max replicas | `number` | `2` | no |
| <a name="input_container_memory"></a> [container\_memory](#input\_container\_memory) | Container memory in GB | `number` | `2` | no |
| <a name="input_container_min_replicas"></a> [container\_min\_replicas](#input\_container\_min\_replicas) | Container min replicas | `number` | `1` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | Container port | `number` | `80` | no |
| <a name="input_container_scale_http_concurrency"></a> [container\_scale\_http\_concurrency](#input\_container\_scale\_http\_concurrency) | When the number of concurrent HTTP requests exceeds this value, then another replica is added. Replicas continue to add to the pool up to the max-replicas amount. | `number` | `10` | no |
| <a name="input_container_scale_out_at_defined_time"></a> [container\_scale\_out\_at\_defined\_time](#input\_container\_scale\_out\_at\_defined\_time) | Should the Container App scale out to the max-replicas during a specified time window? | `bool` | `false` | no |
| <a name="input_container_scale_out_rule_end"></a> [container\_scale\_out\_rule\_end](#input\_container\_scale\_out\_rule\_end) | Specify a time using Linux cron format that represents the end of the scale-out window. Defaults to 18:00 | `string` | `"0 18 * * *"` | no |
| <a name="input_container_scale_out_rule_start"></a> [container\_scale\_out\_rule\_start](#input\_container\_scale\_out\_rule\_start) | Specify a time using Linux cron format that represents the start of the scale-out window. Defaults to 08:00 | `string` | `"0 8 * * *"` | no |
| <a name="input_container_secret_environment_variables"></a> [container\_secret\_environment\_variables](#input\_container\_secret\_environment\_variables) | Container environment variables, which are defined as `secrets` within the container app configuration. This is to help reduce the risk of accidentally exposing secrets. | `map(string)` | `{}` | no |
| <a name="input_create_container_app_blob_storage_sas"></a> [create\_container\_app\_blob\_storage\_sas](#input\_create\_container\_app\_blob\_storage\_sas) | Generate a SAS connection string that is exposed to your App as an environment variable so that it can connect to the Storage Account | `bool` | `true` | no |
| <a name="input_custom_container_apps"></a> [custom\_container\_apps](#input\_custom\_container\_apps) | Custom container apps, by default deployed within the container app environment managed by this module. | <pre>map(object({<br/>    container_app_environment_id = optional(string, "")<br/>    resource_group_name          = optional(string, "")<br/>    revision_mode                = optional(string, "Single")<br/>    container_port               = optional(number, 0)<br/>    ingress = optional(object({<br/>      external_enabled = optional(bool, true)<br/>      target_port      = optional(number, null)<br/>      traffic_weight = object({<br/>        percentage = optional(number, 100)<br/>      })<br/>      cdn_frontdoor_custom_domain                = optional(string, "")<br/>      cdn_frontdoor_origin_fqdn_override         = optional(string, "")<br/>      cdn_frontdoor_origin_host_header_override  = optional(string, "")<br/>      enable_cdn_frontdoor_health_probe          = optional(bool, false)<br/>      cdn_frontdoor_health_probe_protocol        = optional(string, "")<br/>      cdn_frontdoor_health_probe_interval        = optional(number, 120)<br/>      cdn_frontdoor_health_probe_request_type    = optional(string, "")<br/>      cdn_frontdoor_health_probe_path            = optional(string, "")<br/>      cdn_frontdoor_forwarding_protocol_override = optional(string, "")<br/>    }), null)<br/>    identity = optional(list(object({<br/>      type         = string<br/>      identity_ids = list(string)<br/>    })), [])<br/>    secrets = optional(list(object({<br/>      name  = string<br/>      value = string<br/>    })), [])<br/>    registry = optional(object({<br/>      server               = optional(string, "")<br/>      username             = optional(string, "")<br/>      password_secret_name = optional(string, "")<br/>      identity             = optional(string, "")<br/>    }), null),<br/>    image   = string<br/>    cpu     = number<br/>    memory  = number<br/>    command = list(string)<br/>    liveness_probes = optional(list(object({<br/>      interval_seconds = number<br/>      transport        = string<br/>      port             = number<br/>      path             = optional(string, null)<br/>    })), [])<br/>    env = optional(list(object({<br/>      name      = string<br/>      value     = optional(string, null)<br/>      secretRef = optional(string, null)<br/>    })), [])<br/>    min_replicas = number<br/>    max_replicas = number<br/>  }))</pre> | `{}` | no |
| <a name="input_dns_a_records"></a> [dns\_a\_records](#input\_dns\_a\_records) | DNS A records to add to the DNS Zone | <pre>map(<br/>    object({<br/>      ttl : optional(number, 300),<br/>      records : list(string)<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_dns_aaaa_records"></a> [dns\_aaaa\_records](#input\_dns\_aaaa\_records) | DNS AAAA records to add to the DNS Zone | <pre>map(<br/>    object({<br/>      ttl : optional(number, 300),<br/>      records : list(string)<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_dns_alias_records"></a> [dns\_alias\_records](#input\_dns\_alias\_records) | DNS ALIAS records to add to the DNS Zone | <pre>map(<br/>    object({<br/>      ttl : optional(number, 300),<br/>      target_resource_id : string<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_dns_caa_records"></a> [dns\_caa\_records](#input\_dns\_caa\_records) | DNS CAA records to add to the DNS Zone | <pre>map(<br/>    object({<br/>      ttl : optional(number, 300),<br/>      records : list(<br/>        object({<br/>          flags : number,<br/>          tag : string,<br/>          value : string<br/>        })<br/>      )<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_dns_cname_records"></a> [dns\_cname\_records](#input\_dns\_cname\_records) | DNS CNAME records to add to the DNS Zone | <pre>map(<br/>    object({<br/>      ttl : optional(number, 300),<br/>      record : string<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_dns_mx_records"></a> [dns\_mx\_records](#input\_dns\_mx\_records) | DNS MX records to add to the DNS Zone | <pre>map(<br/>    object({<br/>      ttl : optional(number, 300),<br/>      records : list(<br/>        object({<br/>          preference : number,<br/>          exchange : string<br/>        })<br/>      )<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_dns_ns_records"></a> [dns\_ns\_records](#input\_dns\_ns\_records) | DNS NS records to add to the DNS Zone | <pre>map(<br/>    object({<br/>      ttl : optional(number, 300),<br/>      records : list(string)<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_dns_ptr_records"></a> [dns\_ptr\_records](#input\_dns\_ptr\_records) | DNS PTR records to add to the DNS Zone | <pre>map(<br/>    object({<br/>      ttl : optional(number, 300),<br/>      records : list(string)<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_dns_srv_records"></a> [dns\_srv\_records](#input\_dns\_srv\_records) | DNS SRV records to add to the DNS Zone | <pre>map(<br/>    object({<br/>      ttl : optional(number, 300),<br/>      records : list(<br/>        object({<br/>          priority : number,<br/>          weight : number,<br/>          port : number,<br/>          target : string<br/>        })<br/>      )<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_dns_txt_records"></a> [dns\_txt\_records](#input\_dns\_txt\_records) | DNS TXT records to add to the DNS Zone | <pre>map(<br/>    object({<br/>      ttl : optional(number, 300),<br/>      records : list(string)<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_dns_zone_domain_name"></a> [dns\_zone\_domain\_name](#input\_dns\_zone\_domain\_name) | DNS zone domain name. If created, records will automatically be created to point to the CDN. | `string` | `""` | no |
| <a name="input_dns_zone_soa_record"></a> [dns\_zone\_soa\_record](#input\_dns\_zone\_soa\_record) | DNS zone SOA record block (https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_zone#soa_record) | `map(string)` | `{}` | no |
| <a name="input_enable_app_configuration"></a> [enable\_app\_configuration](#input\_enable\_app\_configuration) | Deploy an Azure App Configuration resource | `bool` | `false` | no |
| <a name="input_enable_app_insights_integration"></a> [enable\_app\_insights\_integration](#input\_enable\_app\_insights\_integration) | Deploy an App Insights instance and connect your Container Apps to it | `bool` | `true` | no |
| <a name="input_enable_cdn_frontdoor"></a> [enable\_cdn\_frontdoor](#input\_enable\_cdn\_frontdoor) | Enable Azure CDN Front Door. This will use the Container Apps endpoint as the origin. | `bool` | `false` | no |
| <a name="input_enable_cdn_frontdoor_health_probe"></a> [enable\_cdn\_frontdoor\_health\_probe](#input\_enable\_cdn\_frontdoor\_health\_probe) | Enable CDN Front Door health probe | `bool` | `true` | no |
| <a name="input_enable_cdn_frontdoor_vdp_redirects"></a> [enable\_cdn\_frontdoor\_vdp\_redirects](#input\_enable\_cdn\_frontdoor\_vdp\_redirects) | Deploy redirects for security.txt and thanks.txt to an external Vulnerability Disclosure Program service | `bool` | `false` | no |
| <a name="input_enable_container_app_blob_storage"></a> [enable\_container\_app\_blob\_storage](#input\_enable\_container\_app\_blob\_storage) | Create an Azure Storage Account and Storage Container to be used for this app | `bool` | `false` | no |
| <a name="input_enable_container_app_file_share"></a> [enable\_container\_app\_file\_share](#input\_enable\_container\_app\_file\_share) | Create an Azure Storage Account and File Share to be mounted to the Container Apps | `bool` | `false` | no |
| <a name="input_enable_container_health_probe"></a> [enable\_container\_health\_probe](#input\_enable\_container\_health\_probe) | Enable liveness probes for the Container | `bool` | `true` | no |
| <a name="input_enable_container_registry"></a> [enable\_container\_registry](#input\_enable\_container\_registry) | Set to true to create a container registry | `bool` | n/a | yes |
| <a name="input_enable_dns_zone"></a> [enable\_dns\_zone](#input\_enable\_dns\_zone) | Conditionally create a DNS zone | `bool` | `false` | no |
| <a name="input_enable_event_hub"></a> [enable\_event\_hub](#input\_enable\_event\_hub) | Send Azure Container App logs to an Event Hub sink | `bool` | `false` | no |
| <a name="input_enable_health_insights_api"></a> [enable\_health\_insights\_api](#input\_enable\_health\_insights\_api) | Deploys a Function App that exposes the last 3 HTTP Web Tests via an API endpoint. 'enable\_app\_insights\_integration' and 'enable\_monitoring' must be set to 'true'. | `bool` | `false` | no |
| <a name="input_enable_init_container"></a> [enable\_init\_container](#input\_enable\_init\_container) | Deploy an Init Container. Init containers run before the primary app container and are used to perform initialization tasks such as downloading data or preparing the environment | `bool` | `false` | no |
| <a name="input_enable_logstash_consumer"></a> [enable\_logstash\_consumer](#input\_enable\_logstash\_consumer) | Create an Event Hub consumer group for Logstash | `bool` | `false` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Create an App Insights instance and notification group for the Container App | `bool` | `false` | no |
| <a name="input_enable_monitoring_traces"></a> [enable\_monitoring\_traces](#input\_enable\_monitoring\_traces) | Monitor App Insights traces for error messages | `bool` | `false` | no |
| <a name="input_enable_monitoring_traces_include_warnings"></a> [enable\_monitoring\_traces\_include\_warnings](#input\_enable\_monitoring\_traces\_include\_warnings) | Extend the App Insights trace monitor to include warning messages (warning: could be noisy!) | `bool` | `false` | no |
| <a name="input_enable_mssql_database"></a> [enable\_mssql\_database](#input\_enable\_mssql\_database) | Set to true to create an Azure SQL server/database, with a private endpoint within the virtual network | `bool` | `false` | no |
| <a name="input_enable_mssql_vulnerability_assessment"></a> [enable\_mssql\_vulnerability\_assessment](#input\_enable\_mssql\_vulnerability\_assessment) | Vulnerability assessment can discover, track, and help you remediate potential database vulnerabilities | `bool` | `true` | no |
| <a name="input_enable_network_watcher"></a> [enable\_network\_watcher](#input\_enable\_network\_watcher) | Enable network watcher. Note: only 1 network watcher per subscription can be created. | `bool` | `false` | no |
| <a name="input_enable_network_watcher_traffic_analytics"></a> [enable\_network\_watcher\_traffic\_analytics](#input\_enable\_network\_watcher\_traffic\_analytics) | Enable network watcher traffic analytics (Requires `enable_network_watcher` to be true) | `bool` | `true` | no |
| <a name="input_enable_postgresql_database"></a> [enable\_postgresql\_database](#input\_enable\_postgresql\_database) | Set to true to create an Azure Postgres server/database, with a private endpoint within the virtual network | `bool` | `false` | no |
| <a name="input_enable_redis_cache"></a> [enable\_redis\_cache](#input\_enable\_redis\_cache) | Set to true to create an Azure Redis Cache, with a private endpoint within the virtual network | `bool` | `false` | no |
| <a name="input_enable_registry_retention_policy"></a> [enable\_registry\_retention\_policy](#input\_enable\_registry\_retention\_policy) | Boolean value that indicates whether the policy is enabled | `bool` | `false` | no |
| <a name="input_enable_resource_group_lock"></a> [enable\_resource\_group\_lock](#input\_enable\_resource\_group\_lock) | Enabling this will add a Resource Lock to the Resource Group preventing any resources from being deleted. | `bool` | `false` | no |
| <a name="input_enable_worker_container"></a> [enable\_worker\_container](#input\_enable\_worker\_container) | Conditionally launch a worker container. This container uses the same image and environment variables as the default container app, but allows a different container command to be run. The worker container does not expose any ports. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name. Will be used along with `project_name` as a prefix for all resources. | `string` | n/a | yes |
| <a name="input_escrow_container_app_secrets_in_key_vault"></a> [escrow\_container\_app\_secrets\_in\_key\_vault](#input\_escrow\_container\_app\_secrets\_in\_key\_vault) | Set sensitive Container App secrets in Key Vault | `bool` | `false` | no |
| <a name="input_eventhub_export_log_analytics_table_names"></a> [eventhub\_export\_log\_analytics\_table\_names](#input\_eventhub\_export\_log\_analytics\_table\_names) | List of Log Analytics table names that you want to export to Event Hub. See https://learn.microsoft.com/en-gb/azure/azure-monitor/logs/logs-data-export?tabs=portal#supported-tables for a list of supported tables | `list(string)` | `[]` | no |
| <a name="input_existing_container_app_environment"></a> [existing\_container\_app\_environment](#input\_existing\_container\_app\_environment) | Conditionally launch resources into an existing Container App environment. Specifying this will NOT create an environment. | <pre>object({<br/>    name           = string<br/>    resource_group = string<br/>  })</pre> | <pre>{<br/>  "name": "",<br/>  "resource_group": ""<br/>}</pre> | no |
| <a name="input_existing_key_vault"></a> [existing\_key\_vault](#input\_existing\_key\_vault) | An existing Key Vault that you want to store Container App secrets in | `string` | `""` | no |
| <a name="input_existing_logic_app_workflow"></a> [existing\_logic\_app\_workflow](#input\_existing\_logic\_app\_workflow) | Name, Resource Group and HTTP Trigger URL of an existing Logic App Workflow to route Alerts to | <pre>object({<br/>    name : string<br/>    resource_group_name : string<br/>  })</pre> | <pre>{<br/>  "name": "",<br/>  "resource_group_name": ""<br/>}</pre> | no |
| <a name="input_existing_network_watcher_name"></a> [existing\_network\_watcher\_name](#input\_existing\_network\_watcher\_name) | Use an existing network watcher to add flow logs. | `string` | `""` | no |
| <a name="input_existing_network_watcher_resource_group_name"></a> [existing\_network\_watcher\_resource\_group\_name](#input\_existing\_network\_watcher\_resource\_group\_name) | Existing network watcher resource group. | `string` | `""` | no |
| <a name="input_existing_resource_group"></a> [existing\_resource\_group](#input\_existing\_resource\_group) | Conditionally launch resources into an existing resource group. Specifying this will NOT create a resource group. | `string` | `""` | no |
| <a name="input_existing_virtual_network"></a> [existing\_virtual\_network](#input\_existing\_virtual\_network) | Conditionally use an existing virtual network. The `virtual_network_address_space` must match an existing address space in the VNet. This also requires the resource group name. | `string` | `""` | no |
| <a name="input_health_insights_api_cors_origins"></a> [health\_insights\_api\_cors\_origins](#input\_health\_insights\_api\_cors\_origins) | List of hostnames that are permitted to contact the Health insights API | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_health_insights_api_ipv4_allow_list"></a> [health\_insights\_api\_ipv4\_allow\_list](#input\_health\_insights\_api\_ipv4\_allow\_list) | List of IPv4 addresses that are permitted to contact the Health insights API | `list(string)` | `[]` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Image name | `string` | n/a | yes |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Image tag | `string` | `"latest"` | no |
| <a name="input_init_container_command"></a> [init\_container\_command](#input\_init\_container\_command) | Container command for the Init Container | `list(any)` | `[]` | no |
| <a name="input_init_container_image"></a> [init\_container\_image](#input\_init\_container\_image) | Image name for the Init Container. Leave blank to use the same Container image from the primary app | `string` | `""` | no |
| <a name="input_key_vault_access_ipv4"></a> [key\_vault\_access\_ipv4](#input\_key\_vault\_access\_ipv4) | List of IPv4 Addresses that are permitted to access the Key Vault | `list(string)` | `[]` | no |
| <a name="input_key_vault_managed_identity_assign_role"></a> [key\_vault\_managed\_identity\_assign\_role](#input\_key\_vault\_managed\_identity\_assign\_role) | Assign the Key Vault Secret User role to the Container App managed identity | `bool` | `false` | no |
| <a name="input_launch_in_vnet"></a> [launch\_in\_vnet](#input\_launch\_in\_vnet) | Conditionally launch into a VNet | `bool` | `true` | no |
| <a name="input_linux_function_apps"></a> [linux\_function\_apps](#input\_linux\_function\_apps) | A list of Linux Function Apps with their corresponding app settings | <pre>map(object({<br/>    runtime                                        = string<br/>    runtime_version                                = string<br/>    app_settings                                   = optional(map(string), {})<br/>    allowed_origins                                = optional(list(string), ["*"])<br/>    ftp_publish_basic_authentication_enabled       = optional(bool, false)<br/>    webdeploy_publish_basic_authentication_enabled = optional(bool, false)<br/>    ipv4_access                                    = optional(list(string), [])<br/>    minimum_tls_version                            = optional(string, "1.3")<br/>  }))</pre> | `{}` | no |
| <a name="input_monitor_email_receivers"></a> [monitor\_email\_receivers](#input\_monitor\_email\_receivers) | A list of email addresses that should be notified by monitoring alerts | `list(string)` | `[]` | no |
| <a name="input_monitor_endpoint_healthcheck"></a> [monitor\_endpoint\_healthcheck](#input\_monitor\_endpoint\_healthcheck) | Specify a route that should be monitored for a 200 OK status | `string` | `"/"` | no |
| <a name="input_monitor_http_availability_fqdn"></a> [monitor\_http\_availability\_fqdn](#input\_monitor\_http\_availability\_fqdn) | Specify a FQDN to monitor for HTTP Availability. Leave unset to dynamically calculate the correct FQDN | `string` | `""` | no |
| <a name="input_monitor_http_availability_verb"></a> [monitor\_http\_availability\_verb](#input\_monitor\_http\_availability\_verb) | Which HTTP verb to use for the HTTP Availability check | `string` | `"HEAD"` | no |
| <a name="input_mssql_azuread_admin_object_id"></a> [mssql\_azuread\_admin\_object\_id](#input\_mssql\_azuread\_admin\_object\_id) | Object ID of a User within Azure AD that you want to assign as the SQL Server Administrator | `string` | `""` | no |
| <a name="input_mssql_azuread_admin_username"></a> [mssql\_azuread\_admin\_username](#input\_mssql\_azuread\_admin\_username) | Username of a User within Azure AD that you want to assign as the SQL Server Administrator | `string` | `""` | no |
| <a name="input_mssql_azuread_auth_only"></a> [mssql\_azuread\_auth\_only](#input\_mssql\_azuread\_auth\_only) | Set to true to only permit SQL logins from Azure AD users | `bool` | `false` | no |
| <a name="input_mssql_database_name"></a> [mssql\_database\_name](#input\_mssql\_database\_name) | The name of the MSSQL database to create. Must be set if `enable_mssql_database` is true | `string` | `""` | no |
| <a name="input_mssql_firewall_ipv4_allow_list"></a> [mssql\_firewall\_ipv4\_allow\_list](#input\_mssql\_firewall\_ipv4\_allow\_list) | A list of IPv4 Addresses that require remote access to the MSSQL Server | <pre>map(object({<br/>    start_ip_range : string,<br/>    end_ip_range : optional(string, "")<br/>  }))</pre> | `{}` | no |
| <a name="input_mssql_maintenance_configuration_name"></a> [mssql\_maintenance\_configuration\_name](#input\_mssql\_maintenance\_configuration\_name) | The name of the Public Maintenance Configuration window to apply to the SQL database | `string` | `""` | no |
| <a name="input_mssql_managed_identity_assign_role"></a> [mssql\_managed\_identity\_assign\_role](#input\_mssql\_managed\_identity\_assign\_role) | Assign the 'Storage Blob Data Contributor' Role to the SQL Server User-Assigned Managed Identity. Note: If you do not have 'Microsoft.Authorization/roleAssignments/write' permission, you will need to manually assign the 'Storage Blob Data Contributor' Role to the identity | `bool` | `true` | no |
| <a name="input_mssql_max_size_gb"></a> [mssql\_max\_size\_gb](#input\_mssql\_max\_size\_gb) | The max size of the database in gigabytes | `number` | `2` | no |
| <a name="input_mssql_private_endpoint_subnet_cidr"></a> [mssql\_private\_endpoint\_subnet\_cidr](#input\_mssql\_private\_endpoint\_subnet\_cidr) | Specify a subnet prefix to use for the mssql\_private\_endpoint subnet | `string` | `""` | no |
| <a name="input_mssql_security_storage_access_key_rotation_reminder_days"></a> [mssql\_security\_storage\_access\_key\_rotation\_reminder\_days](#input\_mssql\_security\_storage\_access\_key\_rotation\_reminder\_days) | Number of days to set for access key rotation reminder on the SQL Security Storage Account. If not set will default to 'storage\_account\_access\_key\_rotation\_reminder\_days' | `number` | `0` | no |
| <a name="input_mssql_security_storage_cross_tenant_replication_enabled"></a> [mssql\_security\_storage\_cross\_tenant\_replication\_enabled](#input\_mssql\_security\_storage\_cross\_tenant\_replication\_enabled) | Should cross Tenant replication be enabled? | `bool` | `false` | no |
| <a name="input_mssql_security_storage_firewall_ipv4_allow_list"></a> [mssql\_security\_storage\_firewall\_ipv4\_allow\_list](#input\_mssql\_security\_storage\_firewall\_ipv4\_allow\_list) | Additional IP addresses to add to the Storage Account that holds the Vulnerability Assessments | `list(string)` | `[]` | no |
| <a name="input_mssql_server_admin_password"></a> [mssql\_server\_admin\_password](#input\_mssql\_server\_admin\_password) | The local administrator password for the MSSQL server | `string` | `""` | no |
| <a name="input_mssql_server_public_access_enabled"></a> [mssql\_server\_public\_access\_enabled](#input\_mssql\_server\_public\_access\_enabled) | Enable public internet access to your MSSQL instance. Be sure to specify 'mssql\_firewall\_ipv4\_allow\_list' to restrict inbound connections | `bool` | `false` | no |
| <a name="input_mssql_sku_name"></a> [mssql\_sku\_name](#input\_mssql\_sku\_name) | Specifies the name of the SKU used by the database | `string` | `"Basic"` | no |
| <a name="input_mssql_storage_account_shared_access_key_enabled"></a> [mssql\_storage\_account\_shared\_access\_key\_enabled](#input\_mssql\_storage\_account\_shared\_access\_key\_enabled) | Should the storage account for mssql security permit requests to be authorized with the account access key via Shared Key? | `bool` | `true` | no |
| <a name="input_mssql_version"></a> [mssql\_version](#input\_mssql\_version) | Specify the version of Microsoft SQL Server you want to run | `string` | `"12.0"` | no |
| <a name="input_network_watcher_flow_log_retention"></a> [network\_watcher\_flow\_log\_retention](#input\_network\_watcher\_flow\_log\_retention) | Number of days to retain flow logs. Set to 0 to keep all logs. | `number` | `90` | no |
| <a name="input_network_watcher_nsg_storage_access_key_rotation_reminder_days"></a> [network\_watcher\_nsg\_storage\_access\_key\_rotation\_reminder\_days](#input\_network\_watcher\_nsg\_storage\_access\_key\_rotation\_reminder\_days) | Number of days to set for access key rotation reminder on the Network Watcher NSG Flow Log Storage Account. If not set will default to 'storage\_account\_access\_key\_rotation\_reminder\_days' | `number` | `0` | no |
| <a name="input_network_watcher_traffic_analytics_interval"></a> [network\_watcher\_traffic\_analytics\_interval](#input\_network\_watcher\_traffic\_analytics\_interval) | Interval in minutes for Traffic Analytics. | `number` | `60` | no |
| <a name="input_postgresql_administrator_login"></a> [postgresql\_administrator\_login](#input\_postgresql\_administrator\_login) | Specify a login that will be assigned to the administrator when creating the Postgres server | `string` | `""` | no |
| <a name="input_postgresql_administrator_password"></a> [postgresql\_administrator\_password](#input\_postgresql\_administrator\_password) | Specify a password that will be assigned to the administrator when creating the Postgres server | `string` | `""` | no |
| <a name="input_postgresql_availability_zone"></a> [postgresql\_availability\_zone](#input\_postgresql\_availability\_zone) | Specify the availibility zone in which the Postgres server should be located | `string` | `"1"` | no |
| <a name="input_postgresql_charset"></a> [postgresql\_charset](#input\_postgresql\_charset) | Specify the charset to be used for the Postgres database | `string` | `"utf8"` | no |
| <a name="input_postgresql_collation"></a> [postgresql\_collation](#input\_postgresql\_collation) | Specify the collation to be used for the Postgres database | `string` | `"en_US.utf8"` | no |
| <a name="input_postgresql_enabled_extensions"></a> [postgresql\_enabled\_extensions](#input\_postgresql\_enabled\_extensions) | Specify a comma seperated list of Postgres extensions to enable. See https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-extensions#postgres-14-extensions | `string` | `""` | no |
| <a name="input_postgresql_firewall_ipv4_allow"></a> [postgresql\_firewall\_ipv4\_allow](#input\_postgresql\_firewall\_ipv4\_allow) | Map of IP address ranges to add into the postgres firewall. Note: only applicable if postgresql\_network\_connectivity\_method is set to public. | <pre>map(object({<br/>    start_ip_address = string<br/>    end_ip_address   = string<br/>  }))</pre> | `{}` | no |
| <a name="input_postgresql_max_storage_mb"></a> [postgresql\_max\_storage\_mb](#input\_postgresql\_max\_storage\_mb) | Specify the max amount of storage allowed for the Postgres server | `number` | `32768` | no |
| <a name="input_postgresql_network_connectivity_method"></a> [postgresql\_network\_connectivity\_method](#input\_postgresql\_network\_connectivity\_method) | Specify postgresql networking method, public or private. See https://learn.microsoft.com/en-gb/azure/postgresql/flexible-server/concepts-networking | `string` | `"private"` | no |
| <a name="input_postgresql_server_version"></a> [postgresql\_server\_version](#input\_postgresql\_server\_version) | Specify the version of postgres server to run (either 11,12,13 or 14) | `string` | `""` | no |
| <a name="input_postgresql_sku_name"></a> [postgresql\_sku\_name](#input\_postgresql\_sku\_name) | Specify the SKU to be used for the Postgres server | `string` | `"B_Standard_B1ms"` | no |
| <a name="input_postgresql_subnet_cidr"></a> [postgresql\_subnet\_cidr](#input\_postgresql\_subnet\_cidr) | Specify a subnet prefix to use for the postgresql subnet | `string` | `""` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name. Will be used along with `environment` as a prefix for all resources. | `string` | n/a | yes |
| <a name="input_redis_cache_capacity"></a> [redis\_cache\_capacity](#input\_redis\_cache\_capacity) | Redis Cache Capacity | `number` | `0` | no |
| <a name="input_redis_cache_family"></a> [redis\_cache\_family](#input\_redis\_cache\_family) | Redis Cache family | `string` | `"C"` | no |
| <a name="input_redis_cache_firewall_ipv4_allow_list"></a> [redis\_cache\_firewall\_ipv4\_allow\_list](#input\_redis\_cache\_firewall\_ipv4\_allow\_list) | A list of IPv4 address that require remote access to the Redis server | `list(string)` | `[]` | no |
| <a name="input_redis_cache_patch_schedule_day"></a> [redis\_cache\_patch\_schedule\_day](#input\_redis\_cache\_patch\_schedule\_day) | Redis Cache patch schedule day | `string` | `"Sunday"` | no |
| <a name="input_redis_cache_patch_schedule_hour"></a> [redis\_cache\_patch\_schedule\_hour](#input\_redis\_cache\_patch\_schedule\_hour) | Redis Cache patch schedule hour | `number` | `18` | no |
| <a name="input_redis_cache_sku"></a> [redis\_cache\_sku](#input\_redis\_cache\_sku) | Redis Cache SKU | `string` | `"Basic"` | no |
| <a name="input_redis_cache_subnet_cidr"></a> [redis\_cache\_subnet\_cidr](#input\_redis\_cache\_subnet\_cidr) | Specify a subnet prefix to use for the redis\_cache subnet | `string` | `""` | no |
| <a name="input_redis_cache_version"></a> [redis\_cache\_version](#input\_redis\_cache\_version) | Redis Cache version | `number` | `6` | no |
| <a name="input_redis_config"></a> [redis\_config](#input\_redis\_config) | Overrides for Redis Cache Configuration options | <pre>object({<br/>    maxmemory_reserved : optional(number),<br/>    maxmemory_delta : optional(number),<br/>    maxfragmentationmemory_reserved : optional(number),<br/>    maxmemory_policy : optional(string),<br/>  })</pre> | `{}` | no |
| <a name="input_registry_admin_enabled"></a> [registry\_admin\_enabled](#input\_registry\_admin\_enabled) | Do you want to enable access key based authentication for your Container Registry? | `bool` | `true` | no |
| <a name="input_registry_ipv4_allow_list"></a> [registry\_ipv4\_allow\_list](#input\_registry\_ipv4\_allow\_list) | List of IPv4 CIDR blocks that require access to the Container Registry | `list(string)` | `[]` | no |
| <a name="input_registry_managed_identity_assign_role"></a> [registry\_managed\_identity\_assign\_role](#input\_registry\_managed\_identity\_assign\_role) | Assign the 'AcrPull' Role to the Container App User-Assigned Managed Identity. Note: If you do not have 'Microsoft.Authorization/roleAssignments/write' permission, you will need to manually assign the 'AcrPull' Role to the identity | `bool` | `true` | no |
| <a name="input_registry_password"></a> [registry\_password](#input\_registry\_password) | Container registry password (required if `enable_container_registry` is false) | `string` | `""` | no |
| <a name="input_registry_public_access_enabled"></a> [registry\_public\_access\_enabled](#input\_registry\_public\_access\_enabled) | Should your Container Registry be publicly accessible? | `bool` | `true` | no |
| <a name="input_registry_retention_days"></a> [registry\_retention\_days](#input\_registry\_retention\_days) | The number of days to retain an untagged manifest after which it gets purged | `number` | `7` | no |
| <a name="input_registry_server"></a> [registry\_server](#input\_registry\_server) | Container registry server (required if `enable_container_registry` is false) | `string` | `""` | no |
| <a name="input_registry_sku"></a> [registry\_sku](#input\_registry\_sku) | The SKU name of the container registry. Possible values are 'Basic', 'Standard' and 'Premium'. | `string` | `"Standard"` | no |
| <a name="input_registry_subnet_cidr"></a> [registry\_subnet\_cidr](#input\_registry\_subnet\_cidr) | Specify a subnet prefix to use for the registry subnet | `string` | `""` | no |
| <a name="input_registry_use_managed_identity"></a> [registry\_use\_managed\_identity](#input\_registry\_use\_managed\_identity) | Create a User-Assigned Managed Identity for the Container App. Note: If you do not have 'Microsoft.Authorization/roleAssignments/write' permission, you will need to manually assign the 'AcrPull' Role to the identity | `bool` | `false` | no |
| <a name="input_registry_username"></a> [registry\_username](#input\_registry\_username) | Container registry username (required if `enable_container_registry` is false) | `string` | `""` | no |
| <a name="input_restrict_container_apps_to_agw_inbound_only"></a> [restrict\_container\_apps\_to\_agw\_inbound\_only](#input\_restrict\_container\_apps\_to\_agw\_inbound\_only) | Restricts access to the Container Apps by creating a network security group rule that only allows a specified App Gateway inbound, and attaches it to the subnet of the container app environment. | `bool` | `false` | no |
| <a name="input_restrict_container_apps_to_cdn_inbound_only"></a> [restrict\_container\_apps\_to\_cdn\_inbound\_only](#input\_restrict\_container\_apps\_to\_cdn\_inbound\_only) | Restricts access to the Container Apps by creating a network security group rule that only allows 'AzureFrontDoor.Backend' inbound, and attaches it to the subnet of the container app environment. | `bool` | `true` | no |
| <a name="input_storage_account_access_key_rotation_reminder_days"></a> [storage\_account\_access\_key\_rotation\_reminder\_days](#input\_storage\_account\_access\_key\_rotation\_reminder\_days) | Number of days to set for access key rotation reminder on Storage Accounts | `number` | `90` | no |
| <a name="input_storage_account_file_share_quota_gb"></a> [storage\_account\_file\_share\_quota\_gb](#input\_storage\_account\_file\_share\_quota\_gb) | The maximum size of the share, in gigabytes. | `number` | `2` | no |
| <a name="input_storage_account_ipv4_allow_list"></a> [storage\_account\_ipv4\_allow\_list](#input\_storage\_account\_ipv4\_allow\_list) | A list of public IPv4 address to grant access to the Storage Account | `list(string)` | `[]` | no |
| <a name="input_storage_account_public_access_enabled"></a> [storage\_account\_public\_access\_enabled](#input\_storage\_account\_public\_access\_enabled) | Should the Azure Storage Account have Public visibility? | `bool` | `false` | no |
| <a name="input_storage_account_sas_expiration_period"></a> [storage\_account\_sas\_expiration\_period](#input\_storage\_account\_sas\_expiration\_period) | The SAS expiration period in format of DD.HH:MM:SS | `string` | `"02.00:00:00"` | no |
| <a name="input_storage_subnet_cidr"></a> [storage\_subnet\_cidr](#input\_storage\_subnet\_cidr) | Specify a subnet prefix to use for the storage subnet | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_virtual_network_address_space"></a> [virtual\_network\_address\_space](#input\_virtual\_network\_address\_space) | Virtual Network address space CIDR | `string` | `"172.16.0.0/12"` | no |
| <a name="input_virtual_network_deny_all_egress"></a> [virtual\_network\_deny\_all\_egress](#input\_virtual\_network\_deny\_all\_egress) | Should all outbound traffic across the default Virtual Network be denied? | `bool` | `false` | no |
| <a name="input_worker_container_command"></a> [worker\_container\_command](#input\_worker\_container\_command) | Container command for the Worker container. `enable_worker_container` must be set to true for this to have any effect. | `list(string)` | `[]` | no |
| <a name="input_worker_container_max_replicas"></a> [worker\_container\_max\_replicas](#input\_worker\_container\_max\_replicas) | Worker ontainer max replicas | `number` | `2` | no |
| <a name="input_worker_container_min_replicas"></a> [worker\_container\_min\_replicas](#input\_worker\_container\_min\_replicas) | Worker container min replicas | `number` | `1` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_azurerm_container_registry"></a> [azurerm\_container\_registry](#output\_azurerm\_container\_registry) | Container Registry |
| <a name="output_azurerm_dns_zone_name_servers"></a> [azurerm\_dns\_zone\_name\_servers](#output\_azurerm\_dns\_zone\_name\_servers) | Name servers of the DNS Zone |
| <a name="output_azurerm_eventhub_container_app"></a> [azurerm\_eventhub\_container\_app](#output\_azurerm\_eventhub\_container\_app) | Container App Event Hub |
| <a name="output_azurerm_log_analytics_workspace_container_app"></a> [azurerm\_log\_analytics\_workspace\_container\_app](#output\_azurerm\_log\_analytics\_workspace\_container\_app) | Container App Log Analytics Workspace |
| <a name="output_azurerm_resource_group_default"></a> [azurerm\_resource\_group\_default](#output\_azurerm\_resource\_group\_default) | Default Azure Resource Group |
| <a name="output_cdn_frontdoor_dns_records"></a> [cdn\_frontdoor\_dns\_records](#output\_cdn\_frontdoor\_dns\_records) | Azure Front Door DNS Records that must be created manually |
| <a name="output_container_app_environment_ingress_ip"></a> [container\_app\_environment\_ingress\_ip](#output\_container\_app\_environment\_ingress\_ip) | Ingress IP address assigned to the Container App environment |
| <a name="output_container_app_managed_identity"></a> [container\_app\_managed\_identity](#output\_container\_app\_managed\_identity) | User-Assigned Managed Identity assigned to the Container App |
| <a name="output_container_fqdn"></a> [container\_fqdn](#output\_container\_fqdn) | FQDN for the Container App |
| <a name="output_networking"></a> [networking](#output\_networking) | IDs for various VNet resources if created |
<!-- END_TF_DOCS -->

[1]: https://azure.microsoft.com/en-us/services/container-apps
[2]: https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview
