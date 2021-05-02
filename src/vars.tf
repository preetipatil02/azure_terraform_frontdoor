variable "azure_subscription_id" {
    type = string
    description = "subscription id for the account"
}

variable "azure_tenant_id" {
    type = string
    description = "tenant id for the account"
}
variable "azure" {
    type = map(string)
    description = "Configuration of the target Azure environment. Keys: resource_group_name, resource_name and location."
    default = {
        "resource_group_name" = "myResourceGroup"
        "resource_name" = "myAzureResource"
        "location" = "uksouth"
    }
}
variable "env_tag" {
    type = map(string)
    description = "tags for each resources"
    default = {
        "environment" = "DEV"
        "created-by" = "Terraform"
    }
}
variable "app_services" {
    type = map(string)
    description = "service names for 2 services"
    default = {
        "service1" = "myServiceA"
        "service2" = "myServiceB"
    }
}
variable "network" {
    type = string
    description = "network Name"
    default = "myNetwork"
}

variable "subnet" {
    type = string
    description = "subnet in the virtual net"
    default = "mysubnet1"
}

# variable "frontdoor_resource_group_name" {
#   description = "(Required) Resource Group name"
#   type = string
# }

variable "frontdoor_name" {
  description = "(Required) Name of the Azure Front Door to create"
  type = string
  default = "myFrontdoor"
}

variable "frontdoor_loadbalancer_enabled" {
  description = "(Required) Enable the load balancer for Azure Front Door"
  type = bool
}

variable "enforce_backend_pools_certificate_name_check" {
  description = "Enforce the certificate name check for Azure Front Door"
  type = bool
  default = false
}

variable "backend_pools_send_receive_timeout_seconds" {
  description = "Set the send/receive timeout for Azure Front Door"
  type = number
  default = 60
}

variable "tags" {
  description = "(Required) Tags for Azure Front Door"  
}

variable "frontend_endpoint" {
  description = "(Required) Frontend Endpoints for Azure Front Door"
}

variable "frontdoor_routing_rule" {
  description = "(Required) Routing rules for Azure Front Door"
}

variable "frontdoor_loadbalancer" {
  description = "(Required) Load Balancer settings for Azure Front Door"
}

variable "frontdoor_health_probe" {
  description = "(Required) Health Probe settings for Azure Front Door"
}

variable "frontdoor_backend" {
  description = "(Required) Backend settings for Azure Front Door"
}

# variable "frontdoor_config" {
#     type = object({
#         name = string
#         age = number
#         fav_food = bool
#         food = list(string)
#         hobbies = map(string)
#         enforce_backend_pools_certificate_name_check = bool
#         frontdoor_loadbalancer_enabled = bool
#     default = {
#         name = "preeti"
#         age = 3
#         fav_food = true
#         food = ["fish", "veg", "cakes"]
#         hobbies = {
#             "first" = "walking"
#             "second" = "talking"
#         }
#         enforce_backend_pools_certificate_name_check = false
#         frontdoor_loadbalancer_enabled = false
#     }
#     })
#     description = "configuration of front door"
# }