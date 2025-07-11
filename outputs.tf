#IPAM outputs
output "ipam_id" {
  description = "ID of the created IPAM"
  value       = module.ipam.ipam_id
}

output "private_scope_id" {
  description = "ID of the private IPAM scope"
  value       = module.ipam.private_scope_id
}

output "regional_pool_ids" {
  description = "IDs of regional pools"
  value       = module.ipam.regional_pool_ids
}

output "environment_pool_ids" {
  description = "IDs of environment pools"
  value       = module.ipam.environment_pool_ids
}

/*
output "subnet_pool_ids" {
  description = "IDs of subnet pools"
  value       = module.ipam.subnet_pool_ids
}
*/
# Output all VPC information dynamically
output "spoke_vpcs" {
  description = "Information about all spoke VPCs"
  value = {
    for name, vpc in module.spoke_vpcs : name => {
      vpc_id           = vpc.vpc_id
      vpc_cidr         = vpc.vpc_cidr
      public_subnets   = vpc.public_subnet_ids
      private_subnets  = vpc.private_subnet_ids
      tgw_subnets      = vpc.tgw_subnet_ids
      tgw_attachment   = vpc.tgw_attachment_id
      environment     = local.vpc_configurations[name].environment
      internet_gateway = vpc.internet_gateway_id
      route_tables    = vpc.route_table_ids
    }
  }
}

# Output VPCs by environment
output "vpcs_by_environment" {
  description = "VPCs grouped by environment"
  value = {
    for env in distinct([for vpc in local.vpc_configurations : vpc.environment]) :
    env => {
      for name, vpc in module.spoke_vpcs : name => {
        vpc_id   = vpc.vpc_id
        vpc_cidr = vpc.vpc_cidr
      }
      if local.vpc_configurations[name].environment == env
    }
  }
}

# Quick summary
output "vpc_summary" {
  description = "Summary of all VPCs"
  value = {
    total_vpcs = length(module.spoke_vpcs)
    environments = {
      for env in distinct([for vpc in local.vpc_configurations : vpc.environment]) :
      env => length([for vpc in local.vpc_configurations : vpc if vpc.environment == env])
    }
    vpc_names = keys(module.spoke_vpcs)
  }
}

# Transit Gateway outputs
output "transit_gateway_id" {
  description = "ID of the created Transit Gateway"
  value       = module.tgw.tgw_id
}

output "tgw_vpc_attachments" {
  description = "IDs of the Transit Gateway VPC attachments"
  value = {
    "us-west-2" = module.tgw.inspection_attachment_id
  }
}

# Transit Gateway route table outputs
output "transit_gateway_route_table_ids" {
  description = "IDs of the Transit Gateway route tables"
  value       = {
    inspection = module.tgw.inspection_rt_id
    main       = module.tgw.main_rt_id
    #  dev        = module.tgw.dev_tgw_rt_id
    nonprod    = module.tgw.nonprod_tgw_rt_id
    prod       = module.tgw.prod_tgw_rt_id
  }
}

# Add Inspection VPC outputs
output "inspection_vpc_id" {
  description = "ID of the Inspection VPC"
  value       = module.inspection_vpc.vpc_id
}

output "inspection_vpc_cidr" {
  description = "CIDR block of the Inspection VPC"
  value       = module.inspection_vpc.vpc_cidr
}

output "inspection_subnet_ids" {
  description = "IDs of the subnets in the Inspection VPC"
  value = {
    public    = module.inspection_vpc.public_subnet_ids
    tgw       = module.inspection_vpc.tgw_subnet_ids
    firewall  = module.inspection_vpc.firewall_subnet_ids
  }
}

output "inspection_route_tables" {
  description = "IDs of the route tables in the Inspection VPC"
  value = {
    public    = module.inspection_vpc.public_route_table_ids
    tgw       = module.inspection_vpc.tgw_route_table_ids
    firewall  = module.inspection_vpc.firewall_route_table_ids
  }
}

# Add Network Firewall outputs
output "firewall_id" {
  description = "ID of the Network Firewall"
  value       = module.network_firewall.firewall_id
}

output "firewall_endpoint_ids" {
  description = "IDs of the Network Firewall endpoints"
  value       = module.network_firewall.firewall_endpoint_ids
}
##############################################
# Network Manager outputs 
output "global_network_id" {
  description = "ID of the Global Network"
  value       = module.tgw.global_network_id
}

output "network_manager_console_url" {
  description = "URL to access Network Manager console"
  value       = module.tgw.network_manager_console_url
}
##########################################################
# Route Manager outputs
output "tgw_route_summary" {
  description = "Summary of all Transit Gateway routes created"
  value       = module.spoke_route_manager.total_routes_created
}

output "routes_by_vpc" {
  description = "Routing information organized by VPC"
  value       = module.spoke_route_manager.routes_by_vpc
}

output "inspection_rt_routes" {
  description = "Routes in the inspection route table"
  value       = module.spoke_route_manager.inspection_rt_routes
}

output "main_rt_routes" {
  description = "Routes in the main route table"
  value       = module.spoke_route_manager.main_rt_routes
}

# SCP Outputs
output "scp_tiered_summary" {
  description = "Summary of tiered SCP implementation"
  value       = module.scps.tiered_scp_summary
}

output "scp_policies_created" {
  description = "Tiered SCP policies created"
  value = {
    root_baseline_id = module.scps.root_baseline_policy_id
    prod_controls_id = module.scps.prod_controls_policy_id
    nonprod_controls_id = module.scps.nonprod_controls_policy_id
  }
}

output "scp_console_url" {
  description = "URL to manage SCPs in AWS Console"
  value       = module.scps.scp_console_url
}

#account factory output
output "account_factory_console_url" {
  description = "URL to view AWS Organizations"
  value       = "https://console.aws.amazon.com/organizations/v2/home"
}


###########################################
# TGW Sharing Outputs

output "tgw_sharing_details" {
  description = "Transit Gateway sharing configuration"
  value = {
    resource_share_id  = module.tgw.tgw_resource_share_id
    resource_share_arn = module.tgw.tgw_resource_share_arn
    shared_accounts    = module.tgw.tgw_shared_accounts
    sharing_status     = module.tgw.tgw_sharing_status
  }
}

output "tgw_access_instructions" {
  description = "Instructions for accessing shared TGW from spoke accounts"
  value = {
    message = "Transit Gateway has been shared with individual accounts. Spoke accounts can now attach VPCs to TGW ID: ${module.tgw.tgw_id}"
    tgw_id  = module.tgw.tgw_id
    shared_accounts = module.tgw.tgw_shared_accounts
    console_url = "https://console.aws.amazon.com/ram/home#Shared_With_Me:sort=resourceType"
  }
}
