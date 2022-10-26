variable "environment" {
  description = "Environment name. Will be used along with `project_name` as a prefix for all resources."
  type        = string
}

variable "project_name" {
  description = "Project name. Will be used along with `environment` as a prefix for all resources."
  type        = string
}

variable "azure_location" {
  description = "Azure location in which to launch resources."
  type        = string
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "launch_in_vnet" {
  description = "Conditionally launch into a VNet"
  type        = bool
  default     = true
}

variable "existing_virtual_network" {
  description = "Conditionally use an existing virtual network. The `virtual_network_address_space` must match an existing address space in the VNet. This also requires the resource group name."
  type        = string
  default     = ""
}

variable "existing_resource_group" {
  description = "Conditionally launch resources into an exiting resource group. Specifying this will not reate a new resource group."
  type        = string
  default     = ""
}

variable "virtual_network_address_space" {
  description = "Virtual Network address space CIDR"
  type        = string
  default     = "172.16.0.0/12"
}

variable "enable_container_registry" {
  description = "Set to true to create a container registry"
  type        = bool
}

variable "registry_server" {
  description = "Container registry server (required if `enable_container_registry` is false)"
  type        = string
  default     = ""
}

variable "registry_username" {
  description = "Container registry username (required if `enable_container_registry` is false)"
  type        = string
  default     = ""
}

variable "registry_password" {
  description = "Container registry password (required if `enable_container_registry` is false)"
  type        = string
  default     = ""
}

variable "enable_mssql_database" {
  description = "Set to true to create an Azure SQL server/database, with a private endpoint within the virtual network"
  type        = bool
  default     = false
}

variable "mssql_server_admin_password" {
  description = "The administrator password for the MSSQL server. Must be set if `enable_mssql_database` is true"
  type        = string
  default     = ""
  sensitive   = true
}

variable "mssql_sku_name" {
  description = "Specifies the name of the SKU used by the database"
  type        = string
  default     = "Basic"
}

variable "mssql_max_size_gb" {
  description = "The max size of the database in gigabytes"
  type        = number
  default     = 2
}

variable "mssql_database_name" {
  description = "The name of the MSSQL database to create. Must be set if `enable_mssql_database` is true"
  type        = string
  default     = ""
}

variable "enable_redis_cache" {
  description = "Set to true to create an Azure Redis Cache, with a private endpoint within the virtual network"
  type        = bool
  default     = false
}

variable "redis_cache_family" {
  description = "Redis Cache family"
  type        = string
  default     = "C"
}

variable "redis_cache_sku" {
  description = "Redis Cache SKU"
  type        = string
  default     = "Basic"
}

variable "redis_cache_capacity" {
  description = "Redis Cache Capacity"
  type        = number
  default     = 0
}

variable "redis_cache_patch_schedule_day" {
  description = "Redis Cache patch schedule day"
  type        = string
  default     = "Wednesday"
}

variable "redis_cache_patch_schedule_hour" {
  description = "Redis Cache patch schedule hour"
  type        = number
  default     = 18
}

variable "image_name" {
  description = "Image name"
  type        = string
}

variable "image_tag" {
  description = "Image tag"
  type        = string
  default     = "latest"
}

variable "container_cpu" {
  description = "Number of container CPU cores"
  type        = number
  default     = 1
}

variable "container_memory" {
  description = "Container memory in GB"
  type        = number
  default     = 2
}

variable "container_min_replicas" {
  description = "Container min replicas"
  type        = number
  default     = 1
}

variable "container_max_replicas" {
  description = "Container max replicas"
  type        = number
  default     = 2
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 80
}

variable "container_command" {
  description = "Container command"
  type        = list(any)
  default     = []
}

variable "container_environment_variables" {
  description = "Container environment variables"
  type        = map(string)
  default     = {}
}

variable "container_secret_environment_variables" {
  description = "Container environment variables, which are defined as `secrets` within the container app configuration. This is to help reduce the risk of accidently exposing secrets."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "enable_worker_container" {
  description = "Conditionally launch a worker container. This container uses the same image and environment variables as a the default container app, but allows a different container commanmd to be ran. The worker container does not expose any ports."
  type        = bool
  default     = false
}

variable "worker_container_command" {
  description = "Container command for the Worker container. `enable_worker_container` must be set to true for this to have any effect."
  type        = list(string)
  default     = []
}
