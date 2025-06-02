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

output "subnet_pool_ids" {
  description = "IDs of subnet pools"
  value       = module.ipam.subnet_pool_ids
}

#Spoke VPC outputs
output "spoke_vpc_details" {
  description = "Details of all spoke VPCs"
  value = {
    for k, v in module.spoke_vpcs : k => {
      vpc_id   = v.vpc_id
      vpc_cidr = v.vpc_cidr
      public_subnets = v.public_subnet_ids
      private_subnets = v.private_subnet_ids
      tgw_attachment_id = v.tgw_attachment_id
      environment = var.spoke_vpc_configs[k].environment
    }
  }
}

output "vpc_cidrs_summary" {
  description = "Summary of all VPC CIDR blocks"
  value = {
    inspection = module.inspection_vpc.vpc_cidr
    spoke_vpcs = {
      for k, v in module.spoke_vpcs : k => v.vpc_cidr
    }
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
    #workload   = module.tgw.workload_rt_id 
    dev        = module.tgw.dev_tgw_rt_id
    nonprod    = module.tgw.nonprod_tgw_rt_id
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



# AWS Config test outputs
output "config_test_bucket" {
description = "Config test bucket name"
value       = module.aws_config_test.config_bucket_name
}
