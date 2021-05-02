# Create Resource group 
resource "azurerm_resource_group" "dev" {
  name     = var.azure["resource_group_name"]
  location = var.azure["location"]
  tags = var.env_tag
}

# Create App Service Plan 
resource "azurerm_app_service_plan" "dev" {
  name                = var.azure["resource_name"]
  location            = var.azure["location"]
  resource_group_name = azurerm_resource_group.dev.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

# Create App Service A
resource "azurerm_app_service" "dev_service1" {
  name                = var.app_services["service1"]
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  app_service_plan_id = azurerm_app_service_plan.dev.id

  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }
}

# Create App Service B
resource "azurerm_app_service" "dev_service2" {
  name                = var.app_services["service2"]
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  app_service_plan_id = azurerm_app_service_plan.dev.id

  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "dev" {
  name                = var.network
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  address_space       = ["10.0.0.0/16"]
}

# Create subnet
resource "azurerm_subnet" "dev" {
  name                 = var.subnet
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Attach the App Services to the vnet
resource "azurerm_app_service_virtual_network_swift_connection" "dev_app_netconnection1" {
  app_service_id = azurerm_app_service.dev_service1.id
  subnet_id      = azurerm_subnet.dev.id
}
resource "azurerm_app_service_virtual_network_swift_connection" "dev_app_netconnection2" {
  app_service_id = azurerm_app_service.dev_service1.id
  subnet_id      = azurerm_subnet.dev.id
}

# Generate randon ID for the storage name (unique)
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.dev.name
    }
    byte_length = 8
}

resource "azurerm_storage_account" "dev" {
  name                     = "dia${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.dev.name
  location                 = azurerm_resource_group.dev.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "DEV"
  }
}

# Create front door WAF policy
resource "azurerm_frontdoor_firewall_policy" "myDevwafpolicy" {
  name                              = "myDevwafpolicy"
  resource_group_name               = azurerm_resource_group.dev.name
  enabled                           = true
  mode                              = "Prevention"
  custom_block_response_status_code = 403 
  /*
  custom_block_response_body takes in is a base 64 encoded string, hence this is the base 64 encoded string for 
  "blocked by frontdoor"
  */
  custom_block_response_body        = "YmxvY2tlZCBieSBmcm9udGRvb3I="

  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
  }
}

# Create front door
resource "azurerm_frontdoor" "instance" {
  #name                                         = "diag${random_id.randomId.hex}"
  name = var.frontdoor_name
  resource_group_name                          = var.azure["resource_group_name"]
  enforce_backend_pools_certificate_name_check = var.enforce_backend_pools_certificate_name_check
  load_balancer_enabled                        = var.frontdoor_loadbalancer_enabled
  backend_pools_send_receive_timeout_seconds   = var.backend_pools_send_receive_timeout_seconds
  tags                                         = var.tags

  dynamic "backend_pool_load_balancing" {
    for_each = var.frontdoor_loadbalancer
    content {
      name                            = backend_pool_load_balancing.value.name
      sample_size                     = backend_pool_load_balancing.value.sample_size
      successful_samples_required     = backend_pool_load_balancing.value.successful_samples_required
      additional_latency_milliseconds = backend_pool_load_balancing.value.additional_latency_milliseconds
    }
  }

  dynamic "routing_rule" {
    for_each = var.frontdoor_routing_rule
    content {
        name               = routing_rule.value.name
        accepted_protocols = routing_rule.value.accepted_protocols
        patterns_to_match  = routing_rule.value.patterns_to_match
        frontend_endpoints = values({for x, endpoint in var.frontend_endpoint : x => endpoint.name})
        dynamic "forwarding_configuration" {
          for_each = routing_rule.value.configuration == "Forwarding" ? routing_rule.value.forwarding_configuration : []
          content {
            backend_pool_name                     = forwarding_configuration.value.backend_pool_name
            cache_enabled                         = forwarding_configuration.value.cache_enabled
            cache_use_dynamic_compression         = forwarding_configuration.value.cache_use_dynamic_compression #default: false
            cache_query_parameter_strip_directive = forwarding_configuration.value.cache_query_parameter_strip_directive
            custom_forwarding_path                = forwarding_configuration.value.custom_forwarding_path
            forwarding_protocol                   = forwarding_configuration.value.forwarding_protocol
          }
        }
        dynamic "redirect_configuration" {
          for_each = routing_rule.value.configuration == "Redirecting" ? routing_rule.value.redirect_configuration : []
          content {
            custom_host         = redirect_configuration.value.custom_host
            redirect_protocol   = redirect_configuration.value.redirect_protocol
            redirect_type       = redirect_configuration.value.redirect_type
            custom_fragment     = redirect_configuration.value.custom_fragment
            custom_path         = redirect_configuration.value.custom_path
            custom_query_string = redirect_configuration.value.custom_query_string
          }
        }
    }
  }

 dynamic "backend_pool_health_probe" {
    for_each = var.frontdoor_health_probe
    content {
      name                = backend_pool_health_probe.value.name
      enabled             = backend_pool_health_probe.value.enabled
      path                = backend_pool_health_probe.value.path
      protocol            = backend_pool_health_probe.value.protocol
      probe_method        = backend_pool_health_probe.value.probe_method
      interval_in_seconds = backend_pool_health_probe.value.interval_in_seconds
    }
  }

  dynamic "backend_pool" {
    for_each = var.frontdoor_backend
    content {
       name                = backend_pool.value.name
       load_balancing_name = backend_pool.value.loadbalancing_name
       health_probe_name   = backend_pool.value.health_probe_name

       dynamic "backend" {
        for_each = backend_pool.value.backend
        content {
          enabled     = backend.value.enabled
          address     = backend.value.address
          host_header = backend.value.host_header
          http_port   = backend.value.http_port
          https_port  = backend.value.https_port
          priority    = backend.value.priority
          weight      = backend.value.weight
        }
      }
    }
  }

  dynamic "frontend_endpoint" {
    for_each = var.frontend_endpoint
    content {
      name                                    = frontend_endpoint.value.name
      host_name                               = frontend_endpoint.value.host_name
      session_affinity_enabled                = frontend_endpoint.value.session_affinity_enabled
      session_affinity_ttl_seconds            = frontend_endpoint.value.session_affinity_ttl_seconds
      web_application_firewall_policy_link_id = azurerm_frontdoor_firewall_policy.myDevwafpolicy.id

    }
  }
  depends_on = [azurerm_resource_group.dev, azurerm_app_service.dev_service1, azurerm_app_service.dev_service2
  ]
}