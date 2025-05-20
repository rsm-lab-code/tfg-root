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

output "vpc_ids" {
  description = "IDs of the created VPCs"
  value       = module.vpc.vpc_id
}

output "vpc_cidrs" {
  description = "CIDR blocks of the created VPCs"
  value       = module.vpc.vpc_cidr
}

output "subnet_ids" {
  description = "IDs of the created subnets"
  value       = {
    public  = module.vpc.public_subnet_ids
    private = module.vpc.private_subnet_ids
  }
}

output "route_table_ids" {
  description = "IDs of the route tables"
  value       = module.vpc.route_table_ids
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
    workload   = module.tgw.workload_rt_id 
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

# Add outputs for dev_vpc2
output "dev_vpc2_id" {
  description = "ID of dev_vpc2"
  value       = module.dev_vpc2.vpc_id
}

output "dev_vpc2_cidr" {
  description = "CIDR block of dev_vpc2"
  value       = module.dev_vpc2.vpc_cidr
}

output "dev_vpc2_subnet_ids" {
  description = "Subnet IDs in dev_vpc2"
  value       = {
    public  = module.dev_vpc2.public_subnet_ids
    private = module.dev_vpc2.private_subnet_ids
  }
}


# Add outputs for nonprod_vpc1
output "nonprod_vpc1_id" {
  description = "ID of nonprod_vpc1"
  value       = module.nonprod_vpc1.vpc_id
}

output "nonprod_vpc1_cidr" {
  description = "CIDR block of nonprod_vpc1"
  value       = module.nonprod_vpc1.vpc_cidr
}

output "nonprod_vpc1_subnet_ids" {
  description = "Subnet IDs in nonprod_vpc1"
  value       = {
    public  = module.nonprod_vpc1.public_subnet_ids
    private = module.nonprod_vpc1.private_subnet_ids
  }
}


# Add outputs for nonprod_vpc2
output "nonprod_vpc2_id" {
  description = "ID of nonprod_vpc2"
  value       = module.nonprod_vpc2.vpc_id
}

output "nonprod_vpc2_cidr" {
  description = "CIDR block of nonprod_vpc2"
  value       = module.nonprod_vpc2.vpc_cidr
}

output "nonprod_vpc2_subnet_ids" {
  description = "Subnet IDs in nonprod_vpc2"
  value       = {
    public  = module.nonprod_vpc2.public_subnet_ids
    private = module.nonprod_vpc2.private_subnet_ids
  }
}

output "available_ipam_pools" {
  description = "Available IPAM pool IDs"
  value       = module.ipam.subnet_pool_ids
}
