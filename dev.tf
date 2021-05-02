# pinning version
# Use the azurerm version greater than minor version 46 but not major version greater than 2
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.46.0"
    }
  }
}

module "front-door" {
  azure_subscription_id = ""
  azure_tenant_id       = ""
  source                = "./src"
  frontdoor_name                             = "my-frontdoor"
  frontdoor_loadbalancer_enabled             = true
  backend_pools_send_receive_timeout_seconds = 240
  tags = {
    environment = "DEV"
  }

  frontend_endpoint = [{
    name                              = "my-frontdoor"
    host_name                         = "my-frontdoor.azurefd.net"
    custom_https_provisioning_enabled = false
    custom_https_configuration        = { certificate_source = "FrontDoor" }
    session_affinity_enabled          = false
    session_affinity_ttl_seconds      = 0
  }]

  frontdoor_routing_rule = [{
    name               = "my-routing-ruleA"
    accepted_protocols = ["Http", "Https"]
    patterns_to_match  = ["/"]
    enabled            = true
    configuration      = "Forwarding"
    forwarding_configuration = [{
      backend_pool_name                     = "backendA"
      cache_enabled                         = false
      cache_use_dynamic_compression         = false
      cache_query_parameter_strip_directive = "StripNone"
      custom_forwarding_path                = ""
      forwarding_protocol                   = "MatchRequest"
    }]
    },
    {
      name               = "my-routing-ruleB"
      accepted_protocols = ["Http", "Https"]
      patterns_to_match  = ["/AppB/*"]
      enabled            = true
      configuration      = "Forwarding"
      forwarding_configuration = [{
        backend_pool_name                     = "backendB"
        cache_enabled                         = false
        cache_use_dynamic_compression         = false
        cache_query_parameter_strip_directive = "StripNone"
        custom_forwarding_path                = ""
        forwarding_protocol                   = "MatchRequest"
      }]
  }]

  frontdoor_loadbalancer = [{
    name                            = "loadbalancerA"
    sample_size                     = 4
    successful_samples_required     = 2
    additional_latency_milliseconds = 0
    },
    {
      name                            = "loadbalancerB"
      sample_size                     = 4
      successful_samples_required     = 2
      additional_latency_milliseconds = 0
  }]

  frontdoor_health_probe = [{
    name                = "healthprobeA"
    enabled             = true
    path                = "/"
    protocol            = "Http"
    probe_method        = "HEAD"
    interval_in_seconds = 60
    },
    {
      name                = "healthprobeB"
      enabled             = true
      path                = "/"
      protocol            = "Http"
      probe_method        = "HEAD"
      interval_in_seconds = 60
  }]

  frontdoor_backend = [{
    name               = "backendA"
    loadbalancing_name = "loadbalancerA"
    health_probe_name  = "healthprobeB"
    backend = [{
      enabled     = true
      host_header = "myServiceA.azurewebsites.net"
      address     = "myServiceA.azurewebsites.net"
      http_port   = 80
      https_port  = 443
      priority    = 1
      weight      = 50
    }]
    },
    {
      name               = "backendB"
      loadbalancing_name = "loadbalancerB"
      health_probe_name  = "healthprobeB"
      backend = [{
        enabled     = true
        host_header = "myServiceB.azurewebsites.net"
        address     = "myServiceB.azurewebsites.net"
        http_port   = 80
        https_port  = 443
        priority    = 1
        weight      = 50
      }]
  }]
}
